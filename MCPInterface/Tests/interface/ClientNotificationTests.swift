
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  enum ClientNotificationTest {

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
      func decodeInitializedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/initialized"
            }
            """,
          .initialized(.init()))
      }

      @Test
      func decodeRootsListChangedNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "method": "notifications/roots/list_changed"
            }
            """,
          .rootsListChanged(.init()))
      }

      @Test
      func failsToDecodeBadValue() throws {
        let data = """
          {
            "jsonrpc": "2.0",
            "method": "notifications/llm/unknown"
          }
          """.data(using: .utf8)!
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(ClientNotification.self, from: data) }
      }

      // MARK: Private

      private func testDecoding(of json: String, _ value: ClientNotification) throws {
        let data = json.data(using: .utf8)!
        #expect(try JSONDecoder().decode(ClientNotification.self, from: data) == value)
      }
    }
  }
}
