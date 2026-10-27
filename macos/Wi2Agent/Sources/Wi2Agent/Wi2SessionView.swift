import SwiftUI

struct Wi2SessionView: View {
  @ObservedObject var viewModel: Wi2SessionViewModel
  @ObservedObject var notificationPermission: NotificationPermission
  @State private var isShowingSettings = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      if viewModel.state.session == nil, !viewModel.state.awaitingLogin {
        startControls
      } else {
        sessionControls
      }
      if viewModel.isBusy {
        HStack(spacing: 12) {
          ProgressView().controlSize(.small)
          Text(viewModel.status).fixedSize(horizontal: false, vertical: true)
        }
      } else if viewModel.isError {
        Text(viewModel.status).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let error = viewModel.notificationError {
        Text(error).foregroundStyle(.orange)
          .fixedSize(horizontal: false, vertical: true)
      }
      if viewModel.state.session != nil || viewModel.state.awaitingLogin {
        Divider()
        HStack {
          Spacer()
          Button("接続管理を停止", role: .destructive, action: viewModel.stopSession)
            .disabled(viewModel.isBusy)
        }
      }
    }
    .padding(24)
    .frame(width: 480)
    .toolbar {
      if viewModel.state.session == nil, !viewModel.state.awaitingLogin {
        ToolbarItem {
          Button("Wi2ログイン", systemImage: "globe", action: viewModel.openPortal)
        }
      }
      ToolbarItem {
        Button("通知設定", systemImage: notificationPermission.isAllowed ? "bell" : "bell.badge") {
          Task {
            if notificationPermission.isAllowed { notificationPermission.openSettings() }
            else { await notificationPermission.request() }
          }
        }
      }
      ToolbarItem {
        Button("API設定", systemImage: "gearshape") { isShowingSettings = true }
      }
    }
    .sheet(isPresented: $isShowingSettings) { APISettingsView(viewModel: viewModel) }
    .task {
      await notificationPermission.requestOnLaunch()
      if !viewModel.isTokenConfigured { isShowingSettings = true }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      Task { await notificationPermission.refresh() }
    }
  }

  private var startControls: some View {
    VStack(alignment: .leading, spacing: 20) {
      Button("コードを取得して接続", action: viewModel.startConnection)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.isTokenConfigured || viewModel.isBusy)
      DisclosureGroup("接続済みのWi2を引き継ぐ") {
        VStack(alignment: .leading, spacing: 12) {
          Stepper("ログインから約\(viewModel.elapsedMinutes)分", value: $viewModel.elapsedMinutes, in: 0...9)
          Button("引き継いで開始", action: viewModel.resumeExistingSession)
            .disabled(!viewModel.isTokenConfigured || viewModel.isBusy)
        }
        .padding(.top, 12)
      }
    }
  }

  private var sessionControls: some View {
    VStack(alignment: .leading, spacing: 20) {
      if let remainingTime = viewModel.remainingTime {
        GroupBox("残り時間") {
          Text(remainingTime)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(remainingTime == "00:00" ? .red : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
      }
      if let code = viewModel.state.currentCode {
        codeView(title: "ゲストコード", code: code)
      }
      if let code = viewModel.state.renewalCode {
        if viewModel.state.currentCode != nil {
          Image(systemName: "chevron.down.2")
            .font(.title3.weight(.semibold))
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        codeView(title: "更新用ゲストコード", code: code)
      }
      HStack {
        Button("ログイン画面を開く", action: viewModel.openPortal)
        Spacer()
        if viewModel.state.awaitingLogin || viewModel.state.renewalCode != nil {
          Button(viewModel.state.awaitingLogin ? "ログイン完了" : "更新完了", action: viewModel.confirmLogin)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)
        } else {
          Button("コード取得を再試行", action: viewModel.retryRenewal)
            .disabled(viewModel.isBusy || !viewModel.isTokenConfigured)
        }
      }
    }
  }

  private func codeView(title: String, code: String) -> some View {
    GroupBox(title) {
      HStack {
        Text(code).font(.system(.title, design: .monospaced).weight(.semibold))
          .textSelection(.enabled)
        Spacer()
        Button("コピー") { viewModel.copyCode(code) }
      }
      .padding(8)
    }
  }
}
