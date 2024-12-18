
import Foundation
import MCPShared
import Testing
extension MCPInterfaceTests {
  enum RoleTest {
    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeUser() throws {
        #expect(try decode("\"user\"") == .user)
      }

      @Test
      func decodeAssistant() throws {
        #expect(try decode("\"assistant\"") == .assistant)
      }

      @Test
      func failsToDecodeBadValue() throws {
        #expect(throws: DecodingError.self) { try decode("\"bot\"") }
      }

      // MARK: Private

      private func decode(_ json: String) throws -> Role {
        // wrap the value in array for it to be valid JSON
        let data = "[\(json)]".data(using: .utf8)!
        return try JSONDecoder().decode([Role].self, from: data).first!
      }
    }
  }
}
