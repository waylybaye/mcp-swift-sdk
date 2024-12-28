
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class ReadResourceTests: MCPConnectionTest {

    @Test("read one resource")
    func test_readOneResource() async throws {
      let resources = try await assert(
        executing: {
          try await self.clientConnection.readResource(.init(uri: "file:///project/src/main.rs"))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/read",
              "params": {
                "uri": "file:///project/src/main.rs"
              }
            }
            """),
          .serverResponding { request in
            guard case .readResource(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.uri == "file:///project/src/main.rs")

            return .success(ReadResourceResult(
              contents: [
                .text(.init(
                  uri: "file:///project/src/main.rs",
                  mimeType: "text/x-rust",
                  text: "fn main() {\n    println!(\"Hello world!\");\n}")),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "contents": [
                  {
                    "uri": "file:///project/src/main.rs",
                    "mimeType": "text/x-rust",
                    "text": "fn main() {\\n    println!(\\"Hello world!\\");\\n}"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.contents.map { $0.text?.text } == ["fn main() {\n    println!(\"Hello world!\");\n}"])
    }

    @Test("read resources of different types")
    func test_readResourcesOfDifferentTypes() async throws {
      let resources = try await assert(
        executing: {
          try await self.clientConnection.readResource(.init(uri: "file:///project/src/*"))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/read",
              "params": {
                "uri": "file:///project/src/*"
              }
            }
            """),
          .serverResponding { _ in
            .success(ReadResourceResult(
              contents: [
                .text(.init(
                  uri: "file:///project/src/main.rs",
                  mimeType: "text/x-rust",
                  text: "fn main() {\n    println!(\"Hello world!\");\n}")),
                .blob(.init(
                  uri: "file:///project/src/main.rs",
                  mimeType: "image/jpeg",
                  blob: "base64-encoded-image-data")),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "contents": [
                  {
                    "uri": "file:///project/src/main.rs",
                    "mimeType": "text/x-rust",
                    "text": "fn main() {\\n    println!(\\"Hello world!\\");\\n}"
                  },
                  {
                    "uri": "file:///project/src/main.rs",
                    "mimeType": "image/jpeg",
                    "blob": "base64-encoded-image-data"
                  }
                ]
              }
            }
            """),
        ])
      #expect(resources.contents.map { $0.text?.text } == ["fn main() {\n    println!(\"Hello world!\");\n}", nil])
      #expect(resources.contents.map { $0.blob?.mimeType } == [nil, "image/jpeg"])
    }

    @Test("error when reading resource")
    func test_errorWhenReadingResource() async throws {
      await assert(
        executing: { try await self.clientConnection.readResource(.init(uri: "file:///nonexistent.txt")) },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/read",
              "params": {
                "uri": "file:///nonexistent.txt"
              }
            }
            """),
          .serverResponding { _ in
            .failure(.init(code: -32002, message: "Resource not found", data: [
              "uri": .string("file:///nonexistent.txt"),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "error": {
                "code": -32002,
                "message": "Resource not found",
                "data": {
                  "uri": "file:///nonexistent.txt"
                }
              }
            }
            """),
        ],
        andFailsWith: { error in
          guard let error = error as? JSONRPCResponseError<JSONValue> else {
            Issue.record("Unexpected error type: \(error)")
            return
          }

          #expect(error.code == -32002)
          #expect(error.message == "Resource not found")
          #expect(error.data == .hash([
            "uri": .string("file:///nonexistent.txt"),
          ]))
        })
    }

    @Test("subscribing to resource updates")
    func test_subscribingToResourceUpdates() async throws {
      try await assert(
        executing: { try await self.clientConnection.subscribeToUpdateToResource(.init(uri: "file:///project/src/main.rs")) },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "resources/subscribe",
              "params" : {
                "uri" : "file:///project/src/main.rs"
              }
            }
            """),
          .serverResponding { request in
            guard case .subscribeToResource(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.uri == "file:///project/src/main.rs")

            return .success(EmptyObject())
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {}
            }
            """),
        ])
    }

    @Test("unsubscribing to resource updates")
    func test_unsubscribingToResourceUpdates() async throws {
      try await assert(
        executing: { try await self.clientConnection.unsubscribeToUpdateToResource(.init(uri: "file:///project/src/main.rs")) },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "resources/unsubscribe",
              "params" : {
                "uri" : "file:///project/src/main.rs"
              }
            }
            """),
          .serverResponding { request in
            guard case .unsubscribeToResource(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.uri == "file:///project/src/main.rs")

            return .success(EmptyObject())
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {}
            }
            """),
        ])
    }

    @Test("receiving resource update notification")
    func test_receivingResourceUpdateNotification() async throws {
      try await assert(executing: {
        try await self.serverConnection.notifyResourceUpdated(.init(uri: "file:///project/src/main.rs"))
      }, triggers: [
        .serverSendsJrpc("""
          {
            "jsonrpc": "2.0",
            "method": "notifications/resources/updated",
            "params": {
              "uri": "file:///project/src/main.rs"
            }
          }
          """),
        .clientReceiving { notification in
          guard case .resourceUpdated(let params) = notification else {
            throw Issue.record("Unexpected notification: \(notification)")
          }
          #expect(params.uri == "file:///project/src/main.rs")
        },
      ])
    }

  }
}
