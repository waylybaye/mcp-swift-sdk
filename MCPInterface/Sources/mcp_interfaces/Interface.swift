// Schema from the MCP protocol.
// This file should map to https://github.com/modelcontextprotocol/specification/blob/main/schema/schema.ts

/// A progress token, used to associate progress notifications with the original request.
public typealias ProgressToken = StringOrNumber

/// An opaque token used to represent a cursor for pagination.
public typealias Cursor = String

// MARK: - MetaType

public protocol MetaType { }

// MARK: - HasMetaValue

public protocol HasMetaValue {
  associatedtype Meta: MetaType
  var _meta: Meta? { get }
}

// MARK: - Optional + HasMetaValue

extension Optional: HasMetaValue where Wrapped: HasMetaValue {
  public var _meta: Wrapped.Meta? { self?._meta }
}

// MARK: - MetaProgress

public struct MetaProgress: MetaType, Codable, Equatable {
  /// If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress). The value of this parameter is an opaque token that will be attached to any subsequent notifications. The receiver is not obligated to provide these notifications.
  public let progressToken: ProgressToken

  public init(progressToken: ProgressToken) {
    self.progressToken = progressToken
  }
}

// MARK: - AnyMeta

/// A payload that contains meta information without a specific schema.
public struct AnyMeta: MetaType, Codable, Equatable, Sendable {
  /// Note: the value key is not represented in the serialization. Instead this types is serialized like `JSON`.
  public let value: JSON
  public init(value: JSON) {
    self.value = value
  }
}

// MARK: - AnyParams

public struct AnyParams: HasMetaValue, Equatable, Codable {
  public let _meta: AnyMeta?
  public let value: [String: JSON.Value]?
  public init(_meta: AnyMeta? = nil, value: [String: JSON.Value]? = nil) {
    self._meta = _meta
    self.value = value
  }
}

// MARK: - AnyParamsWithProgressToken

public struct AnyParamsWithProgressToken: HasMetaValue, Codable, Equatable {
  public let _meta: MetaProgress?
  public let value: [String: JSON.Value]?
  public init(_meta: MetaProgress? = nil, value: [String: JSON.Value]? = nil) {
    self._meta = _meta
    self.value = value
  }
}

// MARK: - Request

/// The _meta parameter is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
public protocol Request: Codable where Params.Meta == MetaProgress {
  associatedtype Params: Codable & HasMetaValue
  associatedtype Result: Codable
  var method: String { get }
  var params: Params { get }

  typealias Handler = (Params) async throws -> Result
}

// MARK: - Notification

public protocol Notification: Codable, Equatable where Params.Meta == AnyMeta {

  associatedtype Params: Codable & HasMetaValue
  var method: String { get }
  /// The _meta parameter in `params` is reserved by MCP to allow clients and servers to attach additional metadata to their notifications.
  var params: Params? { get }
}

// MARK: - HasParams

/// This little boilerplate helps make Swift happy when a type fulfills with `params: Params` a protocol that requires `params: Params?`...
public protocol HasParams {
  associatedtype Params: Codable & HasMetaValue
  var params: Params { get }
}

extension HasParams {
  var _params: Params { params }
}

extension Request where Self: HasParams {
  public var params: Params? { _params }
}

extension Notification where Self: HasParams {
  public var params: Params? { _params }
}

// MARK: - Result

/// The _meta property is reserved by the protocol to allow clients and servers to attach additional metadata to their responses.
public protocol Result: Codable, HasMetaValue where Meta == AnyMeta { }

public typealias RequestId = StringOrNumber

// MARK: - JRPCErrorCodes

public enum JRPCErrorCodes: Int {
  case parseError = -32700
  case invalidRequest = -32600
  case methodNotFound = -32601
  case invalidParams = -32602
  case internalError = -32603
}

// MARK: - JRPCError

public struct JRPCError: Error {
  /// The error type that occurred.
  public let code: Int
  /// A short description of the error. The message SHOULD be limited to a concise single sentence.
  public let message: String
  /// Additional information about the error. The value of this member is defined by the sender (e.g. detailed error information, nested errors etc.).
  public let data: JSON.Value?
  public init(code: Int, message: String, data: JSON.Value? = nil) {
    self.code = code
    self.message = message
    self.data = data
  }
}

// MARK: - CancelledNotification

public struct CancelledNotification: Notification, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: AnyMeta?
    /// The ID of the request to cancel.
    /// This MUST correspond to the ID of a request previously issued in the same direction.
    public let requestId: RequestId
    /// An optional string describing the reason for the cancellation. This MAY be logged or presented to the user.
    public let reason: String?

    public init(_meta: AnyMeta? = nil, requestId: RequestId, reason: String? = nil) {
      self._meta = _meta
      self.requestId = requestId
      self.reason = reason
    }
  }

  public let method = Notifications.cancelled
  public let params: Params

}

// MARK: - InitializeRequest

/// This request is sent from the client to the server when it first connects, asking it to begin initialization.
public struct InitializeRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = InitializeResult
  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The latest version of the Model Context Protocol that the client supports. The client MAY decide to support older versions as well.
    public let protocolVersion: String
    public let capabilities: ClientCapabilities
    public let clientInfo: Implementation

    public init(
      _meta: MetaProgress? = nil,
      protocolVersion: String,
      capabilities: ClientCapabilities,
      clientInfo: Implementation)
    {
      self._meta = _meta
      self.protocolVersion = protocolVersion
      self.capabilities = capabilities
      self.clientInfo = clientInfo
    }
  }

  public let method = Requests.initialize
  public let params: Params

}

// MARK: - InitializeResult

/// After receiving an initialize request from the client, the server sends this response.
public struct InitializeResult: Result {
  public init(
    _meta: AnyMeta? = nil,
    protocolVersion: String,
    capabilities: ServerCapabilities,
    serverInfo: Implementation,
    instructions: String? = nil)
  {
    self._meta = _meta
    self.protocolVersion = protocolVersion
    self.capabilities = capabilities
    self.serverInfo = serverInfo
    self.instructions = instructions
  }

  public let _meta: AnyMeta?
  /// The version of the Model Context Protocol that the server wants to use. This may not match the version that the client requested. If the client cannot support this version, it MUST disconnect.
  public let protocolVersion: String
  public let capabilities: ServerCapabilities
  public let serverInfo: Implementation
  /// Instructions describing how to use the server and its features.
  /// This can be used by clients to improve the LLM's understanding of available tools, resources, etc. It can be thought of like a "hint" to the model. For example, this information MAY be added to the system prompt.
  public let instructions: String?

}

// MARK: - InitializedNotification

/// This notification is sent from the client to the server after initialization has finished.
public struct InitializedNotification: Notification {
  public let method = Notifications.initialized
  public let params: AnyParams?
  public init(params: AnyParams? = nil) {
    self.params = params
  }
}

// MARK: - CapabilityInfo

public struct CapabilityInfo: Codable, Equatable {
  /// Whether this client/server supports subscribing to updates about the capability.
  public let subscribe: Bool?
  /// Whether this client/server supports notifications for changes to the capability.
  public let listChanged: Bool?

  public init(subscribe: Bool? = nil, listChanged: Bool? = nil) {
    self.subscribe = subscribe
    self.listChanged = listChanged
  }
}

// MARK: - ListChangedCapability

public struct ListChangedCapability: Codable, Equatable {
  /// Whether this client/server supports notifications for changes to the capability.
  public let listChanged: Bool?
  public init(listChanged: Bool? = nil) {
    self.listChanged = listChanged
  }
}

// MARK: - ClientCapabilities

/// Capabilities a client may support. Known capabilities are defined here, in this schema, but this is not a closed set: any client can define its own, additional capabilities.
public struct ClientCapabilities: Codable, Equatable {
  /// Experimental, non-standard capabilities that the client supports.
  public let experimental: JSON?
  /// Present if the client supports listing roots.
  public let roots: ListChangedCapability?
  /// Present if the client supports sampling from an LLM.
  public let sampling: EmptyObject?

  public init(experimental: JSON? = nil, roots: ListChangedCapability? = nil, sampling: EmptyObject? = nil) {
    self.experimental = experimental
    self.roots = roots
    self.sampling = sampling
  }
}

// MARK: - ServerCapabilities

/// Capabilities that a server may support. Known capabilities are defined here, in this schema, but this is not a closed set: any server can define its own, additional capabilities.
public struct ServerCapabilities: Codable, Equatable {

  public init(
    experimental: JSON? = nil,
    logging: EmptyObject? = nil,
    prompts: ListChangedCapability? = nil,
    resources: CapabilityInfo? = nil,
    tools: ListChangedCapability? = nil)
  {
    self.experimental = experimental
    self.logging = logging
    self.prompts = prompts
    self.resources = resources
    self.tools = tools
  }

  /// Experimental, non-standard capabilities that the server supports
  public let experimental: JSON?
  /// Present if the server supports sending log messages to the client.
  public let logging: EmptyObject?
  /// Present if the server offers any prompt templates.
  public let prompts: ListChangedCapability?
  /// Present if the server offers any resources to read.
  public let resources: CapabilityInfo?
  /// Present if the server offers any tools to call.
  public let tools: ListChangedCapability?

}

// MARK: - Implementation

/// Describes the name and version of an MCP implementation.
public struct Implementation: Codable, Equatable {
  public let name: String
  public let version: String

  public init(name: String, version: String) {
    self.name = name
    self.version = version
  }
}

// MARK: - PingRequest

/// A ping, issued by either the server or the client, to check that the other party is still alive. The receiver must promptly respond, or else may be disconnected.
public struct PingRequest: Request, Codable {
  public typealias Result = EmptyResult
  public let method = Requests.ping
  public let params: AnyParamsWithProgressToken?

  public init(params: AnyParamsWithProgressToken? = nil) {
    self.params = params
  }
}

// MARK: - EmptyResult

public struct EmptyResult: Result, Codable, Sendable {
  public let _meta: AnyMeta?

  public init(_meta: AnyMeta? = nil) {
    self._meta = _meta
  }
}

// MARK: - ProgressNotification

/// An out-of-band notification used to inform the receiver of a progress update for a long-running request.
public struct ProgressNotification: Notification, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: AnyMeta?
    /// The progress token which was given in the initial request, used to associate this notification with the request that is proceeding.
    public let progressToken: ProgressToken
    /// The progress thus far. This should increase every time progress is made, even if the total is unknown.
    public let progress: Double
    /// Total number of items to process (or total progress required), if known.
    public let total: Double?

    public init(_meta: AnyMeta? = nil, progressToken: ProgressToken, progress: Double, total: Double? = nil) {
      self._meta = _meta
      self.progressToken = progressToken
      self.progress = progress
      self.total = total
    }
  }

  public let method = Notifications.progress
  public let params: Params
}

// MARK: - PaginationParams

public protocol PaginationParams {
  /// An opaque token representing the current pagination position.
  /// If provided, the server should return results starting after this cursor.
  var cursor: Cursor? { get }

  static func updating(cursor: Cursor?, from params: Self?) -> Self
}

// MARK: - Optional + PaginationParams

extension Optional: PaginationParams where Wrapped: PaginationParams {
  public var cursor: Cursor? { self?.cursor }

  public static func updating(cursor: Cursor? = nil, from params: Self? = nil) -> Self {
    Wrapped.updating(cursor: cursor, from: params ?? nil)
  }
}

// MARK: - SharedPaginationParams

/// Note: while we could merge this with `PaginationParams` and remove the need for the extra protocol
/// since all paginated requests currently use the same parameter, it felt better to have those two types
/// to make it easier to evolve the code if the protocol evolves in the future.
public struct SharedPaginationParams: PaginationParams, HasMetaValue, Codable, Equatable {
  public static func updating(cursor: Cursor? = nil, from params: SharedPaginationParams? = nil) -> SharedPaginationParams {
    .init(_meta: params?._meta, cursor: cursor)
  }

  public let _meta: MetaProgress?
  public let cursor: Cursor?

  public init(_meta: MetaProgress? = nil, cursor: Cursor? = nil) {
    self._meta = _meta
    self.cursor = cursor
  }
}

// MARK: - PaginatedRequest

public protocol PaginatedRequest: Request where Result: PaginatedResult, Params: PaginationParams {
  var params: Params { get }
  init(params: Params)
}

// MARK: - PaginatedResult

public protocol PaginatedResult: Result {
  var nextCursor: Cursor? { get }
}

// MARK: - ListResourcesRequest

/// Sent from the client to request a list of resources the server has.
public struct ListResourcesRequest: PaginatedRequest {
  public typealias Result = ListResourcesResult

  public let method = Requests.listResources
  public let params: SharedPaginationParams?

  public init(params: SharedPaginationParams? = nil) {
    self.params = params
  }
}

// MARK: - ListResourcesResult

/// The server's response to a resources/list request from the client.
public struct ListResourcesResult: PaginatedResult {
  public let _meta: AnyMeta?
  public let nextCursor: Cursor?
  public let resources: [Resource]

  public init(_meta: AnyMeta? = nil, nextCursor: Cursor? = nil, resources: [Resource]) {
    self._meta = _meta
    self.nextCursor = nextCursor
    self.resources = resources
  }
}

// MARK: - ListResourceTemplatesRequest

/// Sent from the client to request a list of resource templates the server has.
public struct ListResourceTemplatesRequest: PaginatedRequest {
  public init(params: SharedPaginationParams? = nil) {
    self.params = params
  }

  public typealias Result = ListResourceTemplatesResult

  public let method = Requests.listResourceTemplates
  public let params: SharedPaginationParams?
}

// MARK: - ListResourceTemplatesResult

/// The server's response to a resources/templates/list request from the client.
public struct ListResourceTemplatesResult: PaginatedResult {
  public let _meta: AnyMeta?
  public let nextCursor: Cursor?
  public let resourceTemplates: [ResourceTemplate]

  public init(_meta: AnyMeta? = nil, nextCursor: Cursor? = nil, resourceTemplates: [ResourceTemplate]) {
    self._meta = _meta
    self.nextCursor = nextCursor
    self.resourceTemplates = resourceTemplates
  }
}

// MARK: - ReadResourceRequest

/// Sent from the client to the server, to read a specific resource URI.
public struct ReadResourceRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = ReadResourceResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The URI of the resource to read. The URI can use any protocol; it is up to the server how to interpret it.
    /// @format uri
    public let uri: String

    public init(_meta: MetaProgress? = nil, uri: String) {
      self._meta = _meta
      self.uri = uri
    }
  }

  public let method = Requests.readResource
  public let params: Params

}

// MARK: - ReadResourceResult

/// The server's response to a resources/read request from the client.
public struct ReadResourceResult: Result {
  public let _meta: AnyMeta?
  public let contents: [TextOrBlobResourceContents]

  public init(_meta: AnyMeta? = nil, contents: [TextOrBlobResourceContents]) {
    self._meta = _meta
    self.contents = contents
  }
}

// MARK: - ResourceListChangedNotification

/// An optional notification from the server to the client, informing it that the list of resources it can read from has changed. This may be issued by servers without any previous subscription from the client.
public struct ResourceListChangedNotification: Notification {

  public let method = Notifications.resourceListChanged
  public let params: AnyParams?

  public init(params: AnyParams? = nil) {
    self.params = params
  }
}

// MARK: - SubscribeRequest

/// Sent from the client to request resources/updated notifications from the server whenever a particular resource changes.
public struct SubscribeRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = EmptyResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The URI of the resource to subscribe to. The URI can use any protocol; it is up to the server how to interpret it.
    /// @format uri
    public let uri: String

    public init(_meta: MetaProgress? = nil, uri: String) {
      self._meta = _meta
      self.uri = uri
    }
  }

  public let method = Requests.subscribeToResource
  public let params: Params

}

// MARK: - UnsubscribeRequest

/// Sent from the client to request cancellation of resources/updated notifications from the server. This should follow a previous resources/subscribe request.
public struct UnsubscribeRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = EmptyResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The URI of the resource to unsubscribe from.
    /// @format uri
    public let uri: String

    public init(_meta: MetaProgress? = nil, uri: String) {
      self._meta = _meta
      self.uri = uri
    }
  }

  public let method = Requests.unsubscribeToResource
  public let params: Params

}

// MARK: - ResourceUpdatedNotification

/// A notification from the server to the client, informing it that a resource has changed and may need to be read again. This should only be sent if the client previously sent a resources/subscribe request.
public struct ResourceUpdatedNotification: Notification, HasParams {

  public let method = Notifications.resourceUpdated
  public let params: Params

  public init(params: Params) {
    self.params = params
  }

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: AnyMeta?
    /// The URI of the resource that has been updated. This might be a sub-resource of the one that the client actually subscribed to.
    /// @format uri
    public let uri: String

    public init(_meta: AnyMeta? = nil, uri: String) {
      self._meta = _meta
      self.uri = uri
    }
  }
}

// MARK: - Resource

/// A known resource that the server is capable of reading.
public struct Resource: Annotated, Codable, Equatable {
  public init(annotations: Annotations? = nil, uri: String, name: String, description: String? = nil, mimeType: String? = nil) {
    self.annotations = annotations
    self.uri = uri
    self.name = name
    self.description = description
    self.mimeType = mimeType
  }

  public let annotations: Annotations?
  /// The URI of this resource.
  /// @format uri
  public let uri: String
  /// A human-readable name for this resource.
  /// This can be used by clients to populate UI elements.
  public let name: String
  /// A description of what this resource represents.
  /// This can be used by clients to improve the LLM's understanding of available resources. It can be thought of like a "hint" to the model.
  public let description: String?
  /// The MIME type of this resource, if known.
  public let mimeType: String?

}

// MARK: - ResourceTemplate

/// A template description for resources available on the server.
public struct ResourceTemplate: Annotated, Codable, Equatable {
  public init(
    annotations: Annotations? = nil,
    uriTemplate: String,
    name: String,
    description: String? = nil,
    mimeType: String? = nil)
  {
    self.annotations = annotations
    self.uriTemplate = uriTemplate
    self.name = name
    self.description = description
    self.mimeType = mimeType
  }

  public let annotations: Annotations?
  /// A URI template (according to RFC 6570) that can be used to construct resource URIs.
  /// @format uri
  public let uriTemplate: String
  /// A human-readable name for the type of resource this template refers to.
  /// This can be used by clients to populate UI elements.
  public let name: String
  /// A description of what this template is for.
  /// This can be used by clients to improve the LLM's understanding of available resources. It can be thought of like a "hint" to the model.
  public let description: String?
  /// The MIME type for all resources that match this template. This should only be included if all resources matching this template have the same type.
  public let mimeType: String?

}

// MARK: - ResourceContents

/// The contents of a specific resource or sub-resource.
public protocol ResourceContents {
  /// The URI of this resource.
  /// @format uri
  var uri: String { get }
  /// The MIME type of this resource, if known.
  var mimeType: String? { get }
}

// MARK: - TextResourceContents

public struct TextResourceContents: Codable, Equatable, ResourceContents {
  /// The URI of this resource.
  public let uri: String
  /// The MIME type of this resource, if known.
  public let mimeType: String?
  /// The text of the item. This must only be set if the item can actually be represented as text (not binary data).
  public let text: String

  public init(uri: String, mimeType: String? = nil, text: String) {
    self.uri = uri
    self.mimeType = mimeType
    self.text = text
  }
}

// MARK: - BlobResourceContents

public struct BlobResourceContents: Codable, Equatable, ResourceContents {
  /// The URI of this resource.
  public let uri: String
  /// The MIME type of this resource, if known.
  public let mimeType: String?
  /// A base64-encoded string representing the binary data of the item.
  /// @format byte
  public let blob: String

  public init(uri: String, mimeType: String? = nil, blob: String) {
    self.uri = uri
    self.mimeType = mimeType
    self.blob = blob
  }
}

// MARK: - ListPromptsRequest

/// Sent from the client to request a list of prompts and prompt templates the server has.
public struct ListPromptsRequest: PaginatedRequest {

  public typealias Result = ListPromptsResult

  public let method = Requests.listPrompts
  public let params: SharedPaginationParams?

  public init(params: SharedPaginationParams? = nil) {
    self.params = params
  }
}

// MARK: - ListPromptsResult

/// The server's response to a prompts/list request from the client.
public struct ListPromptsResult: PaginatedResult {
  public let _meta: AnyMeta?
  public let nextCursor: Cursor?
  public let prompts: [Prompt]

  public init(_meta: AnyMeta? = nil, nextCursor: Cursor? = nil, prompts: [Prompt]) {
    self._meta = _meta
    self.nextCursor = nextCursor
    self.prompts = prompts
  }
}

// MARK: - GetPromptRequest

/// Used by the client to get a prompt provided by the server.
public struct GetPromptRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = GetPromptResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The name of the prompt or prompt template.
    public let name: String
    /// Arguments to use for templating the prompt.
    public let arguments: JSON?

    public init(_meta: MetaProgress? = nil, name: String, arguments: JSON? = nil) {
      self._meta = _meta
      self.name = name
      self.arguments = arguments
    }
  }

  public let method = Requests.getPrompt
  public let params: Params

}

// MARK: - GetPromptResult

/// The server's response to a prompts/get request from the client.
public struct GetPromptResult: Result {
  public let _meta: AnyMeta?
  /// An optional description for the prompt.
  public let description: String?
  public let messages: [PromptMessage]

  public init(_meta: AnyMeta? = nil, description: String? = nil, messages: [PromptMessage]) {
    self._meta = _meta
    self.description = description
    self.messages = messages
  }
}

// MARK: - Prompt

/// A prompt or prompt template that the server offers.
public struct Prompt: Codable, Equatable {
  /// The name of the prompt or prompt template.
  public let name: String
  /// An optional description of what this prompt provides
  public let description: String?
  /// A list of arguments to use for templating the prompt.
  public let arguments: [PromptArgument]

  public init(name: String, description: String? = nil, arguments: [PromptArgument]) {
    self.name = name
    self.description = description
    self.arguments = arguments
  }
}

// MARK: - PromptArgument

/// Describes an argument that a prompt can accept.
public struct PromptArgument: Codable, Equatable {
  /// The name of the argument.
  public let name: String
  /// A human-readable description of the argument.
  public let description: String?
  ///  Whether this argument must be provided.
  public let required: Bool?

  public init(name: String, description: String? = nil, required: Bool? = nil) {
    self.name = name
    self.description = description
    self.required = required
  }
}

// MARK: - Role

/// The sender or recipient of messages and data in a conversation.
public enum Role: String, Codable {
  case user
  case assistant
}

// MARK: - PromptMessage

/// Describes a message returned as part of a prompt.
///
/// This is similar to `SamplingMessage`, but also supports the embedding of
/// resources from the MCP server.
public struct PromptMessage: Codable {
  public let role: Role
  public let content: TextContentOrImageContentOrEmbeddedResource

  public init(role: Role, content: TextContentOrImageContentOrEmbeddedResource) {
    self.role = role
    self.content = content
  }
}

// MARK: - EmbeddedResource

/// The contents of a resource, embedded into a prompt or tool call result.
///
/// It is up to the client how best to render embedded resources for the benefit
/// of the LLM and/or the user.
public struct EmbeddedResource: Annotated, Codable, Equatable {
  public let annotations: Annotations?
  public let type = ResourceTypes.resource
  public let resource: TextOrBlobResourceContents

  public init(annotations: Annotations? = nil, resource: TextOrBlobResourceContents) {
    self.annotations = annotations
    self.resource = resource
  }
}

// MARK: - PromptListChangedNotification

/// An optional notification from the server to the client, informing it that the list of prompts it offers has changed. This may be issued by servers without any previous subscription from the client.
public struct PromptListChangedNotification: Notification {

  public let method = Notifications.promptListChanged
  public let params: AnyParams?

  public init(params: AnyParams? = nil) {
    self.params = params
  }
}

// MARK: - ListToolsRequest

/// Sent from the client to request a list of tools the server has.
public struct ListToolsRequest: PaginatedRequest {
  public init(params: SharedPaginationParams? = nil) {
    self.params = params
  }

  public typealias Result = ListToolsResult

  public let method = Requests.listTools
  public let params: SharedPaginationParams?
}

// MARK: - ListToolsResult

/// The server's response to a tools/list request from the client.
public struct ListToolsResult: PaginatedResult {
  public let _meta: AnyMeta?
  public let nextCursor: Cursor?
  public let tools: [Tool]

  public init(_meta: AnyMeta? = nil, nextCursor: Cursor? = nil, tools: [Tool]) {
    self._meta = _meta
    self.nextCursor = nextCursor
    self.tools = tools
  }
}

// MARK: - CallToolResult

/// The server's response to a tool call.
///
/// Any errors that originate from the tool SHOULD be reported inside the result
/// object, with `isError` set to true, _not_ as an MCP protocol-level error
/// response. Otherwise, the LLM would not be able to see that an error occurred
/// and self-correct.
///
/// However, any errors in _finding_ the tool, an error indicating that the
/// server does not support tool calls, or any other exceptional conditions,
/// should be reported as an MCP error response.
public struct CallToolResult: Result {
  public init(_meta: AnyMeta? = nil, content: [TextContentOrImageContentOrEmbeddedResource], isError: Bool? = nil) {
    self._meta = _meta
    self.content = content
    self.isError = isError
  }

  /// An error that occurred during the execution of the tool.
  public struct ExecutionError: Error, Codable {
    public let text: String

    public init(text: String) {
      self.text = text
    }
  }

  public let _meta: AnyMeta?
  public let content: [TextContentOrImageContentOrEmbeddedResource]
  /// Whether the tool call ended in an error.
  /// If not set, this is assumed to be false (the call was successful).
  public let isError: Bool?

}

// MARK: - CallToolRequest

/// Used by the client to invoke a tool provided by the server.
public struct CallToolRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = CallToolResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    public let name: String
    public let arguments: JSON?

    public init(_meta: MetaProgress? = nil, name: String, arguments: JSON? = nil) {
      self._meta = _meta
      self.name = name
      self.arguments = arguments
    }
  }

  public let method = Requests.callTool
  public let params: Params

}

// MARK: - ToolListChangedNotification

/// An optional notification from the server to the client, informing it that the list of tools it offers has changed. This may be issued by servers without any previous subscription from the client.
public struct ToolListChangedNotification: Notification {

  public let method = Notifications.toolListChanged
  public let params: AnyParams?

  public init(params: AnyParams? = nil) {
    self.params = params
  }
}

// MARK: - Tool

// TODO: add the ability to cast this to a Tool<Input> while validating the schema
/// Definition for a tool the client can call.
public struct Tool: Codable, Equatable {
  /// The name of the tool.
  public let name: String
  /// A human-readable description of the tool.
  public let description: String?
  // TODO: Use a more specific type to represent the JSON schema type?
  /// A JSON Schema object defining the expected parameters for the tool.
  public let inputSchema: JSON

  public init(name: String, description: String? = nil, inputSchema: JSON) {
    self.name = name
    self.description = description
    self.inputSchema = inputSchema
  }
}

// MARK: - SetLevelRequest

/// A request from the client to the server, to enable or adjust logging.
public struct SetLevelRequest: Request, HasParams {
  public typealias Result = EmptyResult

  public let method = Requests.setLoggingLevel
  public let params: Params

  public init(params: Params) {
    self.params = params
  }

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: MetaProgress?
    /// The level of logging that the client wants to receive from the server. The server should send all logs at this level and higher (i.e., more severe) to the client as notifications/logging/message.
    public let level: LoggingLevel

    public init(_meta: MetaProgress? = nil, level: LoggingLevel) {
      self._meta = _meta
      self.level = level
    }
  }
}

// MARK: - LoggingMessageNotification

/// Notification of a log message passed from server to client. If no logging/setLevel request has been sent from the client, the server MAY decide which messages to send automatically.
public struct LoggingMessageNotification: Notification, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public struct Params: HasMetaValue, Codable, Equatable {
    public let _meta: AnyMeta?
    /// The severity of this log message.
    public let level: LoggingLevel
    /// An optional name of the logger issuing this message.
    public let logger: String?
    /// The data to be logged, such as a string message or an object. Any JSON serializable type is allowed here.
    public let data: JSON.Value

    public init(_meta: AnyMeta? = nil, level: LoggingLevel, logger: String? = nil, data: JSON.Value) {
      self._meta = _meta
      self.level = level
      self.logger = logger
      self.data = data
    }
  }

  public let method = Notifications.loggingMessage
  public let params: Params

}

// MARK: - LoggingLevel

/// The severity of a log message.
///
/// These map to syslog message severities, as specified in RFC-5424:
/// https://datatracker.ietf.org/doc/html/rfc5424#section-6.2.1
public enum LoggingLevel: String, Codable {
  case debug
  case info
  case notice
  case warning
  case error
  case critical
  case alert
  case emergency
}

// MARK: - CreateSamplingMessageRequest

/// A request from the server to sample an LLM via the client. The client has full discretion over which model to select. The client should also inform the user before beginning sampling, to allow them to inspect the request (human in the loop) and decide whether to approve it.
public struct CreateSamplingMessageRequest: Request, HasParams, Codable {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = CreateMessageResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public init(
      _meta: MetaProgress? = nil,
      messages: [SamplingMessage],
      modelPreferences: ModelPreferences? = nil,
      systemPrompt: String? = nil,
      includeContext: MessageContext? = nil,
      temperature: Double? = nil,
      maxTokens: Int? = nil,
      stopSequences: [String]? = nil,
      metadata: JSON? = nil)
    {
      self._meta = _meta
      self.messages = messages
      self.modelPreferences = modelPreferences
      self.systemPrompt = systemPrompt
      self.includeContext = includeContext
      self.temperature = temperature
      self.maxTokens = maxTokens
      self.stopSequences = stopSequences
      self.metadata = metadata
    }

    public let _meta: MetaProgress?
    public let messages: [SamplingMessage]
    /// The server's preferences for which model to select. The client MAY ignore these preferences.
    public let modelPreferences: ModelPreferences?
    /// An optional system prompt the server wants to use for sampling. The client MAY modify or omit this prompt.
    public let systemPrompt: String?
    /// A request to include context from one or more MCP servers (including the caller), to be attached to the prompt. The client MAY ignore this request.
    public let includeContext: MessageContext?
    public let temperature: Double?
    /// The maximum number of tokens to sample, as requested by the server. The client MAY choose to sample fewer tokens than requested.
    public let maxTokens: Int?
    public let stopSequences: [String]?
    /// Optional metadata to pass through to the LLM provider. The format of this metadata is provider-specific.
    public let metadata: JSON?

  }

  public let method = Requests.createMessage
  public let params: Params

}

// MARK: - CreateMessageResult

/// The client's response to a sampling/create_message request from the server. The client should inform the user before returning the sampled message, to allow them to inspect the response (human in the loop) and decide whether to allow the server to see it.
public struct CreateMessageResult: Result, SamplingMessageInterface, Codable {
  public let role: Role
  public let content: TextOrImageContent
  public let _meta: AnyMeta?
  /// The name of the model that generated the message.
  public let model: String
  /// The reason why sampling stopped, if known.
  public let stopReason: String?

  public init(role: Role, content: TextOrImageContent, _meta: AnyMeta? = nil, model: String, stopReason: String? = nil) {
    self.role = role
    self.content = content
    self._meta = _meta
    self.model = model
    self.stopReason = stopReason
  }
}

// MARK: - SamplingMessageInterface

/// Describes a message issued to or received from an LLM API.
protocol SamplingMessageInterface {
  var role: Role { get }
  var content: TextOrImageContent { get }
}

// MARK: - Annotated

/// Base for objects that include optional annotations for the client. The client can use annotations to inform how objects are used or displayed
public protocol Annotated {
  var annotations: Annotations? { get }
}

// MARK: - Annotations

public struct Annotations: Codable, Equatable {
  /// Describes who the intended customer of this object or data is.
  /// It can include multiple entries to indicate content useful for multiple audiences (e.g., `["user", "assistant"]`).
  public let audience: [Role]?
  /// Describes how important this data is for operating the server.
  /// A value of 1 means "most important," and indicates that the data is
  /// effectively required, while 0 means "least important," and indicates that
  /// the data is entirely optional.
  /// @minimum 0
  /// @maximum 1
  public let priority: Double?

  public init(audience: [Role]? = nil, priority: Double? = nil) {
    self.audience = audience
    self.priority = priority
  }
}

// MARK: - TextContent

/// Text provided to or from an LLM.
public struct TextContent: Annotated, Codable, Equatable {
  public let annotations: Annotations?
  public let type = ResourceTypes.text
  /// The text content of the message.
  public let text: String

  public init(annotations: Annotations? = nil, text: String) {
    self.annotations = annotations
    self.text = text
  }
}

// MARK: - ImageContent

/// An image provided to or from an LLM.
public struct ImageContent: Annotated, Codable, Equatable {
  public let annotations: Annotations?
  public let type = ResourceTypes.image
  /// The base64-encoded image data.
  public let data: String
  /// The MIME type of the image. Different providers may support different image types.
  public let mimeType: String

  public init(annotations: Annotations? = nil, data: String, mimeType: String) {
    self.annotations = annotations
    self.data = data
    self.mimeType = mimeType
  }
}

// MARK: - ModelPreferences

/// The server's preferences for model selection, requested of the client during sampling.
///
/// Because LLMs can vary along multiple dimensions, choosing the "best" model is
/// rarely straightforward.  Different models excel in different areas—some are
/// faster but less capable, others are more capable but more expensive, and so
/// on. This interface allows servers to express their priorities across multiple
/// dimensions to help clients make an appropriate selection for their use case.
///
/// These preferences are always advisory. The client MAY ignore them. It is also
/// up to the client to decide how to interpret these preferences and how to
/// balance them against other considerations.
public struct ModelPreferences: Codable, Equatable {
  public init(
    hints: [ModelHint]? = nil,
    costPriority: Double? = nil,
    speedPriority: Double? = nil,
    intelligencePriority: Double? = nil)
  {
    self.hints = hints
    self.costPriority = costPriority
    self.speedPriority = speedPriority
    self.intelligencePriority = intelligencePriority
  }

  /// Optional hints to use for model selection.
  ///
  /// If multiple hints are specified, the client MUST evaluate them in order
  /// (such that the first match is taken).
  ///
  /// The client SHOULD prioritize these hints over the numeric priorities, but
  /// MAY still use the priorities to select from ambiguous matches.
  public let hints: [ModelHint]?

  /// How much to prioritize cost when selecting a model. A value of 0 means cost
  /// is not important, while a value of 1 means cost is the most important
  /// factor.
  ///
  /// @minimum 0
  /// @maximum 1
  public let costPriority: Double?

  /// How much to prioritize sampling speed (latency) when selecting a model. A
  /// value of 0 means speed is not important, while a value of 1 means speed is
  /// the most important factor.
  ///
  /// @minimum 0
  /// @maximum 1
  public let speedPriority: Double?

  /// How much to prioritize intelligence and capabilities when selecting a
  /// model. A value of 0 means intelligence is not important, while a value of 1
  /// means intelligence is the most important factor.
  ///
  /// @minimum 0
  /// @maximum 1
  public let intelligencePriority: Double?

}

// MARK: - ModelHint

/// Hints to use for model selection.
///
/// Keys not declared here are currently left unspecified by the spec and are up
/// to the client to interpret.
public struct ModelHint: Codable, Equatable {
  /// A hint for a model name.
  ///
  /// The client SHOULD treat this as a substring of a model name; for example:
  ///  - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
  ///  - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
  ///  - `claude` should match any Claude model
  ///
  /// The client MAY also map the string to a different provider's model name or a different model family, as long as it fills a similar niche; for example:
  ///  - `gemini-1.5-flash` could match `claude-3-haiku-20240307`
  public let name: String?

  public init(name: String? = nil) {
    self.name = name
  }
}

// MARK: - CompleteRequest

public struct CompleteRequest: Request, HasParams {
  public init(params: Params) {
    self.params = params
  }

  public typealias Result = CompleteResult

  public struct Params: HasMetaValue, Codable, Equatable {
    public init(_meta: MetaProgress? = nil, ref: PromptOrResourceReference, argument: Argument) {
      self._meta = _meta
      self.ref = ref
      self.argument = argument
    }

    public struct Argument: Codable, Equatable {
      /// The name of the argument
      public let name: String
      /// The value of the argument to use for completion matching.
      public let value: String

      public init(name: String, value: String) {
        self.name = name
        self.value = value
      }
    }

    public let _meta: MetaProgress?
    public let ref: PromptOrResourceReference
    public let argument: Argument

  }

  public let method = Requests.autocomplete
  public let params: Params

}

// MARK: - CompleteResult

/// The server's response to a completion/complete request
public struct CompleteResult: Result {
  public init(_meta: AnyMeta? = nil, completion: Completion) {
    self._meta = _meta
    self.completion = completion
  }

  public struct Completion: Codable {
    /// An array of completion values. Must not exceed 100 items.
    public let values: [String]
    /// The total number of completion options available. This can exceed the number of values actually sent in the response.
    public let total: Int?
    /// Indicates whether there are additional completion options beyond those provided in the current response, even if the exact total is unknown.
    public let hasMore: Bool?

    public init(values: [String], total: Int? = nil, hasMore: Bool? = nil) {
      self.values = values
      self.total = total
      self.hasMore = hasMore
    }
  }

  public let _meta: AnyMeta?
  public let completion: Completion

}

// MARK: - ResourceReference

/// A reference to a resource or resource template definition.
public struct ResourceReference: Codable, Equatable {
  public let type = ResourceTypes.resourceReference
  /// The URI or URI template of the resource.
  /// @format uri-template
  public let uri: String

  public init(uri: String) {
    self.uri = uri
  }
}

// MARK: - PromptReference

/// Identifies a prompt.
public struct PromptReference: Codable, Equatable {
  public let type = ResourceTypes.promptReference
  /// The name of the prompt or prompt template
  public let name: String

  public init(name: String) {
    self.name = name
  }
}

// MARK: - ListRootsRequest

/// Sent from the server to request a list of root URIs from the client. Roots allow
/// servers to ask for specific directories or files to operate on. A common example
/// for roots is providing a set of repositories or directories a server should operate
/// on.
///
/// This request is typically used when the server needs to understand the file system
/// structure or access specific locations that the client has permission to read from.
public struct ListRootsRequest: Request, Codable {

  public typealias Result = ListRootsResult

  public let method = Requests.listRoots
  public let params: AnyParamsWithProgressToken?

  public init(params: AnyParamsWithProgressToken? = nil) {
    self.params = params
  }
}

// MARK: - ListRootsResult

/// The client's response to a roots/list request from the server.
/// This result contains an array of Root objects, each representing a root directory
/// or file that the server can operate on.
public struct ListRootsResult: PaginatedResult, Codable {
  public let _meta: AnyMeta?
  public let nextCursor: Cursor?
  public let roots: [Root]

  public init(_meta: AnyMeta? = nil, nextCursor: Cursor? = nil, roots: [Root]) {
    self._meta = _meta
    self.nextCursor = nextCursor
    self.roots = roots
  }
}

// MARK: - Root

/// Represents a root directory or file that the server can operate on.
public struct Root: Codable, Equatable {
  /// The URI identifying the root. This *must* start with file:// for now.
  /// This restriction may be relaxed in future versions of the protocol to allow
  /// other URI schemes.
  ///
  /// @format uri
  public let uri: String
  /// An optional name for the root. This can be used to provide a human-readable
  /// identifier for the root, which may be useful for display purposes or for
  /// referencing the root in other parts of the application.
  public let name: String?

  public init(uri: String, name: String? = nil) {
    self.uri = uri
    self.name = name
  }
}

// MARK: - RootsListChangedNotification

/// A notification from the client to the server, informing it that the list of roots has changed.
/// This notification should be sent whenever the client adds, removes, or modifies any root.
/// The server should then request an updated list of roots using the ListRootsRequest.
public struct RootsListChangedNotification: Notification {
  public let method = Notifications.rootsListChanged
  public let params: AnyParams?

  public init(params: AnyParams? = nil) {
    self.params = params
  }
}

// MARK: - MessageContext

public enum MessageContext: String, Codable {
  case none
  case thisServer
  case allServers
}

// MARK: - SamplingMessage

public struct SamplingMessage: SamplingMessageInterface, Codable, Equatable {
  public let role: Role

  public let content: TextOrImageContent

  public init(role: Role, content: TextOrImageContent) {
    self.role = role
    self.content = content
  }

}

// MARK: - TextContentOrImageContentOrEmbeddedResource

public enum TextContentOrImageContentOrEmbeddedResource: Codable, Equatable {
  case text(TextContent)
  case image(ImageContent)
  case embeddedResource(EmbeddedResource)
}

// MARK: - TextOrImageContent

public enum TextOrImageContent: Codable, Equatable {
  case text(TextContent)
  case image(ImageContent)
}

// MARK: - StringOrNumber

public enum StringOrNumber: Codable, Equatable {
  case string(_ value: String)
  case number(_ value: Double)
}

// MARK: - TextOrBlobResourceContents

public enum TextOrBlobResourceContents: Codable, Equatable {
  case text(TextResourceContents)
  case blob(BlobResourceContents)
}

// MARK: - PromptOrResourceReference

public enum PromptOrResourceReference: Codable, Equatable {
  case prompt(PromptReference)
  case resource(ResourceReference)
}

// MARK: - ClientRequest

/// Requests that can be received by the client.
/// Note: the ping request is omitted since it is responded to by the connection layer.
public enum ClientRequest: Decodable, Equatable {
  case initialize(InitializeRequest.Params)
  case listPrompts(ListPromptsRequest.Params = nil)
  case getPrompt(GetPromptRequest.Params)
  case listResources(ListResourcesRequest.Params = nil)
  case readResource(ReadResourceRequest.Params)
  case subscribeToResource(SubscribeRequest.Params)
  case unsubscribeToResource(UnsubscribeRequest.Params)
  case listResourceTemplates(ListResourceTemplatesRequest.Params = nil)
  case listTools(ListToolsRequest.Params = nil)
  case callTool(CallToolRequest.Params)
  case complete(CompleteRequest.Params)
  case setLogLevel(SetLevelRequest.Params)
}

// MARK: - ClientNotification

public enum ClientNotification: Decodable, Equatable {
  case cancelled(CancelledNotification.Params)
  case progress(ProgressNotification.Params)
  case initialized(InitializedNotification.Params)
  case rootsListChanged(RootsListChangedNotification.Params)
}

// MARK: - ServerRequest

/// Requests that can be received by the server.
/// Note: the ping request is omitted since it is responded to by the connection layer.
public enum ServerRequest: Decodable, Equatable {
  case createMessage(CreateSamplingMessageRequest.Params)
  case listRoots(ListRootsRequest.Params = nil)
}

// MARK: - ServerNotification

public enum ServerNotification: Decodable, Equatable {
  case cancelled(CancelledNotification.Params)
  case progress(ProgressNotification.Params)
  case loggingMessage(LoggingMessageNotification.Params)
  case resourceUpdated(ResourceUpdatedNotification.Params)
  case resourceListChanged(ResourceListChangedNotification.Params)
  case toolListChanged(ToolListChangedNotification.Params)
  case promptListChanged(PromptListChangedNotification.Params)
}
