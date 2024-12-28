import OSLog

package let mcpLogger = Logger(subsystem: Bundle.main.bundleIdentifier.map { "\($0).mcp" } ?? "com.app.mcp", category: "mcp")
