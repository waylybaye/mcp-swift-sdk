
import Foundation
import Testing

extension Data {
  func jsonString() throws -> String {
    let object = try JSONSerialization.jsonObject(with: self, options: [])
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    guard let str = String(data: data, encoding: .utf8) else {
      throw JSONError()
    }
    return str
  }
}

// MARK: - JSONError

private struct JSONError: Error { }

/// Test decoding the Json data to the given type, encoding it back to Json, and comparing the results.
func testDecodingEncodingOf<T: Codable>(_ json: String, with _: T.Type) throws {
  let jsonData = json.data(using: .utf8)!
  let jsonDecoder = JSONDecoder()
  let decoded = try jsonDecoder.decode(T.self, from: jsonData)

  let encoder = JSONEncoder()
  let encoded = try encoder.encode(decoded)

  let value = try encoded.jsonString()
  let expected = try jsonData.jsonString()

  #expect(expected == value)
}

/// Test that encoding the value gives the expected json.
func testEncodingOf(_ value: some Encodable, _ json: String) throws {
  let encoded = try JSONEncoder().encode(value)
  let encodedString = try encoded.jsonString()

  // Reformat the json expectation (pretty print, sort keys)
  let jsonData = json.data(using: .utf8)!
  let expected = try jsonData.jsonString()

  #expect(expected == encodedString)
}

// TODO: remove the 'Of':

/// Test that decoding the json gives the expected value.
func testDecodingOf<T: Decodable & Equatable>(_ value: T, _ json: String) throws {
  let decoded = try JSONDecoder().decode(T.self, from: json.data(using: .utf8)!)
  #expect(decoded == value)
}

/// Test that encoding the value gives the expected json, and that decoding the json gives the expected value.
func testEncodingDecoding<T: Codable & Equatable>(of value: T, _ json: String) throws {
  try testEncodingOf(value, json)
  try testDecodingOf(value, json)
}
