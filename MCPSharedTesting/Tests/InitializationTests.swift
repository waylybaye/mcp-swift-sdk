
import JSONRPC
import MCPInterface
import MCPTestingUtils
import SwiftTestingUtils
import Testing
@testable import MCPClient
@testable import MCPServer

extension MCPConnectionTestSuite {
  final class InitializationTests: MCPConnectionTest {

    @Test("initialize connection")
    func test_initializeConnection() async throws {
      let initializationResult = try await assert(
        executing: {
          try await self.clientConnection.initialize()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "initialize",
              "params" : {
                "capabilities" : {
                  "roots" : {
                    "listChanged" : true
                  },
                  "sampling" : {}
                },
                "clientInfo" : {
                  "name" : "TestClient",
                  "version" : "1.0.0"
                },
                "protocolVersion" : "\(MCP.protocolVersion)"
              }
            }
            """),
          .serverResponding { request in
            guard case .initialize(let params) = request else {
              throw Issue.record("Unexpected client request: \(request)")
            }
            #expect(params.capabilities.roots?.listChanged == true)

            return .success(InitializeResult(
              protocolVersion: "2024-11-05",
              capabilities: ServerCapabilities(
                logging: .init(),
                prompts: .init(listChanged: true),
                resources: .init(subscribe: true, listChanged: true),
                tools: .init(listChanged: true)),
              serverInfo: .init(
                name: "ExampleServer",
                version: "1.0.0")))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                  "logging": {},
                  "prompts": {
                    "listChanged": true
                  },
                  "resources": {
                    "subscribe": true,
                    "listChanged": true
                  },
                  "tools": {
                    "listChanged": true
                  }
                },
                "serverInfo": {
                  "name": "ExampleServer",
                  "version": "1.0.0"
                }
              }
            }
            """),
        ])
      #expect(initializationResult.serverInfo.name == "ExampleServer")
    }

    @Test("initialize with error")
    func test_initializeWithError() async throws {
      await assert(
        executing: { _ = try await self.clientConnection.initialize() },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "initialize",
              "params" : {
                "capabilities" : {
                  "roots" : {
                    "listChanged" : true
                  },
                  "sampling" : {}
                },
                "clientInfo" : {
                  "name" : "TestClient",
                  "version" : "1.0.0"
                },
                "protocolVersion" : "\(MCP.protocolVersion)"
              }
            }
            """),
          .serverResponding { request in
            guard case .initialize(let params) = request else {
              throw Issue.record("Unexpected client request: \(request)")
            }
            #expect(params.capabilities.roots?.listChanged == true)

            return .failure(.init(
              code: -32602,
              message: "Unsupported protocol version",
              data: .hash([
                "supported": ["2024-11-05"],
                "requested": "1.0.0",
              ])))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "error": {
                "code": -32602,
                "message": "Unsupported protocol version",
                "data": {
                  "supported": ["2024-11-05"],
                  "requested": "1.0.0"
                }
              }
            }
            """),
        ]) { error in
          guard let responseError = try? #require(error as? JSONRPCResponseError<JSONRPC.JSONValue>) else {
            Issue.record("unexpected error type \(error)")
            return
          }

          #expect(responseError.code == -32602)
          #expect(responseError.message == "Unsupported protocol version")
          #expect(responseError.data == [
            "supported": ["2024-11-05"],
            "requested": "1.0.0",
          ])
        }
    }

    @Test("initialization acknowledgement")
    func test_initializationAcknowledgement() async throws {
      try await assert(executing: {
        try await self.clientConnection.acknowledgeInitialization()
      }, triggers: [
        .clientSendsJrpc(
          """
          {
            "jsonrpc" : "2.0",
            "method" : "notifications/initialized",
            "params" : null
          }
          """),
        .serverReceiving { notification in
          guard case .initialized(let params) = notification else {
            throw Issue.record("Unexpected client notification: \(notification)")
          }
          #expect(params.value == nil)
        },
      ])
    }

    @Test("deinitialization")
    func test_deinitializationReleasesReferencedObjects() async throws {
      // initialize the MCP connection. This will create a JRPC session.
      try await test_initializeConnection()

      // Get pointers to values that we want to see dereferenced when MCPClientConnection is dereferenced
      weak var weakTransport = clientTransport
      #expect(weakTransport != nil)

      // Replace the values referenced by this test class.
      clientTransport = MockTransport()
      clientConnection = try await MCPClientConnection(
        info: clientConnection.info,
        capabilities: clientCapabilities,
        transport: clientTransport.dataChannel)

      // Verifies that the referenced objects are released.
      #expect(weakTransport == nil)
    }
  }
}
