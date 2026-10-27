import Foundation
import UserNotifications

public enum CodeNotificationError: Error, LocalizedError {
  case permissionDenied

  public var errorDescription: String? {
    "通知が無効です。システム設定の「通知」でWi2Agentの通知とバナーを許可してください。"
  }
}

public enum CodeNotification {
  public static func show(title: String, body: String) async throws {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized, settings.alertSetting == .enabled else {
      throw CodeNotificationError.permissionDenied
    }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    do {
      try await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    } catch let error as UNError where error.code == .notificationsNotAllowed {
      throw CodeNotificationError.permissionDenied
    }
  }
}
