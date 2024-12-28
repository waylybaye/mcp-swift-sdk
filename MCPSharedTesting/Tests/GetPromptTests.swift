
import JSONRPC
import MCPInterface
import Testing

extension MCPConnectionTestSuite {
  final class GetPromptTests: MCPConnectionTest {

    @Test("get one prompt")
    func test_getOnePrompt() async throws {
      let prompts = try await assert(
        executing: {
          try await self.clientConnection.getPrompt(.init(name: "code_review", arguments: .object([
            "code": .string("def hello():\n    print('world')"),
          ])))
        },
        triggers: [
          .clientSendsJrpc(
            """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/get",
              "params": {
                "name": "code_review",
                "arguments": {
                  "code": "def hello():\\n    print('world')"
                }
              }
            }
            """),
          .serverResponding { request in
            guard case .getPrompt(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.name == "code_review")

            return .success(GetPromptResult(
              description: "Code review prompt",
              messages: [
                .init(
                  role: .user,
                  content: .text(.init(text: "Please review this Python code:\ndef hello():\n    print('world')"))),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "description": "Code review prompt",
                "messages": [
                  {
                    "role": "user",
                    "content": {
                      "type": "text",
                      "text": "Please review this Python code:\\ndef hello():\\n    print('world')"
                    }
                  }
                ]
              }
            }
            """),
        ])
      #expect(
        prompts.messages
          .map { $0.content.text?.text } == ["Please review this Python code:\ndef hello():\n    print('world')"])
    }

    @Test("get prompts of different types")
    func test_getPromptsOfDifferentTypes() async throws {
      let prompts = try await assert(
        executing: {
          try await self.clientConnection.getPrompt(.init(name: "code_review", arguments: .object([
            "code": .string("def hello():\n    print('world')"),
          ])))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/get",
              "params": {
                "name": "code_review",
                "arguments": {
                  "code": "def hello():\\n    print('world')"
                }
              }
            }
            """),
          .serverResponding { _ in
            .success(GetPromptResult(
              description: "Code review prompt",
              messages: [
                .init(
                  role: .user,
                  content: .text(.init(text: "Please review this Python code:\ndef hello():\n    print('world')"))),
                .init(
                  role: .user,
                  content: .image(.init(data: "base64-encoded-image-data", mimeType: "image/png"))),
                .init(
                  role: .user,
                  content: .embeddedResource(.init(resource: .text(.init(
                    uri: "resource://example",
                    mimeType: "text/plain",
                    text: "Resource content"))))),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "description": "Code review prompt",
                "messages": [
                  {
                    "role": "user",
                    "content": {
                      "type": "text",
                      "text": "Please review this Python code:\\ndef hello():\\n    print('world')"
                    }
                  },
                  {
                    "role": "user",
                    "content": {
                      "type": "image",
                      "data": "base64-encoded-image-data",
                      "mimeType": "image/png"
                    }
                  },
                  {
                    "role": "user",
                    "content": {
                      "type": "resource",
                      "resource": {
                        "uri": "resource://example",
                        "mimeType": "text/plain",
                        "text": "Resource content"
                      }
                    }
                  }
                ]
              }
            }
            """),
        ])
      #expect(
        prompts.messages.map { $0.content.text?.text } ==
          ["Please review this Python code:\ndef hello():\n    print('world')", nil, nil])
      #expect(prompts.messages.map { $0.content.image?.data } == [nil, "base64-encoded-image-data", nil])
      #expect(prompts.messages.map { $0.content.embeddedResource?.resource.text?.text } == [nil, nil, "Resource content"])
    }

    @Test("error when getting prompt")
    func test_errorWhenGettingPrompt() async throws {
      await assert(
        executing: { try await self.clientConnection.getPrompt(.init(name: "non_existent_code_review")) },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/get",
              "params": {
                "name": "non_existent_code_review"
              }
            }
            """),
          .serverResponding { _ in
            .failure(.init(code: -32002, message: "Prompt not found", data: [
              "name": "non_existent_code_review",
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "error": {
                "code": -32002,
                "message": "Prompt not found",
                "data": {
                  "name": "non_existent_code_review"
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
          #expect(error.message == "Prompt not found")
          #expect(error.data == .hash([
            "name": .string("non_existent_code_review"),
          ]))
        })
    }

  }
}
