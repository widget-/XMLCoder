//
//  XMLStackParser.swift
//  XMLCoder
//
//  Created by Shawn Moore on 11/14/17.
//  Copyright © 2017 Shawn Moore. All rights reserved.
//

import Foundation

struct XMLElementContext {}

class XMLStackParser: NSObject {
    var root: XMLCoderElement?
    private var stack: [XMLCoderElement] = []

    static func parse(with data: Data) throws -> KeyedBox {
        let parser = XMLStackParser()

        guard let node = try parser.parse(with: data) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "The given data could not be parsed into XML."
            ))
        }

        return node.flatten()
    }

    func parse(with data: Data) throws -> XMLCoderElement? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self

        guard xmlParser.parse() else {
            if let error = xmlParser.parserError {
                throw error
            }
            return nil
        }

        return root
    }

    func withCurrentElement(_ body: (inout XMLCoderElement) throws -> Void) rethrows {
        guard !stack.isEmpty else {
            return
        }
        try body(&stack[stack.count - 1])
    }
}

extension XMLStackParser: XMLParserDelegate {
    func parserDidStartDocument(_: XMLParser) {
        root = nil
        stack = []
    }

    func parser(_: XMLParser,
                didStartElement elementName: String,
                namespaceURI _: String?,
                qualifiedName _: String?,
                attributes attributeDict: [String: String] = [:]) {
        let element = XMLCoderElement(key: elementName, attributes: attributeDict)
        stack.append(element)
    }

    func parser(_: XMLParser, didEndElement _: String, namespaceURI _: String?, qualifiedName _: String?) {
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

    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
}
