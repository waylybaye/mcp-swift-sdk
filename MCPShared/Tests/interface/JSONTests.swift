
import Foundation
import MCPShared
import Testing

extension MCPInterfaceTests {
  struct JSONTests {
    @Test
    func nonNestedObject() throws {
      try testDecodingEncodingOf("""
        {
          "name": "John",
          "age": 31,
          "city": "New York"
        }
        """, with: JSON.self)
    }

    @Test
    func arrayOfNonNestedObject() throws {
      try testDecodingEncodingOf("""
        [{
          "name": "John",
          "age": 31,
          "city": "New York"
        }]
        """, with: JSON.self)
    }

    @Test
    func arrayOfSeveralNonNestedObject() throws {
      try testDecodingEncodingOf("""
        [{
          "name": "John",
          "age": 31,
          "city": "New York"
        },{
          "name": "Joe",
          "age": 32,
          "city": "San Francisco"
        }]
        """, with: JSON.self)
    }

    @Test
    func arrayOfNestedAndNonNestedObject() throws {
      try testDecodingEncodingOf("""
        [{
          "name": "John",
          "age": 31,
          "city": "New York",
          "address": {
            "street": "5th Avenue",
            "houseNumber": 12,
            "acceptDelivery": true
          }
        },{
          "name": "Joe",
          "age": 32,
          "city": "San Francisco"
        }]
        """, with: JSON.self)
    }
  }
}
