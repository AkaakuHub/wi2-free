import Foundation

public enum WiFiNetworkError: Error, LocalizedError {
  case connectionFailed
  case interfaceNotFound

  public var errorDescription: String? {
    switch self {
    case .connectionFailed: "Wi2への接続に失敗しました。"
    case .interfaceNotFound: "Wi-Fiインターフェースを取得できませんでした。"
    }
  }
}

public enum WiFiHardwarePorts {
  public static func wifiDevice(in output: String) -> String? {
    let lines = output.split(whereSeparator: \ .isNewline)
    for (index, line) in lines.enumerated() where line == "Hardware Port: Wi-Fi" {
      guard index + 1 < lines.count else {
        return nil
      }
      let devicePrefix = "Device: "
      let deviceLine = String(lines[index + 1])
      guard deviceLine.hasPrefix(devicePrefix) else {
        return nil
      }
      return String(deviceLine.dropFirst(devicePrefix.count))
    }
    return nil
  }
}

public enum WiFiNetwork {
  public static func connect(ssid: String) throws {
    let hardwarePorts = try run(arguments: ["-listallhardwareports"])
    guard let device = WiFiHardwarePorts.wifiDevice(in: hardwarePorts) else {
      throw WiFiNetworkError.interfaceNotFound
    }
    _ = try run(arguments: ["-setairportnetwork", device, ssid])
  }

  private static func run(arguments: [String]) throws -> String {
    let output = Pipe()
    let process = Process()
    process.executableURL = URL(filePath: "/usr/sbin/networksetup")
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw WiFiNetworkError.connectionFailed
    }
    return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  }
}
