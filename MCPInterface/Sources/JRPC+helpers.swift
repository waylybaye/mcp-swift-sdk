import JSONRPC

extension JSONRPCSession {
  public func send<Req: Request>(_ request: Req) async throws -> Req.Result {
    let response: JSONRPCResponse<Req.Result> = try await sendRequest(request.params, method: request.method)
    return try response.content.get()
  }

  public func send(_ notification: some MCPInterface.Notification) async throws {
    try await sendNotification(notification.params, method: notification.method)
  }

  public func send<Req: PaginatedRequest, Result>(
    _ params: Req.Params,
    getResults: (Req.Result) -> [Result],
    req _: Req.Type = Req.self)
    async throws -> [Result]
  {
    var cursor: String? = nil
    var results = [Result]()

    while true {
      let request = Req(params: Req.Params.updating(cursor: cursor, from: params))
      let response = try await send(request)
      results.append(contentsOf: getResults(response))
      cursor = response.nextCursor
      if cursor == nil {
        return results
      }
    }
  }

}
