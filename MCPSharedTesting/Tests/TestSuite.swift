import MCPInterface
import MCPTestingUtils
import SwiftTestingUtils
import Testing
@testable import MCPClient
@testable import MCPServer

// MARK: - MCPConnectionTestSuite

/// All the tests about `MCPClientConnection`
@Suite("MCP Connection")
class MCPConnectionTestSuite { }

// MARK: - MCPConnectionTest

/// A parent test class that provides a few util functions to assert that the interactions with the transport are as expected.
class MCPConnectionTest {

  // MARK: Lifecycle

  init() {
    clientTransport = MockTransport()
    serverTransport = MockTransport()

    clientCapabilities = ClientCapabilities(roots: .init(listChanged: true), sampling: .init())
    serverCapabilities = ServerCapabilities(
      logging: .init(),
      prompts: .init(listChanged: true),
      resources: .init(subscribe: true, listChanged: true),
      tools: .init(listChanged: true))

    clientConnection = try! MCPClientConnection(
      info: .init(name: "TestClient", version: "1.0.0"),
      capabilities: clientCapabilities,
      transport: clientTransport.dataChannel)

    serverConnection = try! MCPServerConnection(
      info: .init(name: "TestServer", version: "1.0.0"),
      capabilities: serverCapabilities,
      transport: serverTransport.dataChannel)

    clientTransport.onSendMessage { [weak self] message in
      self?.serverTransport.receive(message: String(data: message, encoding: .utf8)!)
    }
    serverTransport.onSendMessage { [weak self] message in
      self?.clientTransport.receive(message: String(data: message, encoding: .utf8)!)
    }
  }

  // MARK: Internal

  var clientTransport: MockTransport
  var serverTransport: MockTransport

  let clientCapabilities: ClientCapabilities
  let serverCapabilities: ServerCapabilities

  var clientConnection: MCPClientConnection
  var serverConnection: MCPServerConnection
}

// MARK: MCPConnectionsProvider

extension MCPConnectionTest {
  func assert<Result>(
    executing task: @escaping () async throws -> Result,
    triggers events: [Event])
    async throws -> Result
  {
    try await MCPTestingUtils.assert(
      clientTransport: clientTransport,
      serverTransport: serverTransport,
      serverRequestsHandler: await clientConnection.requestsToHandle,
      clientRequestsHandler: await serverConnection.requestsToHandle,
      serverNotifications: await clientConnection.notifications,
      clientNotifications: await serverConnection.notifications,
      executing: task,
      triggers: events)
  }

  func assert<Result>(
    executing task: @escaping () async throws -> Result,
    triggers events: [Event],
    andFailsWith errorHandler: (Error) -> Void)
    async
  {
    do {
      _ = try await assert(executing: task, triggers: events)
      Issue.record("Expected the task to fail")
    } catch {
      // Expected
      errorHandler(error)
    }
  }

}
