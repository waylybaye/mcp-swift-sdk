
import Combine

// MARK: - ReadOnlyCurrentValueSubject

/// Like `CurrentValueSubject`, but read-only other than for its owner.
public class ReadOnlyCurrentValueSubject<Output, Failure>: Publisher where Failure: Error {

  // MARK: Lifecycle

  public init(_ value: Output, setValue: @escaping ((Output) -> Void) -> Void) {
    currentValueSubject = .init(value)
    setValue { [weak self] in
      self?.value = $0
    }
  }

  public init(_ publisher: AnyPublisher<Output, Never>) async {
    var cancellable: AnyCancellable?
    var currentValue: CurrentValueSubject<Output, Failure>?

    currentValueSubject = await withCheckedContinuation { continuation in
      cancellable = publisher.sink { value in
        if let currentValue {
          currentValue.send(value)
        } else {
          let curValue = CurrentValueSubject<Output, Failure>(value)
          currentValue = curValue
          continuation.resume(returning: curValue)
        }
      }
    }
    self.cancellable = cancellable
  }

  // MARK: Public

  public private(set) var value: Output {
    get { currentValueSubject.value }
    set { currentValueSubject.value = newValue }
  }

  public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    currentValueSubject.receive(subscriber: subscriber)
  }

  // MARK: Private

  private var cancellable: AnyCancellable?

  private let currentValueSubject: CurrentValueSubject<Output, Failure>

}
