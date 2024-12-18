
import Foundation
import Testing
@testable import MCPClient

/// Asserts that the received JSON is equal to the expected JSON, allowing for any order of keys or spacing.
func assertEqual(received jsonData: Data, expected: String) {
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

extension MockTransport {

  /// Expects the given messages to be sent.
  /// Examples:
  /// expect([
  ///   "{ \"jsonrpc\": \"2.0\", \"id\": 1, \"result\": null }",
  /// ])
  func expect(messages: [String]) {
    expect(messages: messages.map { m in { $0(m) } })
  }

  /// Expects the given messages to be sent, calling the corresponding closure when needed.
  /// Examples:
  /// expect([
  ///   {
  ///     firstMessageReceived.fulfill()
  ///     return "{ \"jsonrpc\": \"2.0\", \"id\": 1, \"result\": null }"
  ///   },
  /// ])
  func expect(messages: [((String) -> Void) -> Void]) {
    var messagesCount = 0

    sendMessage = { message in
      defer { messagesCount += 1 }
      guard messagesCount < messages.count else {
        Issue.record("""
          Too many messages sent. Expected \(messages.count). Last message received:
          \(String(data: message, encoding: .utf8) ?? "Invalid data")
          """)
        return
      }
      messages[messagesCount]() { expected in
        assertEqual(received: message, expected: expected)
      }
    }
  }
}

// MARK: - TestError

enum TestError: Error {
  case expectationUnfulfilled
  case internalError
}

// MARK: - Message

enum Message {
  case request(_ value: String)
  case response(_ value: String)

  var request: String? {
    if case .request(let value) = self {
      return value
    }
    return nil
  }
}
