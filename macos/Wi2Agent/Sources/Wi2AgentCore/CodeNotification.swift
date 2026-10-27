import Foundation
import UserNotifications

public enum CodeNotificationError: Error, LocalizedError {
  case permissionDenied

  public var errorDescription: String? {
    "通知が許可されていません。システム設定の「通知」でWi2Agentを許可してください。コードはアプリ内で確認できます。"
  }
}

public enum CodeNotification {
  public static func show(title: String, body: String) async throws {
    let center = UNUserNotificationCenter.current()
    guard try await center.requestAuthorization(options: [.alert, .sound]) else {
      throw CodeNotificationError.permissionDenied
    }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    try await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
  }
}
