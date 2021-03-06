//
//  XMLKeyTests.swift
//  XMLCoderTests
//
//  Created by Vincent Esche on 12/24/18.
//

import XCTest
@testable import XMLCoder

class XMLKeyTests: XCTestCase {
    func testInitStringValue() {
        let key = _XMLKey(stringValue: "foo")
        XCTAssertEqual(key?.stringValue, "foo")
        XCTAssertEqual(key?.intValue, nil)
    }

    func testInitIntValue() {
        let key = _XMLKey(intValue: 42)
        XCTAssertEqual(key?.stringValue, "42")
        XCTAssertEqual(key?.intValue, 42)
    }

    func testInitStringValueIntValue() {
        let key = _XMLKey(stringValue: "foo", intValue: 42)
        XCTAssertEqual(key.stringValue, "foo")
        XCTAssertEqual(key.intValue, 42)
    }
}
