import JSONRPC
import MCPInterface

// MARK: - MCPServerConnectionInterface

/// The MCP JRPC Bridge is a stateless interface to the MCP server that provides a higher level Swift interface.
/// It does not implement any of the stateful behaviors of the MCP client, such as handling subscriptions, detecting connection health,
/// ensuring that the connection has been initialized before being used etc.
///
/// For most use cases, `MCPServer` should be a preferred interface.
public protocol MCPServerConnectionInterface {
  /// The notifications received by the client.
  var notifications: AsyncStream<ClientNotification> { get async }
  /// The requests received by the client that need to be responded to.
  var requestsToHandle: AsyncStream<HandleClientRequest> { get async }

  /// Creates a new MCP JRPC Bridge.
  /// This will create a new connection with the transport corresponding to the MCP client, but it will not handle the initialization request as specified by the MCP protocol.
  /// The connection will be closed when this object is de-initialized.
  init(
    info: Implementation,
    capabilities: ServerCapabilities,
    transport: Transport) throws

  /// Send a ping to the client
  func ping() async throws

  /// Request the client to create a message (LLM sampling)
  func requestCreateMessage(_ params: CreateSamplingMessageRequest.Params) async throws -> CreateSamplingMessageRequest.Result

  /// Request the list of roots from the client
  func listRoots() async throws -> ListRootsResult

  /// Send a progress notification to the client
  func notifyProgress(_ params: ProgressNotification.Params) async throws

  /// Send a resource updated notification to the client
  func notifyResourceUpdated(_ params: ResourceUpdatedNotification.Params) async throws

  /// Send a resource list changed notification to the client
  func notifyResourceListChanged(_ params: ResourceListChangedNotification.Params?) async throws

  /// Send a tool list changed notification to the client
  func notifyToolListChanged(_ params: ToolListChangedNotification.Params?) async throws

  /// Send a prompt list changed notification to the client
  func notifyPromptListChanged(_ params: PromptListChangedNotification.Params?) async throws

  /// Send a logging message to the client
  func log(_ params: LoggingMessageNotification.Params) async throws

  /// Send a cancellation notification to the client
  func notifyCancelled(_ params: CancelledNotification.Params) async throws
}
