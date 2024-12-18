
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum TextOrImageContentTest {
    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeText() throws {
        let value = try decode("""
          {
            "type": "text",
            "text": "Tool result text"
          }
          """)

        #expect(value.text?.text == "Tool result text")
      }

      @Test
      func decodeImage() throws {
        let value = try decode("""
          {
            "type": "image",
            "data": "base64-encoded-data",
            "mimeType": "image/png"
          }
          """)

        #expect(value.image?.data == "base64-encoded-data")
      }

      @Test
      func failsToDecodeBadData() throws {
        #expect(throws: DecodingError.self) {
          try decode("""
            {
              "type": "resource",
              "resource": {
                "uri": "resource://example",
                "mimeType": "text/plain",
                "text": "Resource content"
              }
            }
            """)
        }
      }

      // MARK: Private

      private func decode(_ jsonString: String) throws -> TextOrImageContent {
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(TextOrImageContent.self, from: data)
      }
    }
  }
}
