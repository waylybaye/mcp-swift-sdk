
import MCPShared
import SwiftTestingUtils
import Testing
@testable import MCPClient

extension MCPClientTestSuite {

  class CallTool: MCPClientTest {

    @Test("call tool works when supported")
    func test_callTool_worksWhenSupported() async throws {
      connection.callToolStub = { toolName, _, progressToken in
        #expect(toolName == "get_weather")
        #expect(progressToken == nil)
        return CallToolRequest.Result(content: [.text(TextContent(text: "hello"))])
      }

      let sut = try await createMCPClient()
      let result = try await sut.callTool(named: "get_weather")
      #expect(result.content.map { $0.text?.text } == ["hello"])
    }

    @Test("call tool fails when the server doesn't support tools")
    func test_callTool_failsWhenNotSupported() async throws {
      connection.initializeStub = {
        .init(
          protocolVersion: MCP.protocolVersion,
          capabilities: .init(),
          serverInfo: .init(name: "test-server", version: "1.0.0"))
      }
      let sut = try await createMCPClient()

      await #expect(throws: MCPClientError.self) { try await sut.callTool(named: "get_weather") }
    }

    @Test("call tool fails when there has been an execution error")
    func test_callTool_failsWhenExecutionError() async throws {
      connection.callToolStub = { _, _, _ in
        CallToolRequest.Result(content: [.text(TextContent(text: "💥 oopsie"))], isError: true)
      }
      let sut = try await createMCPClient()

      await #expect(throws: MCPClientError.self) { try await sut.callTool(named: "get_weather") }
    }

    @Test("call tool with progress handler")
    func test_callToolWithProgress() async throws {
      let requestReceived = expectation(description: "the request was received by the server")
      let progressHandlerCalled = expectation(description: "progress handler called")
      let operationCompleted = expectation(description: "operation completed")

      var responseToToolCall: () -> Void = { }
      var progressToken: ProgressToken? = nil

      connection.callToolStub = { _, _, token in
        #expect(token != nil)
        progressToken = token

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
          responseToToolCall = { continuation.resume(returning: ()) }
          requestReceived.fulfill()
        }
        return CallToolRequest.Result(content: [.text(TextContent(text: "hello"))])
      }

      let sut = try await createMCPClient()

      Task {
        let result = try await sut.callTool(named: "get_weather", progressHandler: { progress, total in
          #expect(progress == 0.5)
          #expect(total == 1)
          progressHandlerCalled.fulfill()
        })
        #expect(result.content.map { $0.text?.text } == ["hello"])
        operationCompleted.fulfill()
      }

      try await fulfillment(of: requestReceived)
      if let progressToken {
        connection.sendNotificationToStream(.progress(.init(progressToken: progressToken, progress: 0.5, total: 1)))
      } else {
        Issue.record("No progress token")
      }

      try await fulfillment(of: progressHandlerCalled)
      responseToToolCall()

      try await fulfillment(of: operationCompleted)
    }
  }

}
