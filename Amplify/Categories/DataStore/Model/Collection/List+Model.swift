//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol ListProtocol { }
/// `List<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral, ListProtocol {

    public typealias Element = ModelType
    public typealias Elements = [Element]
    public typealias Index = Int
    public typealias ArrayLiteralElement = ModelType

    /// The inner list delegation object instantiated from the decoding
    internal var list: BaseList<ModelType>

    ///
    public var base: BaseList<ModelType> {
        list
    }

    // MARK: - Initializers

    public init(list: BaseList<ModelType>) {
        self.list = list
    }

    public required convenience init(arrayLiteral elements: ModelType...) {
        self.init(list: BaseList(elements))
    }

    // MARK: - Collection conformance

    public var startIndex: Index {
        list.startIndex
    }

    public var endIndex: Index {
        list.endIndex
    }

    public func index(after index: Index) -> Index {
        list.index(after: index)
    }

    public subscript(position: Int) -> Element {
        list[position]
    }

    public __consuming func makeIterator() -> IndexingIterator<Elements> {
        list.makeIterator()
    }

    // MARK: Persistant operations

    @available(*, deprecated, message: "Not supported.")
    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    // MARK: - Codable

    required convenience public init(from decoder: Decoder) throws {
        self.init(list: ListDecoderRegistry.decode(decoder: decoder, modelType: ModelType.self))
    }

    public func encode(to encoder: Encoder) throws {
        try list.elements.encode(to: encoder)
    }
}
