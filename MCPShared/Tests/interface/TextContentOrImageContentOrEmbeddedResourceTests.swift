
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  enum TextContentOrImageContentOrEmbeddedResourceTest {

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
      func decodeResource() throws {
        let value = try decode("""
          {
            "type": "resource",
            "resource": {
              "uri": "resource://example",
              "mimeType": "text/plain",
              "text": "Resource content"
            }
          }
          """)

        #expect(value.embeddedResource?.resource.text?.uri == "resource://example")
      }

      // MARK: Private

      private func decode(_ jsonString: String) throws -> TextContentOrImageContentOrEmbeddedResource {
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(TextContentOrImageContentOrEmbeddedResource.self, from: data)
      }
    }
  }
}
