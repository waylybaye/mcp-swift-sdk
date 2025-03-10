
import Foundation
import MCPInterface
import Testing
extension MCPInterfaceTests {
  struct PromptOrResourceReferenceTest {

    @Test
    func encodePrompt() throws {
      let value = PromptOrResourceReference.prompt(.init(name: "code_review"))
      try testEncodingDecoding(of: value, """
        {
          "name" : "code_review",
          "type" : "ref/prompt"
        }
        """)
    }

    @Test
    func encodeResource() throws {
      let value = PromptOrResourceReference.resource(.init(uri: "file:///foo_path"))
      try testEncodingDecoding(of: value, """
        {
          "type" : "ref/resource",
          "uri" : "file:///foo_path"
        }
        """)
    }

    private func testEncoding(of value: PromptOrResourceReference, _ json: String) throws {
      try testEncodingOf(value, json)
    }
  }
}
