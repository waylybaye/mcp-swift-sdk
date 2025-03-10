
import MCPInterface
import Testing
@testable import MCPClient

// MARK: - MCPClientTestSuite

@Suite("MCP Client")
class MCPClientTestSuite { }

// MARK: - MCPClientTest

class MCPClientTest {

  init() {
    version = "1.0.0"
    name = "TestClient"
    capabilities = ClientCapabilities(
      roots: .init(listChanged: true),
      sampling: .init())

    connection = try! MockMCPClientConnection(
      info: .init(name: name, version: version),
      capabilities: capabilities)

    connection.initializeStub = {
      .init(
        protocolVersion: MCP.protocolVersion,
        capabilities: .init(
          logging: EmptyObject(),
          prompts: ListChangedCapability(listChanged: true),
          resources: CapabilityInfo(subscribe: true, listChanged: true),
          tools: ListChangedCapability(listChanged: true)),
        serverInfo: .init(name: "test-server", version: MCP.protocolVersion))
    }
    connection.acknowledgeInitializationStub = { }
    connection.listToolsStub = { [] }
    connection.listPromptsStub = { [] }
    connection.listResourcesStub = { [] }
    connection.listResourceTemplatesStub = { [] }
  }

  let version: String
  let capabilities: ClientCapabilities
  let name: String
  let connection: MockMCPClientConnection

  func createMCPClient(
    samplingRequestHandler: CreateSamplingMessageRequest.Handler? = nil,
    listRootRequestHandler: ListRootsRequest.Handler? = nil,
    connection: MCPClientConnectionInterface? = nil)
    async throws -> MCPClient
  {
    try await MCPClient(
      capabilities: ClientCapabilityHandlers(
        roots: listRootRequestHandler.map { .init(
          info: .init(listChanged: true),
          handler: $0) },
        sampling: samplingRequestHandler.map { .init(handler: $0) }),
      connection: connection ?? self.connection)
  }

}
