//
//  XMLStackParser.swift
//  XMLCoder
//
//  Created by Shawn Moore on 11/14/17.
//  Copyright © 2017 Shawn Moore. All rights reserved.
//

import Foundation

struct XMLElementContext {}

class _XMLStackParser: NSObject {
    var root: _XMLElement?
    private var stack: [_XMLElement] = []

    static func parse(with data: Data,
                      errorContextLength length: UInt) throws -> KeyedBox {
        let parser = _XMLStackParser()

        let node = try parser.parse(with: data, errorContextLength: length)

        return node.flatten()
    }

    func parse(with data: Data,
               errorContextLength: UInt) throws -> _XMLElement {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self

        guard !xmlParser.parse(), root == nil else {
            return root!
        }

        guard let error = xmlParser.parserError else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "The given data could not be parsed into XML."
            ))
        }

        guard errorContextLength > 0 else {
            throw error
        }

        let string = String(data: data, encoding: .utf8) ?? ""
        let lines = string.split(separator: "\n")
        var errorPosition = 0
        let offset = Int(errorContextLength / 2)
        for i in 0..<xmlParser.lineNumber - 1 {
            errorPosition += lines[i].count
        }
        errorPosition += xmlParser.columnNumber
        let lowerBound = String.Index(encodedOffset: errorPosition - offset)
        let upperBound = String.Index(encodedOffset: errorPosition + offset)

        let context = string[lowerBound..<upperBound]

        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: [],
            debugDescription: """
            \(error.localizedDescription) \
            at line \(xmlParser.lineNumber), column \(xmlParser.columnNumber):
            `\(context)`
            """,
            underlyingError: error
        ))
    }

    func withCurrentElement(_ body: (inout _XMLElement) throws -> ()) rethrows {
        guard !stack.isEmpty else {
            return
        }
        try body(&stack[stack.count - 1])
    }
}

extension _XMLStackParser: XMLParserDelegate {
    func parserDidStartDocument(_: XMLParser) {
        root = nil
        stack = []
    }

    func parser(_: XMLParser,
                didStartElement elementName: String,
                namespaceURI _: String?,
                qualifiedName _: String?,
                attributes attributeDict: [String: String] = [:]) {
        let element = _XMLElement(key: elementName, attributes: attributeDict)
        stack.append(element)
    }

    func parser(_: XMLParser,
                didEndElement _: String,
                namespaceURI _: String?,
                qualifiedName _: String?) {
        guard var element = stack.popLast() else {
            return
        }

        if let value = element.value {
            element.value = value.isEmpty ? nil : value
        }

        withCurrentElement { currentElement in
            currentElement.append(element: element, forKey: element.key)
        }

        if stack.isEmpty {
            root = element
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        withCurrentElement { currentElement in
            currentElement.append(value: string)
        }
    }

    func parser(_: XMLParser, foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock, encoding: .utf8) else {
            return
        }
        withCurrentElement { currentElement in
            currentElement.append(value: string)
        }
    }
}
