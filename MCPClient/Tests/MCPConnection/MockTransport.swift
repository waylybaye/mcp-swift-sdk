
import Foundation
import JSONRPC
@testable import MCPClient

final class MockTransport {

  // MARK: Lifecycle

  init() {
    let dataSequence = AsyncStream<Data>() { continuation in
      self.continuation = continuation
    }

    dataChannel = DataChannel(
      writeHandler: { [weak self] data in self?.handleWrite(data: data) },
      dataSequence: dataSequence)
  }

  // MARK: Internal

  private(set) var dataChannel: DataChannel = .noop

  var sendMessage: (Data) -> Void = { _ in }

  func receive(message: String) {
    let data = Data(message.utf8)
    continuation?.yield(data)
  }

  // MARK: Private

  private var continuation: AsyncStream<Data>.Continuation?

  private func handleWrite(data: Data) {
    sendMessage(data)
  }

}
