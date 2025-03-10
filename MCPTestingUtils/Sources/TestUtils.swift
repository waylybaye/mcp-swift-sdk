
import Foundation
import JSONRPC
import MCPInterface
import SwiftTestingUtils
import Testing

/// Asserts that the received JSON is equal to the expected JSON, allowing for any order of keys or spacing.
public func assertEqual(received jsonData: Data, expected: String) {
  do {
    let received = try JSONSerialization.jsonObject(with: jsonData)
    let receivedPrettyPrinted = try JSONSerialization.data(withJSONObject: received, options: [.sortedKeys, .prettyPrinted])

    let expected = try JSONSerialization.jsonObject(with: expected.data(using: .utf8)!)
    let expectedPrettyPrinted = try JSONSerialization.data(withJSONObject: expected, options: [.sortedKeys, .prettyPrinted])

    #expect(String(data: receivedPrettyPrinted, encoding: .utf8)! == String(data: expectedPrettyPrinted, encoding: .utf8)!)
  } catch {
    Issue.record("Failed to compare JSON: \(error)")
  }
}

// MARK: - TestError

public enum TestError: Error {
  case expectationUnfulfilled
  case internalError
}

// MARK: - Event

public enum Event {
  case clientSendsJrpc(_ value: String)
  case serverSendsJrpc(_ value: String)
  case serverResponding(_ request: (ClientRequest) async throws -> AnyJRPCResponse)
  case clientResponding(_ request: (ServerRequest) async throws -> AnyJRPCResponse)
  case serverReceiving(_ notification: (ClientNotification) async throws -> Void)
  case clientReceiving(_ notification: (ServerNotification) async throws -> Void)
}

/// Asserts that the given task sends the expected requests and receives the expected responses.
/// - Parameters:
///  - clientTransport: The transport to use to send messages to the client.
///  - serverTransport: The transport to use to send messages to the server.
///  - serverRequestsHandler: The client's handler that receives server requests. If nil, the client's requests (`clientSendsJrpc`) will be sent immediately.
///  - clientRequestsHandler: The server's handler that receives client requests. If nil, the server's requests (`serverSendsJrpc`) will be sent immediately.
///  - serverNotifications: The client's stream of notifications received from the server.
///  - clientNotifications: The server's stream of notifications received from the client.
///  - task: The task to execute.
///  - events: The sequence of events relevant to the task.
public func assert<Result>(
  clientTransport: MockTransport?,
  serverTransport: MockTransport?,
  serverRequestsHandler: AsyncStream<HandleServerRequest>?,
  clientRequestsHandler: AsyncStream<HandleClientRequest>?,
  serverNotifications: AsyncStream<ServerNotification>?,
  clientNotifications: AsyncStream<ClientNotification>?,
  executing task: @escaping () async throws -> Result,
  triggers events: [Event])
  async throws -> Result
{
  var result: Result? = nil
  var err: Error? = nil

  /// The next JRPC message that is expected to be sent
  var nextMessageToSent: (exp: SwiftTestingUtils.Expectation, clientMessage: String?, serverMessage: String?)?

  clientTransport?.onSendMessage { data in
    if let (exp, message, _) = nextMessageToSent, let message {
      assertEqual(received: data, expected: message)
      exp.fulfill()
    } else {
      Issue.record("Unexpected message sent: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
    }
  }

  serverTransport?.onSendMessage { data in
    if let (exp, _, message) = nextMessageToSent, let message {
      assertEqual(received: data, expected: message)
      exp.fulfill()
    } else {
      Issue.record("Unexpected message sent: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
    }
  }

  var i = 0
  let prepareNextExpectedMessage = {
    loop: for j in i..<events.count {
      switch events[j] {
      case .clientSendsJrpc(let request):
        nextMessageToSent = (
          exp: expectation(description: "jrpc request sent (event #\(j))"),
          clientMessage: request,
          serverMessage: nil)
        break loop

      case .serverSendsJrpc(let response):
        if clientRequestsHandler != nil {
          nextMessageToSent = (
            exp: expectation(description: "jrpc response sent (event #\(j))"),
            clientMessage: nil,
            serverMessage: response)
          break loop
        }

      default:
        break
      }
    }
  }
  prepareNextExpectedMessage()

  // Start the task
  let taskCompleted = expectation(description: "task completed")
  var expectations = [taskCompleted]

  Task {
    do {
      result = try await task()
    } catch {
      err = error
    }
    taskCompleted.fulfill()
  }

  // Process each event
  while i < events.count {
    let event = events[i]
    i += 1
    switch event {
    case .clientSendsJrpc(let message):
      if serverRequestsHandler != nil {
        // Wait for the handler to sent the message.
        guard let exp = nextMessageToSent?.exp, nextMessageToSent?.clientMessage != nil else {
          throw TestError.internalError
        }
        try await fulfillment(of: exp)
        prepareNextExpectedMessage()
      } else {
        // No handler. Send the message immediately.
        serverTransport?.receive(message: message)
      }

    case .serverSendsJrpc(let message):
      if clientRequestsHandler != nil {
        // Wait for the handler to sent the message.
        guard let exp = nextMessageToSent?.exp, nextMessageToSent?.serverMessage != nil else {
          throw TestError.internalError
        }
        try await fulfillment(of: exp)
        prepareNextExpectedMessage()
      } else {
        // No handler. Send the message immediately.
        clientTransport?.receive(message: message)
      }

    case .clientResponding(let requestHandler):
      guard let serverRequestsHandler else {
        throw TestError.internalError
      }
      let exp = expectation(description: "clientResponding completed (event #\(i))")
      expectations.append(exp)
      Task {
        for await (request, completion) in serverRequestsHandler {
          do {
            try await completion(requestHandler(request))
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
          break
        }
      }

    case .serverResponding(let requestHandler):
      guard let clientRequestsHandler else {
        throw TestError.internalError
      }
      let exp = expectation(description: "serverResponding completed (event #\(i))")
      expectations.append(exp)
      Task {
        for await (request, completion) in clientRequestsHandler {
          do {
            try await completion(requestHandler(request))
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
          break
        }
      }

    case .clientReceiving(let notificationHandler):
      guard let serverNotifications else {
        throw TestError.internalError
      }
      let exp = expectation(description: "clientReceiving completed (event #\(i))")
      expectations.append(exp)
      Task {
        for await notification in serverNotifications {
          do {
            try await notificationHandler(notification)
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
          break
        }
      }

    case .serverReceiving(let notificationHandler):
      guard let clientNotifications else {
        throw TestError.internalError
      }
      let exp = expectation(description: "serverReceiving completed (event #\(i))")
      expectations.append(exp)
      Task {
        for await notification in clientNotifications {
          do {
            try await notificationHandler(notification)
          } catch {
            Issue.record(error)
          }
          exp.fulfill()
          break
        }
      }
    }
  }

  // Wait for the task to complete
  try await fulfillment(of: expectations)
  guard let result else {
    throw err ?? TestError.expectationUnfulfilled
  }
  return result
}
