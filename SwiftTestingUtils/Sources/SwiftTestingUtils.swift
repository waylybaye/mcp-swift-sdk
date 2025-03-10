
import Foundation
import OSLog
import Testing

private let logger = Logger(subsystem: "testing", category: "testing")

// MARK: - SwiftTestingUtils

public enum SwiftTestingUtils {

  public class Expectation {

    init(
      description: String,
      _sourceLocation: SourceLocation = #_sourceLocation)
    {
      self.description = description
      location = _sourceLocation
    }

    public func fulfill() {
      if isFulfilled {
        Issue.record("Expectation from \(location) already fulfilled.")
      }
      isFulfilled = true
      onFulfill()
    }

    private(set) var isFulfilled = false

    let description: String
    let location: SourceLocation

    func fulfillment(timeout: TimeInterval = 1) async throws {
      if isFulfilled {
        return
      }

      var hasTimedOut = false
      var hasCompleted = false
      let description = description

      try await withCheckedThrowingContinuation { continuation in
        onFulfill = {
          if !hasTimedOut {
            if hasCompleted {
              Issue.record("Expectation \(description) fulfilled multiple times.")
            } else {
              hasCompleted = true
              continuation.resume(returning: ())
            }
          } else {
            logger.error("Expectation \(description) fulfilled after timeout.")
          }
        }
        Task {
          try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
          if !hasCompleted {
            hasTimedOut = true
            continuation.resume(throwing: SwiftTesting.expectationTimeout(description: description))
          }
        }
      }
    }

    private var onFulfill: () -> Void = { }
  }

  enum SwiftTesting: Error {
    case expectationTimeout(description: String)
    case genericError(_ message: String)
  }
}

/// Create an expectation.
/// Like for `XCTestExpectation`, this expectation should be awaited during the test, and fulfilled only once.
public func expectation(description: String, _sourceLocation: SourceLocation = #_sourceLocation) -> SwiftTestingUtils
  .Expectation
{
  SwiftTestingUtils.Expectation(description: description, _sourceLocation: _sourceLocation)
}

/// Wait for an expectation to be fulfilled, or throw an error after the timeout.
public func fulfillment(of expectation: SwiftTestingUtils.Expectation, timeout: TimeInterval = 1) async throws {
  try await expectation.fulfillment(timeout: timeout)
}

/// Wait for the expectations to be fulfilled, or throw an error after the timeout.
public func fulfillment(of expectations: [SwiftTestingUtils.Expectation], timeout: TimeInterval = 1) async throws {
  for expectation in expectations {
    try await expectation.fulfillment(timeout: timeout)
  }
}

// MARK: - Issue + Error

extension Issue: @retroactive Error { }
