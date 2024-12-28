
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  enum AnyMetaTest {
    struct Serialization {

      // MARK: Internal

      @Test
      func encodeWithNoValues() throws {
        try testEncoding(of: AnyMeta(.object([:])), """
          {}
          """)
      }

      @Test
      func encodeWithValues() throws {
        try testEncoding(of: AnyMeta(.object([
          "key": .string("value"),
          "foo": .number(1),
          "bar": .bool(true),
        ])), """
          {
            "bar" : true,
            "foo" : 1,
            "key" : "value"
          }
          """)
      }

      // MARK: Private

      private func testEncoding(of value: AnyMeta, _ json: String) throws {
        try testEncodingOf(value, json)
      }
    }

    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeWithNoValues() throws {
        try testDecoding(of: """
          {}
          """, AnyMeta(.object([:])))
      }

      @Test
      func decodeWithValues() throws {
        try testDecoding(of: """
          {
            "key": "value",
            "foo": 1,
            "bar": true
          }
          """, AnyMeta(.object([
          "key": .string("value"),
          "foo": .number(1),
          "bar": .bool(true),
        ])))
      }

      // MARK: Private

      private func testDecoding(of jsonString: String, _ value: AnyMeta) throws {
        let data = jsonString.data(using: .utf8)!
        let decodedValue = try JSONDecoder().decode(AnyMeta.self, from: data)
        #expect(decodedValue.value == value.value)
      }
    }
  }
}
