
import JSONRPC
import MCPInterface
import Testing

extension MCPConnectionTestSuite {
  final class CreateSamplingMessageTests: MCPConnectionTest {

    @Test("create sampling message")
    func test_createSamplingMessage() async throws {
      let sampledMessage = try await assert(
        executing: {
          try await self.serverConnection.requestCreateMessage(
            .init(
              messages: [
                .init(
                  role: .user,
                  content: .text(.init(text: "What is the capital of France?"))),
              ],
              modelPreferences: .init(
                hints: [
                  .init(name: "claude-3-sonnet"),
                ],
                speedPriority: 0.5,
                intelligencePriority: 0.8),
              systemPrompt: "You are a helpful assistant.",
              maxTokens: 100))

        },
        triggers: [
          .serverSendsJrpc(
            """
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
            """),
          .clientResponding { request in
            guard case .createMessage(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.modelPreferences?.hints?.first?.name == "claude-3-sonnet")

            return .success(CreateMessageResult(
              role: .assistant,
              content: .text(.init(text: "The capital of France is Paris.")),
              model: "claude-3-sonnet-20240307",
              stopReason: "endTurn"))
          },
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "role": "assistant",
                "content": {
                  "type": "text",
                  "text": "The capital of France is Paris."
                },
                "model": "claude-3-sonnet-20240307",
                "stopReason": "endTurn"
              }
            }
            """),
        ])
      #expect(sampledMessage.content.text?.text == "The capital of France is Paris.")
    }

  }
}
