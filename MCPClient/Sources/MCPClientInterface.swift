import JSONRPC
import MCPShared

// MARK: - MCPClientInterface

public protocol MCPClientInterface { }

public typealias Transport = DataChannel

// MARK: - MCPClientError

public enum MCPClientError: Error {
  case alreadyConnectedOrConnecting
  case notConnected
  case notSupported
  case versionMismatch
  case toolCallError(executionErrors: [CallToolResult.ExecutionError])
}

// MARK: - ServerCapabilityState

public enum ServerCapabilityState<Capability: Equatable>: Equatable {
  case supported(_ capability: Capability)
  case notSupported
}

extension ServerCapabilityState {
  public var capability: Capability? {
    switch self {
    case .supported(let capability):
      return capability
    case .notSupported:
      return nil
    }
  }

  public func get() throws -> Capability {
    switch self {
    case .supported(let capability):
      return capability
    case .notSupported:
      throw MCPClientError.notSupported
    }
  }
}
