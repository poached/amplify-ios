//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 * Amplify project templates
 */
protocol AmplifyProjectTemplate {
    // dependencies based on provided dependency manager
    func dependencies(for manager: DependencyManager, platform: SupportedPlatform) -> [Dependency]

    // files URL relatives to template bundle folder
    func assets() -> [URL]
}

// MARK: AmplifyProjectTemplateFactory
protocol AmplifyProjectTemplateFactory {
    static func template(by identifier: AmplifyTemplateIdentifier) -> AmplifyProjectTemplate
}
extension AmplifyProjectTemplateFactory {
    static func template(by identifier: AmplifyTemplateIdentifier) -> AmplifyProjectTemplate {
        switch identifier {
        case .datastore:
            return DataStoreTemplate()
        default:
            return DataStoreTemplate()
        }
    }
}

// MARK: DataStoreTemplate
struct DataStoreTemplate: AmplifyProjectTemplate {
    func dependencies(for manager: DependencyManager, platform: SupportedPlatform) -> [Dependency] {
        switch manager {
        case .cocoapods:
            return [
                .name("Amplify"),
                .name("AmplifyPlugins/AWSDataStorePlugin")
            ]
        case .swiftpm:
            return []
        }
    }

    func assets() -> [URL] {
        return []
    }
}
