
import Foundation
import MCPShared
import Testing
extension MCPInterfaceTests {
  enum PromptOrResourceReferenceTest {
    struct Serialization {

      // MARK: Internal

      @Test
      func encodePrompt() throws {
        try testEncoding(of: .prompt(.init(name: "code_review")), """
          {
            "name" : "code_review",
            "type" : "ref/prompt"
          }
          """)
      }

      @Test
      func encodeResource() throws {
        try testEncoding(of: .resource(.init(uri: "file:///foo_path")), """
          {
            "type" : "ref/resource",
            "uri" : "file:///foo_path"
          }
          """)
      }

      // MARK: Private

      private func testEncoding(of value: PromptOrResourceReference, _ json: String) throws {
        try testEncodingOf(value, json)
      }
    }
  }
}
