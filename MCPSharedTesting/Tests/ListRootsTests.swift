
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class ListRootsTests: MCPConnectionTest {

    @Test("list roots")
    func test_listRoots() async throws {
      let roots = try await assert(
        executing: {
          try await self.serverConnection.listRoots()
        },
        triggers: [
          .serverSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "roots/list",
              "params" : null
            }
            """),
          .clientResponding { request in
            guard case .listRoots = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListRootsResult(roots: [
              .init(uri: "file:///home/user/projects/myproject", name: "My Project"),
            ]))
          },
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "roots": [
                  {
                    "uri": "file:///home/user/projects/myproject",
                    "name": "My Project"
                  }
                ]
              }
            }
            """),
        ])
      #expect(roots.roots.map(\.name) == ["My Project"])
    }

    @Test("receiving roots list changed notification")
    func test_receivingRootsListChangedNotification() async throws {
      try await assert(executing: {
        try await self.clientConnection.notifyRootsListChanged()
      }, triggers: [
        .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "method": "notifications/roots/list_changed",
              "params": null
            }
          """),
        .serverReceiving { notification in
          guard case .rootsListChanged = notification else {
            throw Issue.record("Unexpected notification: \(notification)")
          }
        },
      ])
    }
  }
}
