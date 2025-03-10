
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class ListPromptsTests: MCPConnectionTest {

    @Test("list prompts")
    func test_listPrompts() async throws {
      let prompts = try await assert(
        executing: {
          try await self.clientConnection.listPrompts()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "prompts/list",
              "params": {}
            }
            """),
          .serverResponding { request in
            guard case .listPrompts = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListPromptsResult(prompts: [
              .init(
                name: "code_review",
                description: "Asks the LLM to analyze code quality and suggest improvements",
                arguments: [
                  .init(
                    name: "code",
                    description: "The code to review",
                    required: true),
                ]),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "prompts": [
                  {
                    "name": "code_review",
                    "description": "Asks the LLM to analyze code quality and suggest improvements",
                    "arguments": [
                      {
                        "name": "code",
                        "description": "The code to review",
                        "required": true
                      }
                    ]
                  }
                ]
              }
            }
            """),
        ])
      #expect(prompts.map(\.name) == ["code_review"])
    }

    @Test("list prompts with pagination")
    func test_listPrompts_withPagination() async throws {
      let prompts = try await assert(
        executing: { try await self.clientConnection.listPrompts() },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "prompts/list",
              "params" : {}
            }
            """),
          .serverResponding { request in
            guard case .listPrompts = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListPromptsResult(
              nextCursor: "next-page-cursor",
              prompts: [
                .init(
                  name: "code_review",
                  description: "Asks the LLM to analyze code quality and suggest improvements",
                  arguments: [
                    .init(
                      name: "code",
                      description: "The code to review",
                      required: true),
                  ]),
              ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "prompts": [
                  {
                    "name": "code_review",
                    "description": "Asks the LLM to analyze code quality and suggest improvements",
                    "arguments": [
                      {
                        "name": "code",
                        "description": "The code to review",
                        "required": true
                      }
                    ]
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
              "method" : "prompts/list",
              "params" : {
                "cursor": "next-page-cursor"
              }
            }
            """),
          .serverResponding { request in
            guard case .listPrompts = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListPromptsResult(prompts: [
              .init(
                name: "test_code",
                description: "Asks the LLM to write a unit test for the code",
                arguments: [
                  .init(
                    name: "code",
                    description: "The code to test",
                    required: true),
                ]),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 2,
              "result": {
                "prompts": [
                  {
                    "name": "test_code",
                    "description": "Asks the LLM to write a unit test for the code",
                    "arguments": [
                      {
                        "name": "code",
                        "description": "The code to test",
                        "required": true
                      }
                    ]
                  }
                ]
              }
            }
            """),
        ])
      #expect(prompts.map(\.name) == ["code_review", "test_code"])
    }

    @Test("receiving prompts list changed notification")
    func test_receivingPromptsListChangedNotification() async throws {
      try await assert(
        executing: {
          try await self.serverConnection.notifyPromptListChanged()
        },
        triggers: [
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "method": "notifications/prompts/list_changed",
              "params": null
            }
            """),
          .clientReceiving { notification in
            guard case .promptListChanged = notification else {
              throw Issue.record("Unexpected notification: \(notification)")
            }
          },
        ])
    }
  }
}
