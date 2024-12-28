
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  struct AnyParamsWithProgressTokenTest {

    @Test
    func encodeWithNoValues() throws {
      try testEncodingDecoding(of: AnyParamsWithProgressToken(), """
        {}
        """)
    }

    @Test
    func encodeWithStringProgressToken() throws {
      try testEncodingDecoding(of: AnyParamsWithProgressToken(_meta: .init(progressToken: .string("123abc"))), """
        {
          "_meta" : {
            "progressToken" : "123abc"
          }
        }
        """)
    }

    @Test
    func encodeWithNumberProgressToken() throws {
      try testEncodingDecoding(of: AnyParamsWithProgressToken(_meta: .init(progressToken: .number(123456))), """
        {
          "_meta" : {
            "progressToken" : 123456
          }
        }
        """)
    }

    @Test
    func encodeWithNonMetaValues() throws {
      try testEncodingDecoding(of: AnyParamsWithProgressToken(value: [
        "key": .string("value"),
      ]), """
        {
          "key" : "value"
        }
        """)
    }

    @Test
    func encodeWithMetaAndOtherParameters() throws {
      try testEncodingDecoding(of: AnyParamsWithProgressToken(
        _meta: .init(progressToken: .string("123abc")),
        value: [
          "key": .string("value"),
        ]), """
          {
            "_meta" : {
              "progressToken" : "123abc"
            },
            "key" : "value"
          }
          """)
    }
  }
}
