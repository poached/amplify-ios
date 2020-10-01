//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class DataStoreList<ModelType: Model>: BaseList<ModelType> {

    /// If the list represents an association between two models, the `associatedId` will
    /// hold the information necessary to query the associated elements (e.g. comments of a post)
    internal var associatedId: Model.Identifier?

    /// The associatedField represents the field to which the owner of the `List` is linked to.
    /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
    /// of `Post` will have a reference to the `post` field in `Comment`.
    internal var associatedField: ModelField?

    /// The array of `Element` that backs the custom collection implementation.
    internal var elements: Elements = []

    /// The current state of lazily loaded list
    internal var state: LoadState = .pending

    internal var limit: Int = 100

    // MARK: - Initializers

    public convenience override init(_ elements: Elements) {
        self.init(elements, associatedId: nil, associatedField: nil)
        self.state = .loaded
    }

    public init(_ elements: Elements,
                associatedId: Model.Identifier? = nil,
                associatedField: ModelField? = nil) {
        super.init(elements)
        self.associatedId = associatedId
        self.associatedField = associatedField
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    public override var startIndex: Index {
        loadIfNeeded()
        return elements.startIndex
    }

    public override var endIndex: Index {
        return elements.endIndex
    }

    public override func index(after index: Index) -> Index {
        return elements.index(after: index)
    }

    public override subscript(position: Int) -> Element {
        return elements[position]
    }

    public __consuming override func makeIterator() -> IndexingIterator<Elements> {
        loadIfNeeded()
        return elements.makeIterator()
    }

    // MARK: - Persistent Operations

    /// Returns the number of currently loaded elements
    public var currentCount: Int {
        elements.count
    }

    public func limit(_ limit: Int) -> Self {
        // TODO handle query with limit
        self.limit = limit
        state = .pending
        return self
    }

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        switch json {
        case .array:
            let elements = try Elements(from: decoder)
            self.init(elements)
        case .object(let list):
            if case let .string(associatedId) = list["associatedId"],
               case let .string(associatedField) = list["associatedField"] {
                let field = Element.schema.field(withName: associatedField)
                // TODO handle eager loaded associations with elements
                self.init([], associatedId: associatedId, associatedField: field)
            } else {
                self.init(Elements())
            }
        default:
            self.init(Elements())
        }
    }
}
