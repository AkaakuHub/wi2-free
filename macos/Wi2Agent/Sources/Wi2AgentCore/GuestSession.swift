import Foundation

public struct GuestSession: Codable, Equatable, Sendable {
  public static let duration: TimeInterval = 10 * 60
  public static let renewalLeadTime: TimeInterval = 2 * 60

  public let startedAt: Date

  public init(startedAt: Date) {
    self.startedAt = startedAt
  }

  public func isExpired(at date: Date) -> Bool {
    date >= expiresAt
  }

  public func remainingSeconds(at date: Date) -> TimeInterval {
    max(0, expiresAt.timeIntervalSince(date))
  }

  public func shouldPrepareRenewal(at date: Date) -> Bool {
    date >= renewalAt && !isExpired(at: date)
  }

  private var expiresAt: Date {
    startedAt.addingTimeInterval(Self.duration)
  }

  private var renewalAt: Date {
    expiresAt.addingTimeInterval(-Self.renewalLeadTime)
  }
}

public enum SessionClock {
  public static func format(seconds: TimeInterval) -> String {
    let roundedSeconds = max(0, Int(seconds.rounded(.down)))
    return String(format: "%02d:%02d", roundedSeconds / 60, roundedSeconds % 60)
  }
}
