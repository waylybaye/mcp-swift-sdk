
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  struct TextOrBlobResourceContentsTest {

    // MARK: Internal

    @Test
    func decodeText() throws {
      let json = """
        {
          "uri": "file:///example.txt",
          "mimeType": "text/plain",
          "text": "Resource content"
        }
        """
      let value = try decode(json)

      #expect(value.text?.text == "Resource content")
      try testEncodingDecoding(of: value, json)
    }

    @Test
    func decodeImage() throws {
      let json = """
        {
          "uri": "file:///example.png",
          "mimeType": "image/png",
          "blob": "base64-encoded-data"
        }
        """
      let value = try decode(json)

      #expect(value.blob?.blob == "base64-encoded-data")
      try testEncodingDecoding(of: value, json)
    }

    // MARK: Private

    private func decode(_ jsonString: String) throws -> TextOrBlobResourceContents {
      let data = jsonString.data(using: .utf8)!
      return try JSONDecoder().decode(TextOrBlobResourceContents.self, from: data)
    }
  }
}
