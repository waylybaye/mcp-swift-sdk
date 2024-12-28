import Foundation
import JSONRPC
import MCPInterface
import MemberwiseInit

// MARK: - MCPClientConnection

public actor MCPClientConnection: MCPClientConnectionInterface {

  // MARK: Lifecycle

  public init(
    info: Implementation,
    capabilities: ClientCapabilities,
    transport: Transport)
    throws
  {
    // Note: ideally we would subclass `MCPConnection`. However Swift actors don't support inheritance.
    _connection = try MCPConnection<ServerRequest, ServerNotification>(transport: transport)
    self.info = info
    self.capabilities = capabilities
  }

  // MARK: Public

  public let info: Implementation

  public let capabilities: ClientCapabilities

  public var notifications: AsyncStream<ServerNotification> { _connection.notifications }
  public var requestsToHandle: AsyncStream<HandleServerRequest> { _connection.requestsToHandle }

  public func initialize() async throws -> InitializeRequest.Result {
    let params = InitializeRequest.Params(
      protocolVersion: MCP.protocolVersion,
      capabilities: capabilities,
      clientInfo: info)

    // TODO: move this to other layer
    let initializationResponse = try await jrpcSession.send(InitializeRequest(params: params))
    assert(initializationResponse.protocolVersion == MCP.protocolVersion, "Server and client protocol version mismatch")
    return initializationResponse
  }

  public func acknowledgeInitialization() async throws {
    try await jrpcSession.send(InitializedNotification())
  }

  public func ping() async throws {
    // TODO: add timeout
    _ = try await jrpcSession.send(PingRequest())
  }

  public func listPrompts() async throws -> [Prompt] {
    try await jrpcSession.send(nil, getResults: { $0.prompts }, req: ListPromptsRequest.self)
  }

  public func getPrompt(_ params: GetPromptRequest.Params) async throws -> GetPromptRequest.Result {
    try await jrpcSession.send(GetPromptRequest(params: params))
  }

  public func listResources() async throws -> [Resource] {
    try await jrpcSession.send(nil, getResults: { $0.resources }, req: ListResourcesRequest.self)
  }

  public func readResource(_ params: ReadResourceRequest.Params) async throws -> ReadResourceRequest.Result {
    try await jrpcSession.send(ReadResourceRequest(params: params))
  }

  public func subscribeToUpdateToResource(_ params: SubscribeRequest.Params) async throws {
    _ = try await jrpcSession.send(SubscribeRequest(params: params))
  }

  public func unsubscribeToUpdateToResource(_ params: UnsubscribeRequest.Params) async throws {
    _ = try await jrpcSession.send(UnsubscribeRequest(params: params))
  }

  public func listResourceTemplates() async throws -> [ResourceTemplate] {
    try await jrpcSession.send(
      nil,
      getResults: { $0.resourceTemplates },
      req: ListResourceTemplatesRequest.self)
  }

  public func listTools() async throws -> [Tool] {
    try await jrpcSession.send(nil, getResults: { $0.tools }, req: ListToolsRequest.self)
  }

  public func call(
    toolName: String,
    arguments: JSON? = nil,
    progressToken: ProgressToken? = nil)
    async throws -> CallToolRequest.Result
  {
    let _meta = progressToken.map { CallToolRequest.Params.Meta(progressToken: $0) }
    return try await jrpcSession.send(CallToolRequest(params: .init(_meta: _meta, name: toolName, arguments: arguments)))
  }

  public func requestCompletion(_ params: CompleteRequest.Params) async throws -> CompleteRequest.Result {
    try await jrpcSession.send(CompleteRequest(params: params))
  }

  public func setLogLevel(_ params: SetLevelRequest.Params) async throws -> SetLevelRequest.Result {
    try await jrpcSession.send(SetLevelRequest(params: params))
  }

  public func notifyRootsListChanged() async throws {
    try await jrpcSession.send(RootsListChangedNotification())
  }

  // MARK: Private

  private let _connection: MCPConnection<ServerRequest, ServerNotification>

  private var jrpcSession: JSONRPCSession {
    _connection.jrpcSession
  }
}
