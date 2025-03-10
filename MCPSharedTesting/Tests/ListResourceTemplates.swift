
import JSONRPC
import MCPInterface
import Testing

extension MCPConnectionTestSuite {
  final class ListResourceTemplatesTests: MCPConnectionTest {

    @Test("list resource templates")
    func test_listResourceTemplates() async throws {
      let resources = try await assert(
        executing: {
          try await self.clientConnection.listResourceTemplates()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/templates/list",
              "params": {}
            }
            """),
          .serverResponding { request in
            guard case .listResourceTemplates = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListResourceTemplatesResult(
              resourceTemplates: [
                .init(
                  uriTemplate: "file:///{path}",
                  name: "Project Files",
                  description: "Access files in the project directory",
                  mimeType: "application/octet-stream"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "resourceTemplates": [
                  {
                    "uriTemplate": "file:///{path}",
                    "name": "Project Files",
                    "description": "Access files in the project directory",
                    "mimeType": "application/octet-stream"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.map(\.uriTemplate) == ["file:///{path}"])
    }

    @Test("list resource templates with pagination")
    func test_listResourceTemplates_withPagination() async throws {
      let resources = try await assert(
        executing: { try await self.clientConnection.listResourceTemplates() },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/templates/list",
              "params": {}
            }
            """),
          .serverResponding { request in
            guard case .listResourceTemplates(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == nil)

            return .success(ListResourceTemplatesResult(
              nextCursor: "next-page-cursor",
              resourceTemplates: [
                .init(
                  uriTemplate: "file:///{path}",
                  name: "Project Files",
                  description: "Access files in the project directory",
                  mimeType: "application/octet-stream"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "resourceTemplates": [
                  {
                    "uriTemplate": "file:///{path}",
                    "name": "Project Files",
                    "description": "Access files in the project directory",
                    "mimeType": "application/octet-stream"
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
              "method" : "resources/templates/list",
              "params" : {
                "cursor": "next-page-cursor"
              }
            }
            """),
          .serverResponding { request in
            guard case .listResourceTemplates(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == "next-page-cursor")

            return .success(ListResourceTemplatesResult(
              resourceTemplates: [
                .init(
                  uriTemplate: "images:///{path}",
                  name: "Project Images",
                  description: "Access images in the project directory",
                  mimeType: "image/jpeg"),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 2,
              "result": {
                "resourceTemplates": [
                  {
                    "uriTemplate": "images:///{path}",
                    "name": "Project Images",
                    "description": "Access images in the project directory",
                    "mimeType": "image/jpeg"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.map(\.uriTemplate) == ["file:///{path}", "images:///{path}"])
    }

  }
}
