//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class BaseList<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral {

    public typealias Element = ModelType
    public typealias Elements = [Element]
    public typealias Index = Int
    public typealias ArrayLiteralElement = ModelType

    /// The array of `Element` that backs the custom collection implementation.
    internal var elements: Elements

    // MARK: - Initializers

    public init(_ elements: Elements) {
        self.elements = elements
    }

    public required convenience init(arrayLiteral elements: ModelType...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    open var startIndex: Index {
        return elements.startIndex
    }

    open var endIndex: Index {
        return elements.endIndex
    }

    open func index(after index: Index) -> Index {
        return elements.index(after: index)
    }

    open subscript(position: Int) -> Element {
        return elements[position]
    }

    open __consuming func makeIterator() -> IndexingIterator<Elements> {
        return elements.makeIterator()
    }

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        switch json {
        case .array:
            let elements = try Elements(from: decoder)
            self.init(elements)
        default:
            self.init(Elements())
        }
    }
}
