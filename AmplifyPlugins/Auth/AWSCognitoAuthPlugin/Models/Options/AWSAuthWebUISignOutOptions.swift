//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSAuthWebUISignOutOptions {

    /// Anchor on which the logout endpoint is presented for signOut.
    ///
    /// To completely signout from the browser session you should pass a presentationAnchor.
    public let presentationAnchor: AuthUIPresentationAnchor

    /// Signout locally will just removes the authenticated user from the local keychain.
    ///
    /// Default value will be `false`
    let signOutLocally: Bool

    @available(iOS 13, *)
    public init(presentationAnchor: AuthUIPresentationAnchor,
                signOutLocally: Bool = false) {
        self.presentationAnchor = presentationAnchor
        self.signOutLocally = signOutLocally
    }
}
