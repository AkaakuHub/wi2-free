import SwiftUI
import WebKit

struct Wi2PortalView: View {
  @ObservedObject var viewModel: Wi2SessionViewModel
  @StateObject private var browser = PortalBrowser()

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button("戻る", systemImage: "chevron.left") { browser.webView.goBack() }
          .disabled(!browser.canGoBack)
        Button("再読み込み", systemImage: "arrow.clockwise") { browser.webView.reload() }
        Spacer()
        if let code = viewModel.state.renewalCode ?? viewModel.state.currentCode {
          Text(code).font(.system(.body, design: .monospaced)).textSelection(.enabled)
          Button("コピー") { viewModel.copyCode(code) }
        }
        if viewModel.state.awaitingLogin || viewModel.state.renewalCode != nil {
          Button(viewModel.state.awaitingLogin ? "ログイン完了" : "更新完了", action: viewModel.confirmLogin)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)
        }
      }
      .padding(12)
      if browser.isLoading { ProgressView().progressViewStyle(.linear) }
      if let error = browser.errorMessage {
        Text(error).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true).padding(12)
        Button("ログイン画面を読み込む", action: browser.openLogin).padding(.bottom, 12)
      }
      Divider()
      PortalWebView(browser: browser)
    }
  }
}

private struct PortalWebView: NSViewRepresentable {
  let browser: PortalBrowser

  func makeNSView(context: Context) -> WKWebView { browser.webView }
  func updateNSView(_ nsView: WKWebView, context: Context) {}
}
