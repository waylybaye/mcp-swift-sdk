
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  enum ServerRequestTest {

    struct Deserialization {

      @Test
      func decodeCancelledNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "roots/list"
            }
            """,
          .listRoots(nil))
      }

      @Test
      func decodeLoggingMessageNotification() throws {
        try testDecoding(
          of: """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "sampling/createMessage",
              "params": {
                "messages": [
                  {
                    "role": "user",
                    "content": {
                      "type": "text",
                      "text": "What is the capital of France?"
                    }
                  }
                ],
                "modelPreferences": {
                  "hints": [
                    {
                      "name": "claude-3-sonnet"
                    }
                  ],
                  "intelligencePriority": 0.8,
                  "speedPriority": 0.5
                },
                "systemPrompt": "You are a helpful assistant.",
                "maxTokens": 100
              }
            }
            """,
          .createMessage(.init(
            messages: [.init(role: .user, content: .text(.init(text: "What is the capital of France?")))],
            modelPreferences: .init(
              hints: [.init(name: "claude-3-sonnet")],
              speedPriority: 0.5,
              intelligencePriority: 0.8),
            systemPrompt: "You are a helpful assistant.",
            maxTokens: 100)))
      }

      private func testDecoding(of json: String, _ value: ServerRequest) throws {
        let data = json.data(using: .utf8)!
        let decodedValue = try JSONDecoder().decode(ServerRequest.self, from: data)
        #expect(decodedValue == value)
      }
    }
  }
}
