
import Foundation
import JSONRPC
import OSLog

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier.map { "\($0).jsonrpc" } ?? "com.app.jsonrpc",
  category: "jsonrpc")

// MARK: - JSONRPCSetupError

public enum JSONRPCSetupError: Error {
  case missingStandardIO
  case couldNotLocateExecutable(executable: String, error: String?)
}

// MARK: LocalizedError

extension JSONRPCSetupError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .missingStandardIO:
      return "Missing standard IO"
    case .couldNotLocateExecutable(let executable, let error):
      return "Could not locate executable \(executable) \(error ?? "")".trimmingCharacters(in: .whitespaces)
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .missingStandardIO:
      return "Make sure that the Process that is passed as an argument has stdin, stdout and stderr set as a Pipe."
    case .couldNotLocateExecutable:
      return "Check that the executable is findable given the PATH environment variable. If needed, pass the right environment to the process."
    }
  }
}

extension DataChannel {

  // MARK: Public

  public static func stdioProcess(
    _ executable: String,
    args: [String] = [],
    cwd: String? = nil,
    env: [String: String]? = nil,
    verbose: Bool = false)
    throws -> DataChannel
  {
    if verbose {
      let command = "\(executable) \(args.joined(separator: " "))"
      logger.log("Running ↪ \(command)")
    }

    // Create the process
    func path(for executable: String) throws -> String {
      guard !executable.contains("/") else {
        return executable
      }
      let path = try locate(executable: executable, env: env)
      return path.isEmpty ? executable : path
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: try path(for: executable))
    process.arguments = args
    if let env {
      process.environment = env
    }

    // Working directory
    if let cwd {
      process.currentDirectoryPath = cwd
    }

    // Input/output
    let stdin = Pipe()
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr

    return try stdioProcess(unlaunchedProcess: process, verbose: verbose)
  }

  public static func stdioProcess(
    unlaunchedProcess process: Process,
    verbose: Bool = false)
    throws -> DataChannel
  {
    guard
      let stdin = process.standardInput as? Pipe,
      let stdout = process.standardOutput as? Pipe,
      let stderr = process.standardError as? Pipe
    else {
      throw JSONRPCSetupError.missingStandardIO
    }

    // Run the process
    var stdoutData = Data()
    var stderrData = Data()

    let outStream: AsyncStream<Data>
    if verbose {
      // As we are both reading stdout here in this function, and want to make the stream readable to the caller,
      // we read the data from the process's stdout, process it and then re-yield it to the caller to a new stream.
      // This is because an AsyncStream can have only one reader.
      var outContinuation: AsyncStream<Data>.Continuation?
      outStream = AsyncStream<Data> { continuation in
        outContinuation = continuation
      }

      Task {
        for await data in stdout.fileHandleForReading.dataStream {
          stdoutData.append(data)
          outContinuation?.yield(data)

          logger.log("Received data:\n\(String(data: data, encoding: .utf8) ?? "nil")")
        }
        outContinuation?.finish()
      }

      if stdout.fileHandleForReading.fileDescriptor != stderr.fileHandleForReading.fileDescriptor {
        Task {
          for await data in stderr.fileHandleForReading.dataStream {
            logger.log("Received error:\n\(String(data: data, encoding: .utf8) ?? "nil")")
            stderrData.append(data)
          }
        }
      }
    } else {
      // If we are not in verbose mode, we are not reading from stdout internally, so we can just return the stream directly.
      outStream = stdout.fileHandleForReading.dataStream
    }

    // Ensures that the process is terminated when the DataChannel is de-referenced.
    let lifetime = Lifetime {
      if process.isRunning {
        process.terminate()
      }
    }

    if process.terminationHandler == nil {
      process.terminationHandler = { task in
        if verbose {
          logger
            .log(
              "Process \(process.processIdentifier) terminated with termination status \(task.terminationStatus)\(stdoutData.toLog(withTitle: "stdout"))\(stderrData.toLog(withTitle: "stderr"))")
        }
      }
    }

    do {
      try process.launchThrowably()
    } catch {
      assertionFailure("Unexpected error: \(error)")
      throw error
    }

    let writeHandler: DataChannel.WriteHandler = { [lifetime] data in
      _ = lifetime
      if verbose {
        logger.log("Sending data:\n\(String(data: data, encoding: .utf8) ?? "nil")")
      }

      stdin.fileHandleForWriting.write(data)
      // Send \n to flush the buffer
      stdin.fileHandleForWriting.write(Data("\n".utf8))
    }

    return DataChannel(writeHandler: writeHandler, dataSequence: outStream)
  }

  // MARK: Private

  /// Finds the full path to the executable using the `which` command.
  private static func locate(executable: String, env: [String: String]? = nil) throws -> String {
    let stdout = Pipe()
    let stderr = Pipe()
    let process = Process()
    process.standardOutput = stdout
    process.standardError = stderr
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [executable]

    if let env {
      process.environment = env
    }

    let group = DispatchGroup()
    var stdoutData = Data()
    var stderrData = Data()

    // From https://github.com/kareman/SwiftShell/blob/99680b2efc7c7dbcace1da0b3979d266f02e213c/Sources/SwiftShell/Command.swift#L140-L163
    do {
      try process.launchThrowably()

      if stdout.fileHandleForReading.fileDescriptor != stderr.fileHandleForReading.fileDescriptor {
        DispatchQueue.global().async(group: group) {
          stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        }
      }

      stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
      try process.finish()
    } catch {
      throw JSONRPCSetupError.couldNotLocateExecutable(
        executable: executable,
        error: String(data: stderrData, encoding: .utf8))
    }

    group.wait()

    guard
      let executablePath = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
      !executablePath.isEmpty
    else {
      throw JSONRPCSetupError.couldNotLocateExecutable(executable: executable, error: String(data: stderrData, encoding: .utf8))
    }
    return executablePath
  }

}

// MARK: - Lifetime

final class Lifetime {

  // MARK: Lifecycle

  init(onDeinit: @escaping () -> Void) {
    self.onDeinit = onDeinit
  }

  deinit {
    onDeinit()
  }

  // MARK: Private

  private let onDeinit: () -> Void

}

extension Data {
  fileprivate func toLog(withTitle title: String) -> String {
    guard let string = String(data: self, encoding: .utf8), !string.isEmpty else { return "" }

    return """

      \(title):
      \(string)
      """
  }
}
