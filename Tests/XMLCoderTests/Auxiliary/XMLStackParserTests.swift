//
//  XMLStackParserTests.swift
//  XMLCoderTests
//
//  Created by Vincent Esche on 12/21/18.
//

import XCTest
@testable import XMLCoder

class XMLStackParserTests: XCTestCase {
    func testParseWith() throws {
        let parser = XMLStackParser()

        let xmlString = "<container><value>42</value></container>"
        let xmlData = xmlString.data(using: .utf8)!

        let root: XMLCoderElement? = try parser.parse(with: xmlData)

        let expected = XMLCoderElement(
            key: "container",
            elements: [
                "value": [
                    XMLCoderElement(
                        key: "value",
                        value: "42"
                    ),
                ],
            ]
        )
        XCTAssertEqual(root, expected)
    }
}
