import JSONRPC
import MemberwiseInit

public typealias Transport = DataChannel

extension Transport {
  public static var noop: Transport {
    .init(writeHandler: { _ in }, dataSequence: DataSequence { _ in })
  }
}

public typealias AnyJRPCResponse = Swift.Result<Encodable & Sendable, AnyJSONRPCResponseError>

// MARK: - CapabilityHandler

/// Describes a capability of a client/server (see `ClientCapabilities` and `ServerCapabilities`), as well as how it is handled.
@MemberwiseInit(.public, _optionalsDefaultNil: true)
public struct CapabilityHandler<Info, Handler> {
  public let info: Info
  public let handler: Handler
}

extension CapabilityHandler where Info == EmptyObject {
  public init(handler: Handler) {
    self.init(info: .init(), handler: handler)
  }
}

// MARK: - CapabilityStatus

/// Describes whether a given capability is supported by the other peer,
/// and if so provide details about which functionalities (subscription, listing changes) are supported.
public enum CapabilityStatus<Capability: Equatable>: Equatable {
  case supported(_ capability: Capability)
  case notSupported
}

extension CapabilityStatus {
  public var capability: Capability? {
    switch self {
    case .supported(let capability):
      capability
    case .notSupported:
      nil
    }
  }

  public func get() throws -> Capability {
    switch self {
    case .supported(let capability):
      return capability
    case .notSupported:
      throw MCPError.notSupported
    }
  }
}

// MARK: - MCPError

public enum MCPError: Error {
  case notSupported
}

public typealias HandleServerRequest = (ServerRequest, (AnyJRPCResponse) -> Void)

public typealias HandleClientRequest = (ClientRequest, (AnyJRPCResponse) -> Void)
