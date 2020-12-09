//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ProjectSpec

protocol DependenciesResolver {
    associatedtype ResolvedDependencies
    static func resolve(dependencies: [Dependency]) -> ResolvedDependencies
}

struct CocoapodsPod: CustomStringConvertible {
    let description: String
    init(_ dependency: Dependency) {
        // TODO: assuming latest version, handle version resolution
        switch dependency {
        case .name(let name, let version):
            self.description = "pod '\(name)'"
        case .url(let url, let name, let version):
            self.description = "pod '\(name)', :git => '\(url)'"
        }
    }
}

// MARK: - CocoapodsDependenciesResolver
struct CocoapodsDependenciesResolver: DependenciesResolver {
    typealias ResolvedDependencies = [CocoapodsPod]

    static func resolve(dependencies: [Dependency]) -> [CocoapodsPod] {
        dependencies.map { CocoapodsPod($0) }
    }
}

// MARK: - SwiftPmDependenciesResolver
struct SwiftPmDependenciesResolver: DependenciesResolver {
    typealias ResolvedDependencies = [String: SwiftPackage]

    static func resolve(dependencies: [Dependency]) -> ResolvedDependencies {
        // TODO
        return [:]
    }
}
