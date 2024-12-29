
import JSONRPC
import JSONSchemaBuilder
import MCPInterface
import SwiftTestingUtils
import Testing
@testable import MCPServer

// MARK: - EmptyInput

@Schemable
struct EmptyInput { }

// MARK: - MCPServerTestSuite.CallTool

extension MCPServerTestSuite {

  class CallTool: MCPServerTest {

    @Test("call tool works when supported")
    func test_callTool_worksWhenSupported() async throws {
      let testTool = Tool(name: "test") { (_: EmptyInput) async throws in [] }

      let sut = try await createMCPServer(tools: [
        testTool,
      ])

      let exp = expectation(description: "tool call response received")
      connection?.sendRequestToStream((
        ClientRequest.callTool(.init(name: "test", arguments: [:])),
        { response in
          do {
            switch response {
            case .success(let result):
              let callToolResult = try #require(result as? CallToolResult)
              if callToolResult.isError == true {
                let text: String? = callToolResult.content.first?.text?.text
                Issue.record(text.map { Comment(stringLiteral: $0) })
              }

            case .failure(let error):
              throw error
            }
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
        }))

      try await fulfillment(of: exp)
      _ = sut
    }

    @Test("call tool fails with bad input")
    func test_callTool_failsWithBadInput() async throws {
      let testTool = Tool(name: "test") { (_: EmptyInput) async throws in
        []
      }

      let sut = try await createMCPServer(tools: [
        testTool,
      ])

      let exp = expectation(description: "tool call response received")
      let badInput: JSON? = nil
      connection?.sendRequestToStream((
        ClientRequest.callTool(.init(name: "test", arguments: badInput)),
        { response in
          do {
            switch response {
            case .success(let result):
              let callToolResult = try #require(result as? CallToolResult)
              if callToolResult.isError == true {
                #expect(callToolResult.content.first?.text?.text == """
                  Decoding error. Received:
                  null
                  Expected schema:
                  {
                    "type" : "object"
                  }
                  """)
              } else {
                Issue.record("Expected response with error but got success")
              }

            case .failure(let error):
              throw error
            }
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
        }))

      try await fulfillment(of: exp)
      _ = sut
    }

    @Test("call tool fails with unknown tool")
    func test_callTool_failsWithUnknownTool() async throws {
      let testTool = Tool(name: "test") { (_: EmptyInput) async throws in
        []
      }

      let sut = try await createMCPServer(tools: [
        testTool,
      ])

      let exp = expectation(description: "tool call response received")
      connection?.sendRequestToStream((
        ClientRequest.callTool(.init(name: "unknown-tool", arguments: nil)),
        { response in
          switch response {
          case .success:
            Issue.record("Expected error but got success")
          case .failure(let error):
            #expect(error.code == JRPCErrorCodes.invalidParams.rawValue)
            #expect(error.message == "Unknown tool: unknown-tool")
          }
          exp.fulfill()
        }))

      try await fulfillment(of: exp)
      _ = sut
    }
  }

}
