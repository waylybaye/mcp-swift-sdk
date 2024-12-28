import Foundation
import JSONSchema
import JSONSchemaBuilder
import MCPInterface

// MARK: - CallableTool

// Allows to use @Schemable from `JSONSchemaBuilder` to define the input for tools as:
//
// @Schemable
// struct RepeatToolInput {
//  let text: String
// }
//
// print(RepeatToolInput.schema.schemaValue)
// -> {"required":["text"],"properties":{"text":{"type":"string"}},"type":"object"}

/// Definition for a tool the client can call.
public protocol CallableTool {
  associatedtype Input: Decodable
  /// A JSON Schema object defining the expected parameters for the tool.
  var inputSchema: JSON { get }
  /// The name of the tool.
  var name: String { get }
  /// A human-readable description of the tool.
  var description: String? { get }

  func decodeInput(_ input: JSON?) throws -> Input

  func call(_ input: Input) async throws -> [TextContentOrImageContentOrEmbeddedResource]
}

// MARK: - Tool

public struct Tool<Input>: CallableTool {

  // MARK: Lifecycle

  public init(
    name: String,
    description: String? = nil,
    inputSchema: JSON,
    decodeInput: @escaping (Data) throws -> Input,
    call: @escaping (Input) async throws -> [TextContentOrImageContentOrEmbeddedResource])
  {
    self.name = name
    self.description = description
    self.inputSchema = inputSchema
    _decodeInput = decodeInput
    _call = call
  }

  // MARK: Public

  public let name: String

  public let description: String?

  public let inputSchema: JSON

  public func call(_ input: Input) async throws -> [TextContentOrImageContentOrEmbeddedResource] {
    try await _call(input)
  }

  public func decodeInput(_ input: MCPInterface.JSON?) throws -> Input {
    let data = try JSONEncoder().encode(input)
    return try _decodeInput(data)
  }

  // MARK: Private

  private let _call: (Input) async throws -> [TextContentOrImageContentOrEmbeddedResource]

  private let _decodeInput: (Data) throws -> Input
}

extension Tool where Input: Schemable {
  public init(
    name: String,
    description: String? = nil,
    call: @escaping (Input) async throws -> [TextContentOrImageContentOrEmbeddedResource]) where Input.Schema.Output == Input
  {
    self.init(
      name: name,
      description: description,
      inputSchema: Input.schema.schemaValue.json,
      decodeInput: { data in
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        switch Input.schema.parse(json) {
        case .valid(let value):
          return value
        case .invalid(let errors):
          throw errors.first ?? MCPServerError.toolCallError(errors)
        }
      },
      call: call)
  }
}

extension Tool where Input: Decodable {
  public init(
    name: String,
    description: String? = nil,
    inputSchema: JSON,
    call: @escaping (Input) async throws -> [TextContentOrImageContentOrEmbeddedResource])
  {
    self.init(
      name: name,
      description: description,
      inputSchema: inputSchema,
      decodeInput: { data in
        try JSONDecoder().decode(Input.self, from: data)
      },
      call: call)
  }
}

extension CallableTool {
  public func decodeInput(_ input: JSON?) throws -> Input {
    let data = try JSONEncoder().encode(input)
    return try JSONDecoder().decode(Input.self, from: data)
  }

  public func call(_ input: JSON?) async throws -> [TextContentOrImageContentOrEmbeddedResource] {
    let input = try decodeInput(input)
    return try await call(input)
  }
}

extension Array where Element == any CallableTool {
  func asRequestHandler(listToolChanged: Bool)
    -> ListedCapabilityHandler<ListChangedCapability, CallToolRequest.Handler, ListToolsRequest.Handler>
  {
    let toolsByName = [String: any CallableTool](uniqueKeysWithValues: map { ($0.name, $0) })

    return .init(
      info: .init(listChanged: listToolChanged),
      handler: { request in
        let name = request.name
        guard let tool = toolsByName[name] else {
          throw MCPError.notSupported
        }
        let arguments = request.arguments
        do {
          let content = try await tool.call(arguments)
          return CallToolResult(content: content)
        } catch {
          return CallToolResult(content: [.text(.init(text: error.localizedDescription))], isError: true)
        }
      },
      listHandler: { _ in
        ListToolsResult(tools: self.map { tool in MCPInterface.Tool(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema) })
      })
  }
}

/// Convert between the JSON representation from `JSONSchema` and ours
extension [KeywordIdentifier: JSONValue] {
  fileprivate var json: JSON {
    .object(mapValues { $0.value })
  }
}

extension JSONValue {
  fileprivate var value: JSON.Value {
    switch self {
    case .null:
      .null
    case .boolean(let value):
      .bool(value)
    case .number(let value):
      .number(value)
    case .string(let value):
      .string(value)
    case .array(let value):
      .array(value.map { $0.value })
    case .object(let value):
      .object(value.mapValues { $0.value })
    case .integer(let value):
      .number(Double(value))
    }
  }
}

// MARK: - ParseIssue + Error

extension ParseIssue: @retroactive Error { }
