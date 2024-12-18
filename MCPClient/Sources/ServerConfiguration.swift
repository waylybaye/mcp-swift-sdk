import Foundation

public struct RunnableServerConfiguration: Decodable {
  public init(executable: String, args: [String] = [], env: [String: String]? = nil, timeout: TimeInterval = 1) {
    self.executable = executable
    self.args = args
    self.env = env
    self.timeout = timeout
  }

  public let executable: String
  public let args: [String]
  public let env: [String: String]?
  public let timeout: TimeInterval
}
