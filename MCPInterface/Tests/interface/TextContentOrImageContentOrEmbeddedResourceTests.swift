
import Foundation
import MCPInterface
import Testing

extension MCPInterfaceTests {
  struct TextContentOrImageContentOrEmbeddedResourceTest {

    // MARK: Internal

    @Test
    func decodeText() throws {
      let json = """
        {
          "type": "text",
          "text": "Tool result text"
        }
        """
      let value = try decode(json)

      #expect(value.text?.text == "Tool result text")
      try testEncodingDecoding(of: value, json)
    }

    @Test
    func decodeImage() throws {
      let json = """
        {
          "type": "image",
          "data": "base64-encoded-data",
          "mimeType": "image/png"
        }
        """
      let value = try decode(json)

      #expect(value.image?.data == "base64-encoded-data")
      try testEncodingDecoding(of: value, json)
    }

    @Test
    func decodeResource() throws {
      let json = """
        {
          "type": "resource",
          "resource": {
            "uri": "resource://example",
            "mimeType": "text/plain",
            "text": "Resource content"
          }
        }
        """
      let value = try decode(json)

      #expect(value.embeddedResource?.resource.text?.uri == "resource://example")
      try testEncodingDecoding(of: value, json)
    }

    // MARK: Private

    private func decode(_ jsonString: String) throws -> TextContentOrImageContentOrEmbeddedResource {
      let data = jsonString.data(using: .utf8)!
      return try JSONDecoder().decode(TextContentOrImageContentOrEmbeddedResource.self, from: data)
    }
  }
}
