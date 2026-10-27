import Foundation

public struct SessionState: Codable, Equatable, Sendable {
  public private(set) var currentCode: String?
  public private(set) var renewalCode: String?
  public private(set) var session: GuestSession?
  public private(set) var awaitingLogin = false
  public private(set) var renewalNotified = false
  public private(set) var nextRetryAt: Date?

  public init() {}

  public mutating func prepareLogin(code: String) {
    self = SessionState()
    currentCode = code
    awaitingLogin = true
  }

  public mutating func confirmLogin(at date: Date) {
    guard awaitingLogin || renewalCode != nil else { return }
    if let renewalCode { currentCode = renewalCode }
    beginSession(at: date)
  }

  public mutating func resumeExistingSession(at date: Date, elapsedMinutes: Int) {
    self = SessionState()
    beginSession(at: date.addingTimeInterval(-Double(min(9, max(0, elapsedMinutes))) * 60))
  }

  public func shouldFetchRenewal(at date: Date) -> Bool {
    guard let session, !session.isExpired(at: date), renewalCode == nil else { return false }
    return nextRetryAt.map { date >= $0 } ?? true
  }

  public mutating func receiveRenewal(code: String, at date: Date) -> Bool {
    guard code != currentCode else {
      recordFetchFailure(at: date)
      return false
    }
    renewalCode = code
    nextRetryAt = nil
    return true
  }

  public mutating func recordFetchFailure(at date: Date) {
    nextRetryAt = date.addingTimeInterval(15)
  }

  public func shouldNotifyRenewal(at date: Date) -> Bool {
    guard let session, !renewalNotified else { return false }
    return session.isExpired(at: date)
  }

  public mutating func markRenewalNotified() {
    renewalNotified = true
  }

  private mutating func beginSession(at date: Date) {
    session = GuestSession(startedAt: date)
    renewalCode = nil
    awaitingLogin = false
    renewalNotified = false
    nextRetryAt = nil
  }
}
