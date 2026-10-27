import Foundation
import Testing
@testable import Wi2AgentCore

@Test
func wifiHardwarePortsFindsWiFiDevice() {
  let output = """
    Hardware Port: Ethernet Adapter (en4)
    Device: en4

    Hardware Port: Wi-Fi
    Device: en0
    """

  #expect(WiFiHardwarePorts.wifiDevice(in: output) == "en0")
}

@Test
func wifiHardwarePortsReturnsNilWhenWiFiDeviceIsAbsent() {
  let output = """
    Hardware Port: Ethernet Adapter (en4)
    Device: en4
    """

  #expect(WiFiHardwarePorts.wifiDevice(in: output) == nil)
}

@Test
func guestSessionRequestsRenewalTwoMinutesBeforeExpiry() {
  let startedAt = Date(timeIntervalSince1970: 0)
  let session = GuestSession(startedAt: startedAt)

  #expect(!session.shouldPrepareRenewal(at: startedAt.addingTimeInterval(479)))
  #expect(session.shouldPrepareRenewal(at: startedAt.addingTimeInterval(480)))
  #expect(!session.shouldPrepareRenewal(at: startedAt.addingTimeInterval(600)))
}

@Test
func sessionClockFormatsRemainingTime() {
  #expect(SessionClock.format(seconds: 479.9) == "07:59")
  #expect(SessionClock.format(seconds: -1) == "00:00")
}
