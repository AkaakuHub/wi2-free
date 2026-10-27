import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().delegate = self
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}

@main
struct Wi2AgentApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var viewModel = Wi2SessionViewModel()
  @StateObject private var notificationPermission = NotificationPermission()
  @Environment(\.openWindow) private var openWindow

  var body: some Scene {
    Window("Wi2ゲスト接続", id: "session") {
      Wi2SessionView(viewModel: viewModel, notificationPermission: notificationPermission)
    }
    .windowResizability(.contentSize)

    MenuBarExtra {
      Button("Wi2ゲスト接続を表示") {
        openWindow(id: "session")
        NSApplication.shared.activate(ignoringOtherApps: true)
      }
      if let code = viewModel.state.renewalCode {
        Button("更新コードをコピー: \(code)") { viewModel.copyCode(code) }
      }
      Divider()
      Button("Wi2Agentを終了") { NSApplication.shared.terminate(nil) }
    } label: {
      Label(viewModel.remainingTime ?? "Wi2", systemImage: "wifi")
    }
  }
}
