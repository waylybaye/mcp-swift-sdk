
import Foundation
import Testing

extension Data {
  func jsonString() throws -> String {
    let object = try JSONSerialization.jsonObject(with: self, options: [])
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    return String(data: data, encoding: .utf8)!
  }
}

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

/// Test encoding the value to Json, and comparing it to the expectation.
func testEncodingOf(_ value: some Encodable, _ json: String) throws {
  let encoder = JSONEncoder()
  let encoded = try encoder.encode(value)

  let jsonData = json.data(using: .utf8)!

  let encodedString = try encoded.jsonString()
  let expected = try jsonData.jsonString()

  #expect(expected == encodedString)
}
