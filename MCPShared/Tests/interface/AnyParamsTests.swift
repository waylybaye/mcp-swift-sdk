
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum AnyParamsTest {
    struct Serialization {

      // MARK: Internal

      @Test
      func encodeWithNoValues() throws {
        try testEncoding(of: AnyParams(), """
          {}
          """)
      }

      @Test
      func encodeWithMetaValues() throws {
        try testEncoding(of: AnyParams(_meta: .init(value: .object([
          "key": .string("value"),
        ]))), """
          {
            "_meta" : {
              "key" : "value"
            }
          }
          """)
      }

      @Test
      func encodeWithNonMetaValues() throws {
        try testEncoding(of: AnyParams(value: .object([
          "key": .string("value"),
        ])), """
          {
            "key" : "value"
          }
          """)
      }

      @Test
      func encodeWithMetaAndOtherParameters() throws {
        try testEncoding(of: AnyParams(
          _meta: .init(value: .object([
            "meta_key": .string("meta_value"),
          ])),
          value: .object([
            "key": .string("value"),
          ])), """
            {
              "_meta" : {
                "meta_key" : "meta_value"
              },
              "key" : "value"
            }
            """)
      }

      // MARK: Private

      private func testEncoding(of value: AnyParams, _ json: String) throws {
        try testEncodingOf(value, json)
      }
    }

    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeWithNoValues() throws {
        try testDecoding(of: """
          {}
          """, AnyParams())
      }

      @Test
      func decodeWithMetaValues() throws {
        try testDecoding(of: """
          {
            "_meta" : {
              "key" : "value"
            }
          }
          """, AnyParams(_meta: .init(value: .object([
          "key": .string("value"),
        ]))))
      }

      @Test
      func decodeWithNonMetaValues() throws {
        try testDecoding(of: """
          {
            "key" : "value"
          }
          """, AnyParams(value: .object([
          "key": .string("value"),
        ])))
      }

      @Test
      func decodeWithMetaAndOtherParameters() throws {
        try testDecoding(of: """
          {
            "_meta" : {
              "meta_key" : "meta_value"
            },
            "key" : "value"
          }
          """, AnyParams(
          _meta: .init(value: .object([
            "meta_key": .string("meta_value"),
          ])),
          value: .object([
            "key": .string("value"),
          ])))
      }

      // MARK: Private

      private func testDecoding(of json: String, _ expected: AnyParams) throws {
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyParams.self, from: data)
        #expect(value == expected)
      }
    }
  }
}
