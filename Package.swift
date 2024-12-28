// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MCP",
  platforms: [
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "MCPClient",
      targets: [
        "MCPClient",
      ]),
    .library(
      name: "MCPServer",
      targets: [
        "MCPServer",
      ]),
    .executable(name: "ExampleMCPServer", targets: [
      "ExampleMCPServer",
    ]),
  ],
  dependencies: [
    .package(url: "https://github.com/ChimeHQ/JSONRPC", revision: "ef61a695bafa0e07080dadac65a0c59b37880548"),
    .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro", from: "0.5.1"),
//    .package(url: "https://github.com/gsabran/swift-json-schema", from: "0.3.1"),
    .package(url: "https://github.com/gsabran/swift-json-schema", branch: "main"),
    // Dev dependency
    .package(url: "https://github.com/airbnb/swift", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "MCPClient",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "MCPInterface"),
      ],
      path: "MCPClient/Sources"),
    .target(
      name: "MCPServer",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "MCPInterface"),
        .product(name: "JSONSchema", package: "swift-json-schema"),
        .product(name: "JSONSchemaBuilder", package: "swift-json-schema"),
      ],
      path: "MCPServer/Sources"),
    .target(
      name: "MCPInterface",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
      ],
      path: "MCPInterface/Sources"),

    // Examples
    .executableTarget(
      name: "ExampleMCPServer",
      dependencies: [
        .target(name: "MCPServer"),
      ],
      path: "ExampleMCPServer/Sources"),

    // Tests libraries
    .target(
      name: "MCPTestingUtils",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "MCPInterface"),
        .target(name: "SwiftTestingUtils"),
      ],
      path: "MCPTestingUtils/Sources"),
    .target(
      name: "SwiftTestingUtils",
      dependencies: [],
      path: "SwiftTestingUtils/Sources"),
    .testTarget(
      name: "MCPClientTests",
      dependencies: [
        .target(name: "MCPClient"),
        .target(name: "MCPInterface"),
        .target(name: "MCPTestingUtils"),
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "SwiftTestingUtils"),
      ],
      path: "MCPClient/Tests"),
    .testTarget(
      name: "MCPServerTests",
      dependencies: [
        .target(name: "MCPServer"),
        .target(name: "MCPInterface"),
        .target(name: "MCPTestingUtils"),
        .target(name: "SwiftTestingUtils"),
        .product(name: "JSONRPC", package: "JSONRPC"),
      ],
      path: "MCPServer/Tests"),
    .testTarget(
      name: "MCPInterfaceTests",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "MCPInterface"),
      ],
      path: "MCPInterface/Tests"),
    .testTarget(
      name: "MCPSharedTesting",
      dependencies: [
        .product(name: "JSONRPC", package: "JSONRPC"),
        .target(name: "MCPInterface"),
        .target(name: "MCPClient"),
        .target(name: "MCPServer"),
        .target(name: "MCPTestingUtils"),
        .target(name: "SwiftTestingUtils"),
      ],
      path: "MCPSharedTesting/Tests"),
  ])
