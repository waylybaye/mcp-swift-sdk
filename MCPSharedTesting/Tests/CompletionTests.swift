
import JSONRPC
import MCPInterface
import Testing

extension MCPConnectionTestSuite {
  final class CompletionTests: MCPConnectionTest {
    @Test("request completion")
    func test_requestCompletion() async throws {
      let resources = try await assert(
        executing: {
          try await self.clientConnection.requestCompletion(CompleteRequest.Params(
            ref: .prompt(PromptReference(name: "code_review")),
            argument: .init(name: "language", value: "py")))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "completion/complete",
              "params": {
                "ref": {
                  "type": "ref/prompt",
                  "name": "code_review"
                },
                "argument": {
                  "name": "language",
                  "value": "py"
                }
              }
            }
            """),
          .serverResponding { request in
            guard case .complete(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.ref.prompt?.name == "code_review")

            return .success(CompleteResult(completion: .init(values: ["python", "pytorch", "pyside"], total: 10, hasMore: true)))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "completion": {
                  "values": ["python", "pytorch", "pyside"],
                  "total": 10,
                  "hasMore": true
                }
              }
            }
            """),
        ])
      #expect(resources.completion.values == ["python", "pytorch", "pyside"])
      #expect(resources.completion.hasMore == true)
    }
  }
}
