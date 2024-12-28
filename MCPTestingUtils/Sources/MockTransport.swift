
import Foundation
import JSONRPC
import MCPInterface
import Testing

// MARK: - MockTransport

public final class MockTransport {

  // MARK: Lifecycle

  public init() {
    let dataSequence = AsyncStream<Data>() { continuation in
      self.continuation = continuation
    }

    dataChannel = DataChannel(
      writeHandler: { [weak self] data in self?.handleWrite(data: data) },
      dataSequence: dataSequence)
  }

  // MARK: Public

  public private(set) var dataChannel: DataChannel = .noop

  public func onSendMessage(_ hook: @escaping (Data) -> Void) {
    let previousSendMessage = sendMessage
    sendMessage = { message in
      previousSendMessage(message)
      hook(message)
    }
  }

  public func receive(message: String) {
    let data = Data(message.utf8)
    continuation?.yield(data)
  }

  // MARK: Private

  private var sendMessage: (Data) -> Void = { _ in }

  private var continuation: AsyncStream<Data>.Continuation?

  private func handleWrite(data: Data) {
    sendMessage(data)
  }

}

extension MockTransport {

  /// Expects the given messages to be sent.
  /// Examples:
  /// expect([
  ///   "{ \"jsonrpc\": \"2.0\", \"id\": 1, \"result\": null }",
  /// ])
  public func expect(messages: [String]) {
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
  public func expect(messages: [((String) -> Void) -> Void]) {
    var messagesCount = 0

    let previousSendMessage = sendMessage

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

      previousSendMessage(message)
    }
  }
}
