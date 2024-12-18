
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum TextOrBlobResourceContentsTest {
    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeText() throws {
        let value = try decode("""
          {
            "uri": "file:///example.txt",
            "mimeType": "text/plain",
            "text": "Resource content"
          }
          """)

        #expect(value.text?.text == "Resource content")
      }

      @Test
      func decodeImage() throws {
        let value = try decode("""
          {
            "uri": "file:///example.png",
            "mimeType": "image/png",
            "blob": "base64-encoded-data"
          }
          """)

        #expect(value.blob?.blob == "base64-encoded-data")
      }

      // MARK: Private

      private func decode(_ jsonString: String) throws -> TextOrBlobResourceContents {
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(TextOrBlobResourceContents.self, from: data)
      }
    }
  }
}
