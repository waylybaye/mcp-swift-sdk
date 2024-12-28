
import Foundation
import MCPInterface
import Testing
extension MCPInterfaceTests {
  enum LoggingLevelTest {
    struct Serialization {

      // MARK: Internal

      @Test
      func encodeDebug() throws {
        try testEncoding(of: .debug, "\"debug\"")
      }

      @Test
      func encodeInfo() throws {
        try testEncoding(of: .info, "\"info\"")
      }

      @Test
      func encodeNotice() throws {
        try testEncoding(of: .notice, "\"notice\"")
      }

      @Test
      func encodeWarning() throws {
        try testEncoding(of: .warning, "\"warning\"")
      }

      @Test
      func encodeError() throws {
        try testEncoding(of: .error, "\"error\"")
      }

      @Test
      func encodeCritical() throws {
        try testEncoding(of: .critical, "\"critical\"")
      }

      @Test
      func encodeAlert() throws {
        try testEncoding(of: .alert, "\"alert\"")
      }

      @Test
      func encodeEmergency() throws {
        try testEncoding(of: .emergency, "\"emergency\"")
      }

      // MARK: Private

      private func testEncoding(of value: LoggingLevel, _ json: String) throws {
        // wrap the value in array for it to be valid JSON
        try testEncodingOf([value], "[\(json)]")
      }
    }

    struct Deserialization {

      // MARK: Internal

      @Test
      func decodeDebug() throws {
        try testDecoding(of: "\"debug\"", .debug)
      }

      @Test
      func decodeInfo() throws {
        try testDecoding(of: "\"info\"", .info)
      }

      @Test
      func decodeNotice() throws {
        try testDecoding(of: "\"notice\"", .notice)
      }

      @Test
      func decodeWarning() throws {
        try testDecoding(of: "\"warning\"", .warning)
      }

      @Test
      func decodeError() throws {
        try testDecoding(of: "\"error\"", .error)
      }

      @Test
      func decodeCritical() throws {
        try testDecoding(of: "\"critical\"", .critical)
      }

      @Test
      func decodeAlert() throws {
        try testDecoding(of: "\"alert\"", .alert)
      }

      @Test
      func decodeEmergency() throws {
        try testDecoding(of: "\"emergency\"", .emergency)
      }

      @Test
      func failsToDecodeBadValue() throws {
        // wrap the value in array for it to be valid JSON
        let data = "[\"unknown\"]".data(using: .utf8)!
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([LoggingLevel].self, from: data) }
      }

      // MARK: Private

      private func testDecoding(of json: String, _ value: LoggingLevel) throws {
        // wrap the value in array for it to be valid JSON
        let data = "[\(json)]".data(using: .utf8)!
        #expect(try JSONDecoder().decode([LoggingLevel].self, from: data).first! == value)
      }
    }
  }
}
