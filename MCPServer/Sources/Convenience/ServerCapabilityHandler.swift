extension ServerCapabilityHandlers {
  /// Initialize a new `ServerCapabilityHandlers` with the given handlers.
  /// - Parameters:
  ///  - logging: The logging handler.
  ///  - prompts: The prompts handler.
  ///  - tools: The list of supported tools (the request handlers will be created automatically).
  ///  - resources: The resources handler.
  public init(
    logging: SetLevelRequest.Handler? = nil,
    prompts: ListedCapabilityHandler<ListChangedCapability, GetPromptRequest.Handler, ListPromptsRequest.Handler>? = nil,
    tools: [any CallableTool],
    resources: ResourcesCapabilityHandler? = nil)
  {
    self.init(
      logging: logging,
      prompts: prompts,
      tools: tools.asRequestHandler(listToolChanged: false),
      resources: resources)
  }
}
