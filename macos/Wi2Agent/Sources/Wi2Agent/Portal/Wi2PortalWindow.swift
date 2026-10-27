import AppKit
import SwiftUI

@MainActor
final class Wi2PortalWindow: NSWindowController {
  private let browser = PortalBrowser()

  init(viewModel: Wi2SessionViewModel) {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "Wi2ログイン"
    window.minSize = NSSize(width: 400, height: 500)
    window.isReleasedWhenClosed = false
    window.contentView = NSHostingView(rootView: Wi2PortalView(viewModel: viewModel, browser: browser))
    window.center()
    super.init(window: window)
  }

  func showLogin() {
    browser.openLogin()
    showWindow(nil)
  }

  required init?(coder: NSCoder) { nil }
}
