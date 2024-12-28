import Combine
import JSONRPC
import MCPInterface

// MARK: - MCPServer

// TODO: Support cancelling request
// TODO: Support sending progress
// TODO: test MCPServer

public actor MCPServer: MCPServerInterface {

  // MARK: Lifecycle

  /// Creates a MCP server and connects to the client through the provided transport.
  /// The methods completes after connecting to the client.
  public init(
    info: Implementation,
    capabilities: ServerCapabilityHandlers,
    transport: Transport,
    initializeRequestHook: @escaping InitializeRequestHook = { _ in })
  async throws {
    connection = try MCPServerConnection(
      info: info,
      capabilities: capabilities.description,
      transport: transport)
    self.info = info
    self.capabilities = capabilities

    clientInfo = try await Self.connectToClient(
      connection: connection,
      initializeRequestHook: initializeRequestHook,
      capabilities: capabilities,
      info: info)

    Task {
      for await notification in await connection.notifications {
        mcpLogger.log("Received notification: \(String(describing: notification), privacy: .public)")
      }
    }
    await startListeningToNotifications()
    await startListeningToRequests()
    startPinging()

    Task { try await self.updateRoots() }
  }

  // MARK: Public

  public private(set) var clientInfo: ClientInfo

  public var roots: ReadOnlyCurrentValueSubject<CapabilityStatus<[Root]>, Never> {
    get async {
      await .init(_roots.compactMap { $0 }.removeDuplicates().eraseToAnyPublisher())
    }
  }

  public func waitForDisconnection() async throws {
    await withCheckedContinuation { (_ continuation: CheckedContinuation<Void, Never>) in
      // keep running forever
      // TODO: handle disconnection from the transport. From ping?
      didDisconnect = {
        continuation.resume()
      }
    }
  }

  public func getSampling(params: CreateSamplingMessageRequest.Params) async throws -> CreateSamplingMessageRequest.Result {
    guard clientInfo.capabilities.sampling != nil else {
      throw MCPError.notSupported
    }
    return try await connection.requestCreateMessage(params)
  }

  public func log(params: LoggingMessageNotification.Params) async throws {
    try await connection.log(params)
  }

  public func notifyResourceUpdated(params: ResourceUpdatedNotification.Params) async throws {
    guard capabilities.resources != nil else {
      throw MCPError.notSupported
    }
    try await connection.notifyResourceUpdated(params)
  }

  public func notifyResourceListChanged(params _: ResourceListChangedNotification.Params? = nil) async throws {
    guard capabilities.resources != nil else {
      throw MCPError.notSupported
    }
    try await connection.notifyResourceListChanged()
  }

  public func notifyToolListChanged(params _: ToolListChangedNotification.Params? = nil) async throws {
    guard capabilities.tools != nil else {
      throw MCPError.notSupported
    }
    try await connection.notifyResourceListChanged()
  }

  public func notifyPromptListChanged(params _: PromptListChangedNotification.Params? = nil) async throws {
    guard capabilities.prompts != nil else {
      throw MCPError.notSupported
    }
    try await connection.notifyResourceListChanged()
  }

  public func update(tools: [any CallableTool]) async throws {
    guard capabilities.tools?.info.listChanged == true else {
      throw MCPError.notSupported
    }
    capabilities = .init(
      logging: capabilities.logging,
      prompts: capabilities.prompts,
      tools: tools.asRequestHandler(listToolChanged: true),
      resources: capabilities.resources)

    try await connection.notifyToolListChanged()
  }

  // MARK: Private

  private let _roots = CurrentValueSubject<CapabilityStatus<[Root]>?, Never>(nil)

  private let info: Implementation

  private var capabilities: ServerCapabilityHandlers

  /// Called once the client has disconnected. The closure should only be called once.
  private var didDisconnect: () -> Void = { }

  private let connection: MCPServerConnection

  private static func connectToClient(
    connection: MCPServerConnectionInterface,
    initializeRequestHook: @escaping InitializeRequestHook,
    capabilities: ServerCapabilityHandlers,
    info: Implementation)
    async throws -> ClientInfo
  {
    try await withCheckedThrowingContinuation { (_ continuation: CheckedContinuation<ClientInfo, Error>) in
      Task {
        for await(request, completion) in await connection.requestsToHandle {
          if case .initialize(let params) = request {
            do {
              try await initializeRequestHook(params)
              completion(.success(InitializeRequest.Result(
                protocolVersion: MCP.protocolVersion,
                capabilities: capabilities.description,
                serverInfo: info)))

              let clientInfo = ClientInfo(
                info: params.clientInfo,
                capabilities: params.capabilities)
              continuation.resume(returning: clientInfo)
            } catch {
              completion(.failure(.init(
                code: JRPCErrorCodes.internalError.rawValue,
                message: error.localizedDescription)))
              continuation.resume(throwing: error)
            }
            break
          } else {
            mcpLogger.error("Unexpected request received before initialization")
            completion(.failure(.init(
              code: JRPCErrorCodes.internalError.rawValue,
              message: "Unexpected request received before initialization")))
          }
        }
      }
    }
  }

  private func updateRoots() async throws {
    guard clientInfo.capabilities.roots != nil else {
      // Tool calling not supported
      _roots.send(.notSupported)
      return
    }
    let roots = try await connection.listRoots()
    _roots.send(.supported(roots.roots))
  }

  private func startPinging() {
    // TODO
  }

  private func handle<Params>(
    request params: Params,
    with handler: ((Params) async throws -> some Encodable)?,
    _ requestName: String)
    async -> AnyJRPCResponse
  {
    if let handler {
      do {
        return .success(try await handler(params))
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

  private func startListeningToNotifications() async {
    let notifications = await connection.notifications
    Task { [weak self] in
      for await notification in notifications {
        switch notification {
        case .cancelled:
          // TODO: Handle this
          break

        case .progress(let progressParams):
          // TODO: Handle this
          break

        case .initialized:
          break

        case .rootsListChanged:
          try await self?.updateRoots()
        }
      }
    }
  }

  private func startListeningToRequests() async {
    let requests = await connection.requestsToHandle
    Task { [weak self] in
      for await(request, completion) in requests {
        mcpLogger.log("Received request: \(String(describing: request), privacy: .public)")

        guard let self else {
          completion(.failure(.init(
            code: JRPCErrorCodes.internalError.rawValue,
            message: "The server is gone")))
          return
        }

        switch request {
        case .initialize:
          mcpLogger.error("initialization received twice")
          completion(.failure(.init(
            code: JRPCErrorCodes.internalError.rawValue,
            message: "initialization received twice")))

        case .listPrompts(let params):
          await completion(handle(request: params, with: capabilities.prompts?.listHandler, "Listing prompts"))

        case .getPrompt(let params):
          await completion(handle(request: params, with: capabilities.prompts?.handler, "Getting prompt"))

        case .listResources(let params):
          await completion(handle(request: params, with: capabilities.resources?.listResource, "Listing resources"))

        case .readResource(let params):
          await completion(handle(request: params, with: capabilities.resources?.readResource, "Reading resource"))

        case .subscribeToResource(let params):
          await completion(handle(request: params, with: capabilities.resources?.subscribeToResource, "Subscribing to resource"))

        case .unsubscribeToResource(let params):
          await completion(handle(
            request: params,
            with: capabilities.resources?.unsubscribeToResource,
            "Unsubscribing to resource"))

        case .listResourceTemplates(let params):
          await completion(handle(
            request: params,
            with: capabilities.resources?.listResourceTemplates,
            "Listing resource templates"))

        case .listTools(let params):
          await completion(handle(request: params, with: capabilities.tools?.listHandler, "Listing tools"))

        case .callTool(let params):
          await completion(handle(request: params, with: capabilities.tools?.handler, "Tool calling"))

        case .complete(let params):
          await completion(handle(request: params, with: capabilities.resources?.complete, "Resource completion"))

        case .setLogLevel(let params):
          await completion(handle(request: params, with: capabilities.logging, "Setting log level"))
        }
      }
    }
  }

}

extension ServerCapabilityHandlers {
  /// The MCP description of the supported server capabilities, inferred from which ones have handlers.
  var description: ServerCapabilities {
    ServerCapabilities(
      experimental: nil, // TODO: support experimental requests
      logging: logging != nil ? EmptyObject() : nil,
      prompts: prompts?.info,
      resources: resources.map { capability in
        CapabilityInfo(
          subscribe: capability.subscribeToResource != nil,
          listChanged: capability.listChanged)
      },
      tools: tools?.info)
  }
}
