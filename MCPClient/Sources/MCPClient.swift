import Combine
import Foundation
import MCPInterface

// MARK: - MCPClient

// TODO: Support cancelling a request

public actor MCPClient: MCPClientInterface {

  /// Creates a MCP client and connects to the server through the provided transport.
  /// The methods completes after connecting to the server.
  public init(
    info: Implementation,
    transport: Transport,
    capabilities: ClientCapabilityHandlers = .init())
  async throws {
    try await self.init(
      capabilities: capabilities,
      connection: MCPClientConnection(
        info: info,
        capabilities: ClientCapabilities(
          experimental: nil, // TODO: support experimental requests
          roots: capabilities.roots?.info,
          sampling: capabilities.sampling?.info),
        transport: transport))
  }

  init(
    capabilities: ClientCapabilityHandlers,
    connection: MCPClientConnectionInterface)
  async throws {
    // Initialize the connection, and then update server capabilities.
    self.connection = connection
    self.capabilities = capabilities
    serverInfo = try await Self.connectToServer(connection: connection)

    await startListeningToNotifications()
    await startListeningToRequests()
    startPinging()

    Task { try await self.updateTools() }
    Task { try await self.updatePrompts() }
    Task { try await self.updateResources() }
    Task { try await self.updateResourceTemplates() }
  }

  public private(set) var serverInfo: ServerInfo

  public var tools: ReadOnlyCurrentValueSubject<CapabilityStatus<[Tool]>, Never> {
    get async {
      await .init(_tools.compactMap(\.self).removeDuplicates().eraseToAnyPublisher())
    }
  }

  public var prompts: ReadOnlyCurrentValueSubject<CapabilityStatus<[Prompt]>, Never> {
    get async {
      await .init(_prompts.compactMap(\.self).removeDuplicates().eraseToAnyPublisher())
    }
  }

  public var resources: ReadOnlyCurrentValueSubject<CapabilityStatus<[Resource]>, Never> {
    get async {
      await .init(_resources.compactMap(\.self).removeDuplicates().eraseToAnyPublisher())
    }
  }

  public var resourceTemplates: ReadOnlyCurrentValueSubject<CapabilityStatus<[ResourceTemplate]>, Never> {
    get async {
      await .init(_resourceTemplates.compactMap(\.self).removeDuplicates().eraseToAnyPublisher())
    }
  }

  public func callTool(
    named name: String,
    arguments: JSON? = nil,
    progressHandler: ((Double, Double?) -> Void)? = nil)
    async throws -> CallToolResult
  {
    guard serverInfo.capabilities.tools != nil else {
      throw MCPError.capabilityNotSupported
    }
    var progressToken: String? = nil
    if let progressHandler {
      let token = UUID().uuidString
      progressHandlers[token] = progressHandler
      progressToken = token
    }
    let result = try await connection.call(
      toolName: name,
      arguments: arguments,
      progressToken: progressToken.map { .string($0) })
    if let progressToken {
      progressHandlers[progressToken] = nil
    }
    // If there has been an error during the execution, throw it
    if result.isError == true {
      let errors = result.content.compactMap(\.text).map { CallToolResult.ExecutionError(text: $0.text) }
      throw MCPClientError.toolCallError(executionErrors: errors)
    }
    return result
  }

  public func getPrompt(named name: String, arguments: JSON? = nil) async throws -> GetPromptResult {
    guard serverInfo.capabilities.prompts != nil else {
      throw MCPError.capabilityNotSupported
    }
    return try await connection.getPrompt(.init(name: name, arguments: arguments))
  }

  public func readResource(uri: String) async throws -> ReadResourceResult {
    guard serverInfo.capabilities.resources != nil else {
      throw MCPError.capabilityNotSupported
    }
    return try await connection.readResource(.init(uri: uri))
  }

  let connection: MCPClientConnectionInterface

  private let capabilities: ClientCapabilityHandlers

  private let _tools = CurrentValueSubject<CapabilityStatus<[Tool]>?, Never>(nil)
  private let _prompts = CurrentValueSubject<CapabilityStatus<[Prompt]>?, Never>(nil)
  private let _resources = CurrentValueSubject<CapabilityStatus<[Resource]>?, Never>(nil)
  private let _resourceTemplates = CurrentValueSubject<CapabilityStatus<[ResourceTemplate]>?, Never>(nil)

  private var progressHandlers = [String: (progress: Double, total: Double?) -> Void]()

  private static func connectToServer(connection: MCPClientConnectionInterface) async throws -> ServerInfo {
    let response = try await connection.initialize()
    guard response.protocolVersion == MCP.protocolVersion else {
      throw MCPClientError.versionMismatch(received: response.protocolVersion, expected: MCP.protocolVersion)
    }

    try await connection.acknowledgeInitialization()

    return ServerInfo(
      info: response.serverInfo,
      capabilities: response.capabilities)
  }

  private func startListeningToNotifications() async {
    let notifications = await connection.notifications
    Task { [weak self] in
      for await notification in notifications {
        switch notification {
        case .cancelled:
          // TODO: Handle this
          break

        case .loggingMessage:
          // TODO: Handle this
          break

        case .progress(let progressParams):
          if let token = progressParams.progressToken.string {
            await self?.progressHandlers[token]?(progressParams.progress, progressParams.total)
          }

        case .promptListChanged:
          try await self?.updatePrompts()

        case .resourceListChanged:
          try await self?.updateResources()

        case .toolListChanged:
          try await self?.updateResources()

        case .resourceUpdated:
          // TODO: Handle this
          break
        }
      }
    }
  }

  private func startListeningToRequests() async {
    let requests = await connection.requestsToHandle
    Task { [weak self] in
      for await (request, completion) in requests {
        guard let self else {
          completion(.failure(.init(
            code: JRPCErrorCodes.internalError.rawValue,
            message: "The client disconnected")))
          return
        }
        switch request {
        case .createMessage(let params):
          await completion(handle(request: params, with: capabilities.sampling?.handler, "Sampling"))
        case .listRoots(let params):
          await completion(handle(request: params, with: capabilities.roots?.handler, "Listing roots"))
        }
      }
    }
  }

  private func handle<Params>(
    request params: Params,
    with handler: ((Params) async throws -> some Encodable)?,
    _ requestName: String)
    async -> AnyJRPCResponse
  {
    if let handler {
      do {
        return try await .success(handler(params))
      } catch {
        return .failure(.init(
          code: JRPCErrorCodes.internalError.rawValue,
          message: error.localizedDescription))
      }
    } else {
      return .failure(.init(
        code: JRPCErrorCodes.invalidRequest.rawValue,
        message: "\(requestName) is not supported by this server"))
    }
  }

  private func startPinging() {
    // TODO
  }

  private func updateTools() async throws {
    guard serverInfo.capabilities.tools != nil else {
      // Tool calling not supported
      _tools.send(.notSupported)
      return
    }
    let tools = try await connection.listTools()
    _tools.send(.supported(tools))
  }

  private func updatePrompts() async throws {
    guard serverInfo.capabilities.prompts != nil else {
      // Prompts calling not supported
      _prompts.send(.notSupported)
      return
    }
    let prompts = try await connection.listPrompts()
    _prompts.send(.supported(prompts))
  }

  private func updateResources() async throws {
    guard serverInfo.capabilities.resources != nil else {
      // Resources calling not supported
      _resources.send(.notSupported)
      return
    }
    let resources = try await connection.listResources()
    _resources.send(.supported(resources))
  }

  private func updateResourceTemplates() async throws {
    guard serverInfo.capabilities.resources != nil else {
      // Resources calling not supported
      _resourceTemplates.send(.notSupported)
      return
    }
    let resourceTemplates = try await connection.listResourceTemplates()
    _resourceTemplates.send(.supported(resourceTemplates))
  }

}
