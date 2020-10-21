//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `List<ModelType>` provides simple conformance to `Collection` with a backing array of `Model` type elements.
/// This class acts as an abstract class for plugins to build subclasses that implement their own specific
/// implementations of a `ModelList`. The decoding logic leverages the `ModelListRegistry` to check for decodability
/// and decodes to subclasses of this type.
open class List<ModelType: Model>: ModelList {
    public typealias ModelListElement = ModelType
    public typealias Page = List<ModelType>
    public typealias Element = ModelType
    public typealias Elements = [Element]

    /// The array of `Element` that backs the custom collection implementation.
    internal var elements: Elements

    // MARK: - Initializers

    public init(_ elements: Elements) {
        self.elements = elements
    }

    // MARK: - ExpressibleByArrayLiteral

    public required convenience init(arrayLiteral elements: ModelType...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    open var startIndex: Int {
        elements.startIndex
    }

    open var endIndex: Int {
        elements.endIndex
    }

    open func index(after index: Index) -> Index {
        elements.index(after: index)
    }

    open subscript(position: Int) -> Element {
        elements[position]
    }

    open __consuming func makeIterator() -> IndexingIterator<Elements> {
        elements.makeIterator()
    }

    // MARK: Persistant operations
    
    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    @available(*, deprecated, message: "Not supported.")
    public func limit(_ limit: Int) -> Self {
        return self
    }

    // MARK: Paginatable

    open func hasNextPage() -> Bool {
        return false
    }

    open func getNextPage() throws -> List<ModelType> {
        fatalError("Not supported")
    }

    // MARK: - Codable

    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders {
            if listDecoder.shouldDecode(decoder: decoder) {
                guard let list = listDecoder.decode(decoder: decoder, modelType: ModelType.self) as? Self else {
                    fatalError("Failed to decode")
                }

                self.init(factory: { list })
                return
            }
        }

        let json = try JSONValue(from: decoder)

        switch json {
        case .array:
            let elements = try Elements(from: decoder)
            self.init(elements)
        default:
            self.init(Elements())
        }
    }

    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}
