import SwiftUI

struct Wi2SessionView: View {
  @ObservedObject var viewModel: Wi2SessionViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Wi2ゲスト接続").font(.title2.bold())
      DisclosureGroup(viewModel.isTokenConfigured ? "API設定を変更" : "APIを設定") {
        TextField("API接続先（https://example.com/code）", text: $viewModel.apiEndpoint)
          .textFieldStyle(.roundedBorder)
        SecureField("WorkerのAPIトークン", text: $viewModel.apiToken)
          .textFieldStyle(.roundedBorder)
        Button("Keychainへ保存", action: viewModel.saveToken)
          .disabled(viewModel.apiToken.isEmpty || viewModel.isBusy)
      }

      if let code = viewModel.state.currentCode {
        codeView(title: "現在のゲストコード", code: code)
      }
      if viewModel.state.awaitingLogin {
        Button("ログイン完了", action: viewModel.confirmLogin)
          .disabled(viewModel.isBusy)
      }
      if let remainingTime = viewModel.remainingTime {
        Text("残り時間の目安").foregroundStyle(.secondary)
        Text(remainingTime)
          .font(.system(size: 44, weight: .bold, design: .rounded))
          .monospacedDigit()
        if remainingTime == "00:00" {
          Text("利用時間を過ぎています。更新用コードで再ログインしてください。コード未取得の場合は、インターネットへ接続できる回線で再取得してください。")
            .foregroundStyle(.red)
        }
      }
      if let code = viewModel.state.renewalCode {
        codeView(title: "更新用ゲストコード", code: code)
        Text("Wi2画面でログアウト後、このコードでログインします。接続できたら「更新完了」を押してください。")
          .foregroundStyle(.secondary)
        Button("更新完了", action: viewModel.confirmLogin)
          .disabled(viewModel.isBusy)
      }

      Text(viewModel.status)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(viewModel.isError ? .red : .secondary)
      if let error = viewModel.notificationError {
        Text(error).foregroundStyle(.orange)
      }
      if viewModel.isBusy { ProgressView().controlSize(.small) }

      HStack {
        Button("Wi2ログイン画面を開く", action: viewModel.openPortal)
        if viewModel.state.session != nil, viewModel.state.renewalCode == nil {
          Button("コード取得を再試行", action: viewModel.retryRenewal)
            .disabled(viewModel.isBusy || !viewModel.isTokenConfigured)
        }
      }
      if viewModel.state.session == nil, !viewModel.state.awaitingLogin {
        Button("コード取得→Wi2接続", action: viewModel.startConnection)
          .buttonStyle(.borderedProminent)
          .disabled(!viewModel.isTokenConfigured || viewModel.isBusy)
        Divider()
        Text("すでにWi2へログインしている場合")
        Stepper("ログインから約\(viewModel.elapsedMinutes)分", value: $viewModel.elapsedMinutes, in: 0...9)
        Button("現在の接続を引き継ぐ", action: viewModel.resumeExistingSession)
          .disabled(!viewModel.isTokenConfigured || viewModel.isBusy)
      } else {
        Button("接続管理を停止", action: viewModel.stopSession)
          .disabled(viewModel.isBusy)
      }
    }
    .padding(24)
    .frame(width: 480)
  }

  private func codeView(title: String, code: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).foregroundStyle(.secondary)
      HStack {
        Text(code).font(.system(.title, design: .monospaced).weight(.semibold))
          .textSelection(.enabled)
        Button("コピー") { viewModel.copyCode(code) }
      }
    }
  }
}
