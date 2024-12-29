import JSONRPC
import MCPInterface
import MCPServer

// MARK: - MockMCPServerConnection

/// A mock `MCPServerConnection` that can be used in tests.
class MockMCPServerConnection: MCPServerConnectionInterface {

  // MARK: Lifecycle

  required init(
    info: Implementation,
    capabilities: ServerCapabilities,
    transport _: Transport = .noop)
    throws
  {
    self.info = info
    self.capabilities = capabilities

    var sendNotificationToStream: (ClientNotification) -> Void = { _ in }
    notifications = AsyncStream<ClientNotification>() { continuation in
      sendNotificationToStream = { continuation.yield($0) }
    }
    self.sendNotificationToStream = sendNotificationToStream

    var sendRequestToStream: (HandleClientRequest) -> Void = { _ in }
    requestsToHandle = AsyncStream<HandleClientRequest>() { continuation in
      sendRequestToStream = { continuation.yield($0) }
    }
    self.sendRequestToStream = sendRequestToStream
  }

  // MARK: Internal

  /// Send a client notification.
  private(set) var sendNotificationToStream: ((ClientNotification) -> Void) = { _ in }
  /// Send a client request to the handler.
  private(set) var sendRequestToStream: ((HandleClientRequest) -> Void) = { _ in }

  let info: Implementation
  let capabilities: ServerCapabilities

  var notifications: AsyncStream<ClientNotification>
  var requestsToHandle: AsyncStream<HandleClientRequest>

  /// This function is called when `ping` is called
  var pingStub: (() async throws -> Void)?

  /// This function is called when `requestCreateMessage` is called
  var requestCreateMessageStub: ((CreateSamplingMessageRequest.Params) async throws -> CreateSamplingMessageRequest.Result)?

  /// This function is called when `listRoots` is called
  var listRootsStub: (() async throws -> ListRootsResult)?

  /// This function is called when `notifyProgress` is called
  var notifyProgressStub: ((ProgressNotification.Params) async throws -> Void)?

  /// This function is called when `notifyResourceUpdated` is called
  var notifyResourceUpdatedStub: ((ResourceUpdatedNotification.Params) async throws -> Void)?

  /// This function is called when `notifyResourceListChanged` is called
  var notifyResourceListChangedStub: ((ResourceListChangedNotification.Params?) async throws -> Void)?

  /// This function is called when `notifyToolListChanged` is called
  var notifyToolListChangedStub: ((ToolListChangedNotification.Params?) async throws -> Void)?

  /// This function is called when `notifyPromptListChanged` is called
  var notifyPromptListChangedStub: ((PromptListChangedNotification.Params?) async throws -> Void)?

  /// This function is called when `log` is called
  var logStub: ((LoggingMessageNotification.Params) async throws -> Void)?

  /// This function is called when `notifyCancelled` is called
  var notifyCancelledStub: ((CancelledNotification.Params) async throws -> Void)?

  func ping() async throws {
    if let pingStub {
      return try await pingStub()
    }
    throw MockMCPServerConnectionError.notImplemented(function: "ping")
  }

  func requestCreateMessage(_ params: CreateSamplingMessageRequest.Params) async throws -> CreateSamplingMessageRequest.Result {
    if let requestCreateMessageStub {
      return try await requestCreateMessageStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "requestCreateMessage")
  }

  func listRoots() async throws -> ListRootsResult {
    if let listRootsStub {
      return try await listRootsStub()
    }
    throw MockMCPServerConnectionError.notImplemented(function: "listRoots")
  }

  func notifyProgress(_ params: ProgressNotification.Params) async throws {
    if let notifyProgressStub {
      return try await notifyProgressStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyProgress")
  }

  func notifyResourceUpdated(_ params: ResourceUpdatedNotification.Params) async throws {
    if let notifyResourceUpdatedStub {
      return try await notifyResourceUpdatedStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyResourceUpdated")
  }

  func notifyResourceListChanged(_ params: ResourceListChangedNotification.Params?) async throws {
    if let notifyResourceListChangedStub {
      return try await notifyResourceListChangedStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyResourceListChanged")
  }

  func notifyToolListChanged(_ params: ToolListChangedNotification.Params?) async throws {
    if let notifyToolListChangedStub {
      return try await notifyToolListChangedStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyToolListChanged")
  }

  func notifyPromptListChanged(_ params: PromptListChangedNotification.Params?) async throws {
    if let notifyPromptListChangedStub {
      return try await notifyPromptListChangedStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyPromptListChanged")
  }

  func log(_ params: LoggingMessageNotification.Params) async throws {
    if let logStub {
      return try await logStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "log")
  }

  func notifyCancelled(_ params: CancelledNotification.Params) async throws {
    if let notifyCancelledStub {
      return try await notifyCancelledStub(params)
    }
    throw MockMCPServerConnectionError.notImplemented(function: "notifyCancelled")
  }
}

// MARK: - MockMCPServerConnectionError

enum MockMCPServerConnectionError: Error {
  case notImplemented(function: String)
}
