
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum ServerNotificationTest {

    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeCancelledNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/cancelled",
              "params": {
                "requestId": "123",
                "reason": "User requested cancellation"
              }
            }
            """,
          .cancelled(.init(requestId: .string("123"), reason: "User requested cancellation")))
      }

      @Test
      func decodeLoggingMessageNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/message",
              "params": {
                "level": "error",
                "logger": "database",
                "data": {
                  "error": "Connection failed",
                  "details": {
                    "host": "localhost",
                    "port": 5432
                  }
                }
              }
            }
            """,
          .loggingMessage(.init(level: .error, logger: "database", data: .object([
            "error": .string("Connection failed"),
            "details": .object([
              "host": .string("localhost"),
              "port": .number(5432),
            ]),
          ]))))
      }

      @Test
      func decodeProgressNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/progress",
              "params": {
                "progressToken": "abc123",
                "progress": 50,
                "total": 100
              }
            }
            """,
          .progress(.init(progressToken: .string("abc123"), progress: 50, total: 100)))
      }

      @Test
      func decodePromptListChangedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/prompts/list_changed"
            }
            """,
          .promptListChanged(.init()))
      }

      @Test
      func decodeResourcesListChangedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/resources/list_changed"
            }
            """,
          .resourceListChanged(.init()))
      }

      @Test
      func decodeResourceUpdatedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/resources/updated",
              "params": {
                "uri": "file:///project/src/main.rs"
              }
            }
            """,
          .resourceUpdated(.init(uri: "file:///project/src/main.rs")))
      }

      @Test
      func decodeToolsListChangedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/tools/list_changed"
            }
            """,
          .toolListChanged(.init()))
      }

      @Test
      func failsToDecodeBadValue() throws {
        let data = """
          {
            "jsonrpc": "2.0",
            "method": "notifications/llm/unknown"
          }
          """.data(using: .utf8)!
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(ServerNotification.self, from: data) }
      }

      // MARK: Private

      private func testDecoding(of json: String, _ value: ServerNotification) throws {
        let data = json.data(using: .utf8)!
        #expect(try JSONDecoder().decode(ServerNotification.self, from: data) == value)
      }
    }
  }
}
