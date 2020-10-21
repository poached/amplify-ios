//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides page related functionality when conforming to `Paginatable`
public protocol Paginatable {

    associatedtype Page

    /// Checks if there is subsequent data to retrieve. If True, retrieve the next page using `getNextPage()`
    func hasNextPage() -> Bool

    /// Retrieves the next page as a new in-memory object.
    func getNextPage() throws -> Page
}
