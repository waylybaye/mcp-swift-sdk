import Foundation

// MARK: - JSON

public enum JSON: Codable, Equatable, Sendable {
  case object(_ value: [String: JSON.Value])
  case array(_ value: [JSON.Value])

  // MARK: - JSONValue

  public enum Value: Codable, Equatable, Sendable {
    case string(_ value: String)
    case object(_ value: [String: JSON.Value])
    case array(_ value: [JSON.Value])
    case bool(_ value: Bool)
    case number(_ value: Double)
    case null
  }
}

// MARK: ExpressibleByDictionaryLiteral

extension JSON: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, JSON.Value)...) {
    var object = [String: JSON.Value]()

    for element in elements {
      object[element.0] = element.1
    }

    self = .object(object)
  }
}

// MARK: ExpressibleByArrayLiteral

extension JSON: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: JSON.Value...) {
    var array = [JSON.Value]()

    for element in elements {
      array.append(element)
    }

    self = .array(array)
  }
}

// MARK: - JSON.Value + ExpressibleByNilLiteral

extension JSON.Value: ExpressibleByNilLiteral {
  public init(nilLiteral _: ()) {
    self = .null
  }
}

// MARK: - JSON.Value + ExpressibleByDictionaryLiteral

extension JSON.Value: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, JSON.Value)...) {
    var object = [String: JSON.Value]()

    for element in elements {
      object[element.0] = element.1
    }

    self = .object(object)
  }
}

// MARK: - JSON.Value + ExpressibleByStringLiteral

extension JSON.Value: ExpressibleByStringLiteral {
  public init(stringLiteral: String) {
    self = .string(stringLiteral)
  }
}

// MARK: - JSON.Value + ExpressibleByIntegerLiteral

extension JSON.Value: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: IntegerLiteralType) {
    self = .number(Double(value))
  }
}

// MARK: - JSON.Value + ExpressibleByFloatLiteral

extension JSON.Value: ExpressibleByFloatLiteral {
  public init(floatLiteral value: FloatLiteralType) {
    self = .number(value)
  }
}

// MARK: - JSON.Value + ExpressibleByArrayLiteral

extension JSON.Value: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: JSON.Value...) {
    var array = [JSON.Value]()

    for element in elements {
      array.append(element)
    }

    self = .array(array)
  }
}

// MARK: - JSON.Value + ExpressibleByBooleanLiteral

extension JSON.Value: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}
