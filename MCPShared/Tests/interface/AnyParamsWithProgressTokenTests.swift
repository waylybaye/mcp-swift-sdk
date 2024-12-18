
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum AnyParamsWithProgressTokenTest {
    struct Serialization {

      // MARK: Internal

      @Test
      func encodeWithNoValues() throws {
        try testEncoding(of: AnyParamsWithProgressToken(), """
          {}
          """)
      }

      @Test
      func encodeWithStringProgressToken() throws {
        try testEncoding(of: AnyParamsWithProgressToken(_meta: .init(progressToken: .string("123abc"))), """
          {
            "_meta" : {
              "progressToken" : "123abc"
            }
          }
          """)
      }

      @Test
      func encodeWithNumberProgressToken() throws {
        try testEncoding(of: AnyParamsWithProgressToken(_meta: .init(progressToken: .number(123456))), """
          {
            "_meta" : {
              "progressToken" : 123456
            }
          }
          """)
      }

      @Test
      func encodeWithNonMetaValues() throws {
        try testEncoding(of: AnyParamsWithProgressToken(value: .object([
          "key": .string("value"),
        ])), """
          {
            "key" : "value"
          }
          """)
      }

      @Test
      func encodeWithMetaAndOtherParameters() throws {
        try testEncoding(of: AnyParamsWithProgressToken(
          _meta: .init(progressToken: .string("123abc")),
          value: .object([
            "key": .string("value"),
          ])), """
            {
              "_meta" : {
                "progressToken" : "123abc"
              },
              "key" : "value"
            }
            """)
      }

      // MARK: Private

      private func testEncoding(of value: AnyParamsWithProgressToken, _ json: String) throws {
        try testEncodingOf(value, json)
      }
    }
  }
}
