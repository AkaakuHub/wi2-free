import AppKit
import Combine
import Foundation
import Wi2AgentCore

@MainActor
final class Wi2SessionViewModel: ObservableObject {
  @Published var apiToken = ""
  @Published var apiEndpoint = UserDefaults.standard.string(forKey: "api-endpoint") ?? ""
  @Published var elapsedMinutes = 1
  @Published private(set) var state = SessionState()
  @Published private(set) var isBusy = false
  @Published private(set) var isError = false
  @Published private(set) var isTokenConfigured = false
  @Published private(set) var remainingTime: String?
  @Published private(set) var status = "APIトークンを登録してください。"
  @Published private(set) var notificationError: String?

  private let store = SessionStore()
  private var portalWindow: Wi2PortalWindow?
  private var timer: Timer?
  private var renewalWindowSession: Date?
  private var isNotifyingRenewal = false
  private var nextNotificationRetryAt: Date?

  init() {
    isTokenConfigured = TokenStore.hasToken() && !apiEndpoint.isEmpty
    do {
      state = try store.load()
      status = state.session == nil
        ? "コードを取得してWi2へ接続します。"
        : "前回の接続情報を復元しました。残り時間は手動で確認したログイン時刻からの目安です。"
    } catch {
      isError = true
      status = "接続情報を復元できませんでした: \(error.localizedDescription)"
    }
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.refreshTimer() }
    }
    refreshTimer()
  }

  func saveToken() {
    guard let endpoint = URL(string: apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
      endpoint.scheme == "https", endpoint.host != nil, endpoint.user == nil, endpoint.password == nil
    else {
      isError = true
      status = "HTTPSのAPI接続先を入力してください。"
      return
    }
    guard !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    do {
      try TokenStore.save(apiToken.trimmingCharacters(in: .whitespacesAndNewlines))
      UserDefaults.standard.set(endpoint.absoluteString, forKey: "api-endpoint")
      apiEndpoint = endpoint.absoluteString
      apiToken = ""
      isTokenConfigured = true
      isError = false
      status = "APIトークンをKeychainへ保存しました。"
    } catch {
      report(error)
    }
  }

  func startConnection() {
    guard !isBusy else { return }
    isBusy = true
    isError = false
    status = "Wi2用コードを取得しています。"
    Task {
      do {
        let code = try await fetchCode()
        state.prepareLogin(code: code)
        persist()
        remainingTime = nil
        isBusy = false
        status = "Wi2へ切り替えています。ログイン後に「ログイン完了」を押してください。"
        Task { await notify(title: "Wi2ゲストコード", body: "ゲストコード: \(code)") }
        Task {
          do {
            try await Task.detached { try WiFiNetwork.connect(ssid: "Wi2") }.value
            guard state.awaitingLogin, state.currentCode == code else { return }
            status = "ログイン後に「ログイン完了」を押してください。"
          } catch {
            guard state.awaitingLogin, state.currentCode == code else { return }
            report(error)
          }
        }
      } catch {
        isBusy = false
        report(error)
      }
    }
  }

  func confirmLogin() {
    guard !isBusy else { return }
    state.confirmLogin(at: Date())
    persist()
    isError = false
    status = "ログイン時刻を記録しました。次回のコードを取得します。"
    refreshTimer()
  }

  func resumeExistingSession() {
    guard !isBusy else { return }
    state.resumeExistingSession(at: Date(), elapsedMinutes: elapsedMinutes)
    persist()
    isError = false
    status = "現在の接続を引き継ぎました。次回のコードを取得します。"
    refreshTimer()
  }

  func retryRenewal() {
    guard !isBusy, state.session != nil, state.renewalCode == nil else { return }
    prepareRenewalCode()
  }

  func stopSession() {
    guard !isBusy else { return }
    state = SessionState()
    nextNotificationRetryAt = nil
    renewalWindowSession = nil
    notificationError = nil
    persist()
    remainingTime = nil
    isError = false
    status = "タイマーとコードの自動取得を停止しました。"
  }

  func copyCode(_ code: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code, forType: .string)
  }

  func openPortal() {
    if portalWindow == nil { portalWindow = Wi2PortalWindow(viewModel: self) }
    portalWindow?.showLogin()
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  private func refreshTimer() {
    let now = Date()
    remainingTime = state.session.map { SessionClock.format(seconds: $0.remainingSeconds(at: now)) }
    handleExpiry(at: now)
    guard !isBusy else { return }
    if state.shouldFetchRenewal(at: now), isTokenConfigured {
      prepareRenewalCode()
    }
  }

  private func handleExpiry(at now: Date) {
    guard let session = state.session, session.isExpired(at: now) else { return }
    if renewalWindowSession != session.startedAt {
      renewalWindowSession = session.startedAt
      openPortal()
    }
    guard state.shouldNotifyRenewal(at: now), !isNotifyingRenewal,
      nextNotificationRetryAt.map({ now >= $0 }) ?? true else { return }
    isNotifyingRenewal = true
    let body = state.renewalCode.map { "更新用コード: \($0)。ログイン画面で再ログインしてください。" }
      ?? "更新用コードを取得できていません。アプリでコードを再取得してください。"
    Task {
      defer { isNotifyingRenewal = false }
      let sent = await notify(title: "Wi2の利用時間が終了しました", body: body)
      guard state.session?.startedAt == session.startedAt else { return }
      if sent {
        state.markRenewalNotified()
        nextNotificationRetryAt = nil
        persist()
      } else {
        nextNotificationRetryAt = Date().addingTimeInterval(15)
      }
    }
  }

  private func prepareRenewalCode() {
    isBusy = true
    isError = false
    status = "次回のゲストコードを取得しています。"
    Task {
      defer { isBusy = false }
      do {
        let code = try await fetchCode()
        if state.receiveRenewal(code: code, at: Date()) {
          status = "更新用コードを確保しました。利用期限に通知し、ログイン画面を開きます。"
        } else {
          isError = true
          status = "現在と同じコードが返りました。Wi2へのログインを確認してください。15秒後に再試行します。"
        }
      } catch {
        state.recordFetchFailure(at: Date())
        isError = true
        status = "コード取得に失敗しました。利用時間内は15秒後に再試行します: \(error.localizedDescription)"
      }
      persist()
    }
  }

  private func fetchCode() async throws -> String {
    guard let endpoint = URL(string: UserDefaults.standard.string(forKey: "api-endpoint") ?? "") else {
      throw Wi2CodeClientError.invalidEndpoint
    }
    return try await Wi2CodeClient().fetchCode(endpoint: endpoint, token: TokenStore.load())
  }

  @discardableResult
  private func notify(title: String, body: String) async -> Bool {
    do {
      try await CodeNotification.show(title: title, body: body)
      notificationError = nil
      return true
    } catch {
      notificationError = error.localizedDescription
      return false
    }
  }

  private func persist() {
    do { try store.save(state) } catch { report(error) }
  }

  private func report(_ error: Error) {
    isError = true
    status = error.localizedDescription
  }
}
