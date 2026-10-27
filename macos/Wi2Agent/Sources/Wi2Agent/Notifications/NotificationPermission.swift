import AppKit
import Combine
import UserNotifications

@MainActor
final class NotificationPermission: ObservableObject {
  @Published private(set) var isAllowed = false
  private var didRequestOnLaunch = false

  func requestOnLaunch() async {
    guard !didRequestOnLaunch else { return }
    didRequestOnLaunch = true
    await request()
  }

  func refresh() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    isAllowed = settings.authorizationStatus == .authorized && settings.alertSetting == .enabled
  }

  func openSettings() {
    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!)
  }

  func request() async {
    let center = UNUserNotificationCenter.current()
    var requestError: String?
    let settings = await center.notificationSettings()
    if settings.authorizationStatus == .notDetermined {
      NSApplication.shared.activate(ignoringOtherApps: true)
      do {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
      } catch {
        requestError = "通知の許可を要求できませんでした。システム設定でWi2Agentの通知を許可してください。"
      }
    }
    await refresh()
    guard !isAllowed else { return }
    let alert = NSAlert()
    alert.messageText = "Wi2Agentの通知を許可してください"
    alert.informativeText = requestError ?? "ゲストコードと残り2分の通知を表示します。システム設定で「通知を許可」とバナーを有効にしてください。"
    alert.addButton(withTitle: "通知設定を開く")
    alert.addButton(withTitle: "あとで")
    NSApplication.shared.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn {
      openSettings()
    }
  }
}
