import Foundation
import JSONRPC
import MCPInterface

// MARK: - MCPClientConnection

public actor MCPServerConnection: MCPServerConnectionInterface {

  // MARK: Lifecycle

  public init(
    info: Implementation,
    capabilities: ServerCapabilities,
    transport: Transport)
    throws
  {
    // Note: ideally we would subclass `MCPConnection`. However Swift actors don't support inheritance.
    _connection = try MCPConnection<ClientRequest, ClientNotification>(transport: transport)
    self.info = info
    self.capabilities = capabilities
  }

  // MARK: Public

  public let info: Implementation

  public let capabilities: ServerCapabilities

  public var notifications: AsyncStream<ClientNotification> { _connection.notifications }
  public var requestsToHandle: AsyncStream<HandleClientRequest> { _connection.requestsToHandle }

  public func ping() async throws {
    // TODO: add timeout
    _ = try await jrpcSession.send(PingRequest())
  }

  public func requestCreateMessage(_ params: CreateSamplingMessageRequest.Params) async throws -> CreateSamplingMessageRequest
    .Result
  {
    try await jrpcSession.send(CreateSamplingMessageRequest(params: params))
  }

  public func listRoots() async throws -> ListRootsResult {
    try await jrpcSession.send(ListRootsRequest())
  }

  public func notifyProgress(_ params: ProgressNotification.Params) async throws {
    try await jrpcSession.send(ProgressNotification(params: params))
  }

  public func notifyResourceUpdated(_ params: ResourceUpdatedNotification.Params) async throws {
    try await jrpcSession.send(ResourceUpdatedNotification(params: params))
  }

  public func notifyResourceListChanged(_ params: ResourceListChangedNotification.Params? = nil) async throws {
    try await jrpcSession.send(ResourceListChangedNotification(params: params))
  }

  public func notifyToolListChanged(_ params: ToolListChangedNotification.Params? = nil) async throws {
    try await jrpcSession.send(ToolListChangedNotification(params: params))
  }

  public func notifyPromptListChanged(_ params: PromptListChangedNotification.Params? = nil) async throws {
    try await jrpcSession.send(PromptListChangedNotification(params: params))
  }

  public func notifyCancelled(_ params: CancelledNotification.Params) async throws {
    try await jrpcSession.send(CancelledNotification(params: params))
  }

  public func log(_ params: LoggingMessageNotification.Params) async throws {
    try await jrpcSession.send(LoggingMessageNotification(params: params))
  }

  // MARK: Private

  private let _connection: MCPConnection<ClientRequest, ClientNotification>

  private var jrpcSession: JSONRPCSession {
    _connection.jrpcSession
  }

}
