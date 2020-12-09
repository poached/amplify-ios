//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum DependencyVersion {
    case latest
}

enum Dependency {
    case name(_: String, version: DependencyVersion = .latest)
    case url(_: URL, named: String, version: DependencyVersion = .latest)
}
