import Foundation
import Testing
@testable import Wi2AgentCore

private let start = Date(timeIntervalSince1970: 1_000)

@Test func timerStartsOnlyAfterLoginConfirmation() {
  var state = SessionState()
  state.prepareLogin(code: "ABC12345")
  #expect(state.session == nil)
  #expect(!state.shouldFetchRenewal(at: start))
  state.confirmLogin(at: start)
  #expect(state.session?.remainingSeconds(at: start) == 600)
  #expect(state.shouldFetchRenewal(at: start))
}

@Test func renewalRetriesAfterFailureAndRejectsCurrentCode() {
  var state = SessionState()
  state.prepareLogin(code: "ABC12345")
  state.confirmLogin(at: start)
  let accepted = state.receiveRenewal(code: "ABC12345", at: start)
  #expect(!accepted)
  #expect(state.renewalCode == nil)
  #expect(!state.shouldFetchRenewal(at: start.addingTimeInterval(14)))
  #expect(state.shouldFetchRenewal(at: start.addingTimeInterval(15)))
  state.recordFetchFailure(at: start.addingTimeInterval(15))
  #expect(!state.shouldFetchRenewal(at: start.addingTimeInterval(29)))
  #expect(state.shouldFetchRenewal(at: start.addingTimeInterval(30)))
  #expect(!state.shouldFetchRenewal(at: start.addingTimeInterval(600)))
}

@Test func renewalSurvivesExpiryAndStartsNextCycle() {
  var state = SessionState()
  state.prepareLogin(code: "ABC12345")
  state.confirmLogin(at: start)
  let accepted = state.receiveRenewal(code: "DEF67890", at: start)
  #expect(accepted)
  #expect(!state.shouldFetchRenewal(at: start))
  #expect(!state.shouldNotifyRenewal(at: start.addingTimeInterval(479)))
  #expect(state.shouldNotifyRenewal(at: start.addingTimeInterval(480)))
  #expect(state.shouldNotifyRenewal(at: start.addingTimeInterval(610)))
  state.markRenewalNotified()
  #expect(!state.shouldNotifyRenewal(at: start.addingTimeInterval(611)))
  state.confirmLogin(at: start.addingTimeInterval(620))
  #expect(state.currentCode == "DEF67890")
  #expect(state.renewalCode == nil)
  #expect(state.session?.remainingSeconds(at: start.addingTimeInterval(620)) == 600)
  #expect(state.shouldFetchRenewal(at: start.addingTimeInterval(620)))
}

@Test func duplicateConfirmationDoesNotExtendExistingSession() {
  var state = SessionState()
  state.resumeExistingSession(at: start, elapsedMinutes: 1)
  state.confirmLogin(at: start.addingTimeInterval(10))
  #expect(state.session?.remainingSeconds(at: start) == 540)
}

@Test func restartingRestoresCodesAndOriginalDeadline() throws {
  let suiteName = "Wi2AgentTests.\(UUID().uuidString)"
  let defaults = try #require(UserDefaults(suiteName: suiteName))
  defer { defaults.removePersistentDomain(forName: suiteName) }
  let store = SessionStore(defaults: defaults)
  var state = SessionState()
  state.resumeExistingSession(at: start, elapsedMinutes: 1)
  let accepted = state.receiveRenewal(code: "ABC12345", at: start)
  #expect(accepted)
  try store.save(state)
  let restored = try store.load()
  #expect(restored == state)
  #expect(restored.session?.remainingSeconds(at: start.addingTimeInterval(60)) == 480)
  #expect(restored.renewalCode == "ABC12345")
  #expect(!restored.shouldFetchRenewal(at: start))
}
