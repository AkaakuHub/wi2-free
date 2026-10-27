// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Wi2Agent",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "wi2-agent", targets: ["Wi2Agent"]),
  ],
  targets: [
    .target(name: "Wi2AgentCore"),
    .executableTarget(name: "Wi2Agent", dependencies: ["Wi2AgentCore"]),
    .testTarget(name: "Wi2AgentCoreTests", dependencies: ["Wi2AgentCore"]),
  ],
)
