import Foundation

public struct SessionStore {
  private let defaults: UserDefaults
  private let key = "guest-session"

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func load() throws -> SessionState {
    guard let data = defaults.data(forKey: key) else { return SessionState() }
    return try JSONDecoder().decode(SessionState.self, from: data)
  }

  public func save(_ state: SessionState) throws {
    defaults.set(try JSONEncoder().encode(state), forKey: key)
  }
}
