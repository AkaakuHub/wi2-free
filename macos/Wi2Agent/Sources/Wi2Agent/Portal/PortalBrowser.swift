import AppKit
import Combine
import WebKit

@MainActor
final class PortalBrowser: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
  let webView: WKWebView
  @Published private(set) var isLoading = false
  @Published private(set) var canGoBack = false
  @Published private(set) var errorMessage: String?

  override init() {
    webView = WKWebView(frame: .zero)
    super.init()
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.allowsBackForwardNavigationGestures = true
  }

  func openLogin() {
    webView.load(URLRequest(url: URL(string: "http://a.wi2.co.jp/")!))
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    isLoading = true
    errorMessage = nil
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    isLoading = false
    canGoBack = webView.canGoBack
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    finishWithError(error)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    finishWithError(error)
  }

  func webView(
    _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
    return nil
  }

  func webView(
    _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void
  ) {
    let alert = NSAlert()
    alert.messageText = message
    alert.addButton(withTitle: "OK")
    if let window = webView.window {
      alert.beginSheetModal(for: window) { _ in completionHandler() }
    } else {
      alert.runModal()
      completionHandler()
    }
  }

  func webView(
    _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void
  ) {
    let alert = NSAlert()
    alert.messageText = message
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "キャンセル")
    if let window = webView.window {
      alert.beginSheetModal(for: window) { response in completionHandler(response == .alertFirstButtonReturn) }
    } else {
      completionHandler(alert.runModal() == .alertFirstButtonReturn)
    }
  }

  private func finishWithError(_ error: Error) {
    isLoading = false
    canGoBack = webView.canGoBack
    if (error as NSError).code != NSURLErrorCancelled {
      errorMessage = error.localizedDescription
    }
  }
}
