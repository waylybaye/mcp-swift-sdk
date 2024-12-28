
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

extension MCPConnectionTestSuite {
  final class LoggingTests: MCPConnectionTest {
    @Test("setting log level")
    func test_settingLogLevel() async throws {
      _ = try await assert(
        executing: {
          try await self.clientConnection.setLogLevel(SetLevelRequest.Params(level: .debug))
        },
        triggers: [
          .clientSendsJrpc("""
            {
              "id" : 1,
              "jsonrpc" : "2.0",
              "method" : "logging/setLevel",
              "params" : {
                "level" : "debug"
              }
            }
            """),
          .serverResponding { request in
            guard case .setLogLevel(let params) = request else {
              throw Issue.record("Unexpected request: \(request)")
            }
            #expect(params.level == .debug)

            return .success(SetLevelRequest.Result())
          },
          .serverSendsJrpc("""
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {}
            }
            """),
        ])
    }

    @Test("send a log")
    func test_sendALog() async throws {
      try await assert(
        executing: {
          try await self.serverConnection.log(LoggingMessageNotification.Params(level: .debug, data: .string("Up and running!")))
        },
        triggers: [
          .serverSendsJrpc("""
            {
              "jsonrpc" : "2.0",
              "method" : "notifications/message",
              "params" : {
                "data" : "Up and running!",
                "level" : "debug"
              }
            }
            """),
          .clientReceiving { notification in
            guard case .loggingMessage(let message) = notification else {
              throw Issue.record("Unexpected notification: \(notification)")
            }
            #expect(message.level == .debug)
            #expect(message.data == "Up and running!")
          },
        ])
    }

    @Test("receive a server log notification")
    func test_receivesServerLogNotification() async throws {
//      let notificationReceived = expectation(description: "Notification received")
//      Task {
//        for await notification in await sut.notifications {
//          switch notification {
//          case .loggingMessage(let message):
//            #expect(message.level == .error)
//            #expect(message.data == .object([
//              "error": .string("Connection failed"),
//              "details": .object([
//                "host": .string("localhost"),
//                "port": .number(5432),
//              ]),
//            ]))
//            notificationReceived.fulfill()
//
//          default:
//            Issue.record("Unexpected notification: \(notification)")
//          }
//        }
//      }
//
//      transport.receive(message: """
//        {
//          "jsonrpc": "2.0",
//          "method": "notifications/message",
//          "params": {
//            "level": "error",
//            "logger": "database",
//            "data": {
//              "error": "Connection failed",
//              "details": {
//                "host": "localhost",
//                "port": 5432
//              }
//            }
//          }
//        }
//        """)
//      try await fulfillment(of: [notificationReceived])
    }

  }
}
