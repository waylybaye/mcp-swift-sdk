
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class ListToolsTests: MCPConnectionTest {

    @Test("list tools")
    func test_listTools() async throws {
      let tools = try await assert(
        executing: {
          try await self.clientConnection.listTools()
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "tools/list",
              "params" : {}
            }
            """),
          .serverResponding { request in
            guard case .listTools = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            return .success(ListToolsResult(tools: [
              .init(
                name: "get_weather",
                description: "Get current weather information for a location",
                inputSchema: [
                  "type": "object",
                  "properties": [
                    "location": [
                      "type": "string",
                      "description": "City name or zip code",
                    ],
                  ],
                  "required": ["location"],
                ]),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "tools": [
                  {
                    "name": "get_weather",
                    "description": "Get current weather information for a location",
                    "inputSchema": {
                      "type": "object",
                      "properties": {
                        "location": {
                          "type": "string",
                          "description": "City name or zip code"
                        }
                      },
                      "required": ["location"]
                    }
                  }
                ]
              }
            }
            """),
        ])
      #expect(tools.map(\.name) == ["get_weather"])
    }

    @Test("list tools with pagination")
    func test_listTools_withPagination() async throws {
      let tools = try await assert(
        executing: { try await self.clientConnection.listTools() },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "tools/list",
              "params" : {}
            }
            """),
          .serverResponding { request in
            guard case .listTools(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == nil)

            return .success(ListToolsResult(nextCursor: "next-page-cursor", tools: [
              .init(
                name: "get_weather",
                description: "Get current weather information for a location",
                inputSchema: [
                  "type": "object",
                  "properties": [
                    "location": [
                      "type": "string",
                      "description": "City name or zip code",
                    ],
                  ],
                  "required": ["location"],
                ]),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "tools": [
                  {
                    "name": "get_weather",
                    "description": "Get current weather information for a location",
                    "inputSchema": {
                      "type": "object",
                      "properties": {
                        "location": {
                          "type": "string",
                          "description": "City name or zip code"
                        }
                      },
                      "required": ["location"]
                    }
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
              "method" : "tools/list",
              "params" : {
                "cursor": "next-page-cursor"
              }
            }
            """),
          .serverResponding { request in
            guard case .listTools(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.cursor == "next-page-cursor")

            return .success(ListToolsResult(tools: [
              .init(
                name: "get_time",
                description: "Get current time information for a location",
                inputSchema: [
                  "type": "object",
                  "properties": [
                    "location": [
                      "type": "string",
                      "description": "City name or zip code",
                    ],
                  ],
                  "required": ["location"],
                ]),
            ]))
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 2,
              "result": {
                "tools": [
                  {
                    "name": "get_time",
                    "description": "Get current time information for a location",
                    "inputSchema": {
                      "type": "object",
                      "properties": {
                        "location": {
                          "type": "string",
                          "description": "City name or zip code"
                        }
                      },
                      "required": ["location"]
                    }
                  }
                ]
              }
            }
            """),
        ])

      #expect(tools.map(\.name) == ["get_weather", "get_time"])
    }

    @Test("receiving list tool changed notification")
    func test_receivingListToolChangedNotification() async throws {
      let notificationReceived = expectation(description: "Notification received")
      Task {
        for await notification in await clientConnection.notifications {
          switch notification {
          case .toolListChanged:
            notificationReceived.fulfill()
          default:
            Issue.record("Unexpected notification: \(notification)")
          }
        }
      }

      clientTransport.receive(message: """
        {
          "jsonrpc": "2.0",
          "method": "notifications/tools/list_changed"
        }
        """)
      try await fulfillment(of: [notificationReceived])
    }
  }
}
