
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class ListResourcesTests: MCPConnectionTest {

    @Test("list resources")
    func test_listResources() async throws {
      let resources = try await assert(
        executing: {
          try await self.clientConnection.listResources()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/list",
              "params": {}
            }
            """),
          .serverResponding { request in
            guard case .listResources = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListResourcesResult(
              resources: [
                Resource(
                  uri: "file:///project/src/main.rs",
                  name: "main.rs",
                  description: "Primary application entry point",
                  mimeType: "text/x-rust"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "resources": [
                  {
                    "uri": "file:///project/src/main.rs",
                    "name": "main.rs",
                    "description": "Primary application entry point",
                    "mimeType": "text/x-rust"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.map(\.name) == ["main.rs"])
    }

    @Test("list resources with pagination")
    func test_listResources_withPagination() async throws {
      let resources = try await assert(
        executing: { try await self.clientConnection.listResources() },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "resources/list",
              "params" : {}
            }
            """),
          .serverResponding { request in
            guard case .listResources(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == nil)

            return .success(ListResourcesResult(
              nextCursor: "next-page-cursor",
              resources: [
                Resource(
                  uri: "file:///project/src/main.rs",
                  name: "main.rs",
                  description: "Primary application entry point",
                  mimeType: "text/x-rust"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "resources": [
                  {
                    "uri": "file:///project/src/main.rs",
                    "name": "main.rs",
                    "description": "Primary application entry point",
                    "mimeType": "text/x-rust"
                  }
                ],
                "nextCursor": "next-page-cursor"
              }
            }
            """),
          .clientSendsJrpc("""
            {
              "id" : 2,
              "jsonrpc" : "2.0",
              "method" : "resources/list",
              "params" : {
                "cursor": "next-page-cursor"
              }
            }
            """),
          .serverResponding { request in
            guard case .listResources(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == "next-page-cursor")

            return .success(ListResourcesResult(
              resources: [
                Resource(
                  uri: "file:///project/src/utils.rs",
                  name: "utils.rs",
                  description: "Some utils functions application entry point",
                  mimeType: "text/x-rust"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 2,
              "result": {
                "resources": [
                  {
                    "uri": "file:///project/src/utils.rs",
                    "name": "utils.rs",
                    "description": "Some utils functions application entry point",
                    "mimeType": "text/x-rust"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.map(\.name) == ["main.rs", "utils.rs"])
    }

    @Test("receiving resources list changed notification")
    func test_receivingResourcesListChangedNotification() async throws {
      try await assert(executing: {
        try await self.serverConnection.notifyResourceListChanged()
      }, triggers: [
        .serverSendsJrpc("""
          {
            "jsonrpc": "2.0",
            "method": "notifications/resources/list_changed",
            "params" : null
          }
          """),
        .clientReceiving { notification in
          guard case .resourceListChanged = notification else {
            throw Issue.record("Unexpected notification: \(notification)")
          }
        },
      ])
    }
  }
}
