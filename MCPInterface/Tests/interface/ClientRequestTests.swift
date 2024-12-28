import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  enum ClientRequestTest {

    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeInitializeRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "initialize",
              "params": {
                "protocolVersion": "1.0",
                "capabilities": {
                  "roots": {
                    "listChanged": true
                  }
                },
                "clientInfo": {
                  "name": "TestClient",
                  "version": "1.0.0"
                }
              }
            }
            """,
          .initialize(.init(
            protocolVersion: "1.0",
            capabilities: .init(roots: .init(listChanged: true)),
            clientInfo: .init(name: "TestClient", version: "1.0.0"))))
      }

      @Test
      func decodeListPromptsRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/list"
            }
            """,
          .listPrompts(nil))
      }

      @Test
      func decodeGetPromptRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/get",
              "params": {
                "name": "code_review"
              }
            }
            """,
          .getPrompt(.init(name: "code_review")))
      }

      @Test
      func decodeListResourcesRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/list"
            }
            """,
          .listResources(nil))
      }

      @Test
      func decodeReadResourceRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/read",
              "params": {
                "uri": "file:///example.txt"
              }
            }
            """,
          .readResource(.init(uri: "file:///example.txt")))
      }

      @Test
      func decodeSubscribeToResourceRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/subscribe",
              "params": {
                "uri": "file:///example.txt"
              }
            }
            """,
          .subscribeToResource(.init(uri: "file:///example.txt")))
      }

      @Test
      func decodeUnsubscribeToResourceRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/unsubscribe",
              "params": {
                "uri": "file:///example.txt"
              }
            }
            """,
          .unsubscribeToResource(.init(uri: "file:///example.txt")))
      }

      @Test
      func decodeListResourceTemplatesRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "resources/templates/list"
            }
            """,
          .listResourceTemplates(nil))
      }

      @Test
      func decodeListToolsRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "tools/list"
            }
            """,
          .listTools(nil))
      }

      @Test
      func decodeCallToolRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "tools/call",
              "params": {
                "name": "format_code",
                "arguments": {
                  "language": "swift",
                  "style": "default"
                }
              }
            }
            """,
          .callTool(.init(
            name: "format_code",
            arguments: .object([
              "language": .string("swift"),
              "style": .string("default"),
            ]))))
      }

      @Test
      func decodeCompleteRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "completion/complete",
              "params": {
                "ref": {
                  "type": "ref/prompt",
                  "name": "code_completion"
                },
                "argument": {
                  "name": "prefix",
                  "value": "func test"
                }
              }
            }
            """,
          .complete(.init(
            ref: .prompt(.init(name: "code_completion")),
            argument: .init(name: "prefix", value: "func test"))))
      }

      @Test
      func decodeSetLogLevelRequest() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "logging/setLevel",
              "params": {
                "level": "debug"
              }
            }
            """,
          .setLogLevel(.init(level: .debug)))
      }

      // MARK: Private

      private func testDecoding(of json: String, _ value: ClientRequest) throws {
        let data = json.data(using: .utf8)!
        let decodedValue = try JSONDecoder().decode(ClientRequest.self, from: data)
        #expect(decodedValue == value)
      }
    }
  }
}
