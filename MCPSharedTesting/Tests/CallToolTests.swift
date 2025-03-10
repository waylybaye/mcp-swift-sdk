
import JSONRPC
import MCPInterface
import Testing

// MARK: - MCPConnectionTestSuite.CallToolTests

extension MCPConnectionTestSuite {
  final class CallToolTests: MCPConnectionTest {

    @Test("call tool")
    func test_callTool() async throws {
      let weathers = try await assert(executing: {
        try await self.clientConnection.call(
          toolName: self.tool.name,
          arguments: .object([
            "location": .string("New York"),
          ]),
          progressToken: .string("toolCallId"))
          .content
          .map(\.text)
      }, triggers: [
        .clientSendsJrpc("""
          {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
              "_meta" : {
                "progressToken" : "toolCallId"
              },
              "name": "get_weather",
              "arguments": {
                "location": "New York"
              }
            }
          }
          """),
        .serverResponding { request in
          guard case .callTool(let callToolRequest) = request else {
            throw Issue.record("Unexpected request: \(request)")
          }
          #expect(callToolRequest.name == self.tool.name)

          return .success(CallToolResult(
            content: [
              .text(.init(
                text: "Current weather in New York:\nTemperature: 72°F\nConditions: Partly cloudy")),
            ]))
        },
        .serverSendsJrpc("""
          {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
              "content": [{
                "type": "text",
                "text": "Current weather in New York:\\nTemperature: 72°F\\nConditions: Partly cloudy"
              }]
            }
          }
          """),
      ])

      #expect(weathers.map { $0?.text } == ["Current weather in New York:\nTemperature: 72°F\nConditions: Partly cloudy"])
    }

    @Test("protocol error")
    func test_protocolError() async throws {
      await assert(
        executing: {
          _ = try await self.clientConnection.call(toolName: self.tool.name, arguments: .object([
            "location": .string("New York"),
          ]))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "tools/call",
              "params": {
                "name": "get_weather",
                "arguments": {
                  "location": "New York"
                }
              }
            }
            """),
          .serverResponding { _ in
            .failure(.init(code: -32602, message: "Unknown tool: invalid_tool_name"))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "error": {
                "code": -32602,
                "message": "Unknown tool: invalid_tool_name"
              }
            }
            """),
        ]) { error in
          guard let error = error as? JSONRPCResponseError<JSONValue> else {
            Issue.record("Unexpected error type: \(error)")
            return
          }

          #expect(error.code == -32602)
          #expect(error.message == "Unknown tool: invalid_tool_name")
          #expect(error.data == nil)
        }
    }

    @Test("tool call error")
    func test_toolCallError() async throws {
      let response = try await assert(
        executing: {
          try await self.clientConnection.call(
            toolName: self.tool.name,
            arguments: .object([
              "location": .string("New York"),
            ]))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "method": "tools/call",
              "params": {
                "name": "get_weather",
                "arguments": {
                  "location": "New York"
                }
              }
            }
            """),
          .serverResponding { _ in
            .success(CallToolResult(
              content: [
                .text(.init(
                  text: "Failed to fetch weather data: API rate limit exceeded")),
              ],
              isError: true))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "content": [{
                  "type": "text",
                  "text": "Failed to fetch weather data: API rate limit exceeded"
                }],
                "isError": true
              }
            }
            """),
        ])
      #expect(response.isError == true)
      #expect(response.content.map { $0.text?.text } == ["Failed to fetch weather data: API rate limit exceeded"])
    }

    private let tool = Tool(
      name: "get_weather",
      description: "Get current weather information for a location",
      inputSchema: .array([]))

  }
}

// MARK: - ToolArguments

private struct ToolArguments: Encodable {
  let location: String
}

// MARK: - ToolResponse

private struct ToolResponse: Decodable {
  let type: String
  let text: String
}
