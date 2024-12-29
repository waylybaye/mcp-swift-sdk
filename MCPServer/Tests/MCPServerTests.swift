import MCPInterface
import Testing
@testable import MCPServer

// MARK: - MCPServerTestSuite

@Suite("MCP Server")
class MCPServerTestSuite { }

// MARK: - MCPServerTest

class MCPServerTest {

  let info = Implementation(name: "TestServer", version: "1.0.0")
  var connection: MockMCPServerConnection?

  func createMCPServer(
    tools: [any CallableTool] = [],
    connection: MockMCPServerConnection? = nil)
    async throws -> MCPServer
  {
    let capabilities = ServerCapabilityHandlers(
      tools: tools)

    let connection = connection ?? (try! MockMCPServerConnection(
      info: info,
      capabilities: capabilities.description))
    self.connection = connection

    return try await withCheckedThrowingContinuation { continuation in
      Task {
        do {
          let sut = try await MCPServer(
            info: info,
            capabilities: capabilities,
            connection: connection)
          continuation.resume(returning: sut)
        } catch {
          continuation.resume(throwing: error)
        }
      }

      connection.sendRequestToStream((
        ClientRequest.initialize(.init(
          protocolVersion: MCP.protocolVersion,
          capabilities: .init(),
          clientInfo: .init(name: "TestClient", version: "1.0.0"))),
        { _ in }))
    }
  }

}
