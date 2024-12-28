
import JSONRPC
import Testing

extension MCPConnectionTestSuite {
  final class PingTests: MCPConnectionTest {

    @Test("client sending ping")
    func clientSendingPing() async throws {
      try await assert(
        executing: {
          try await self.clientConnection.ping()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "ping",
              "params" : null
            }
            """),
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {}
            }
            """),
        ])
    }

    @Test("server sending ping")
    func serverSendingPing() async throws {
      try await assert(
        executing: {
          try await self.serverConnection.ping()
        },
        triggers: [
          .serverSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "ping",
              "params" : null
            }
            """),
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {}
            }
            """),
        ])
    }
  }
}
