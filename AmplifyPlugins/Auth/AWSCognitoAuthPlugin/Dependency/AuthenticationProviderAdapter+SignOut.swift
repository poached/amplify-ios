//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

typealias SignOutCompletion = (Result<Void, AuthError>) -> Void

extension AuthenticationProviderAdapter {

    func signOut(request: AuthSignOutRequest, completionHandler: @escaping SignOutCompletion) {

        // If user is signed in through HostedUI the signout require UI to complete. So calling this in main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if let webUISignOutOption = request.options.pluginOptions as? AWSAuthWebUISignOutOptions {
                if #available(iOS 13, *) {
                    self.signOutWithASWebAuthenticationSession(window: webUISignOutOption.presentationAnchor,
                                                               localSignOut: webUISignOutOption.signOutLocally,
                                                               completionHandler: completionHandler)
                } else {
                    self.signOutWithUI(isGlobalSignout: request.options.globalSignOut,
                                       completionHandler: completionHandler)
                }
            } else {
                self.signOutWithUI(isGlobalSignout: request.options.globalSignOut,
                                   completionHandler: completionHandler)
            }
        }
    }

    private func signOutWithUI(isGlobalSignout: Bool, completionHandler: @escaping SignOutCompletion) {

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        let signOutOptions = SignOutOptions(signOutGlobally: isGlobalSignout, invalidateTokens: true)
        awsMobileClient.signOut(options: signOutOptions) { [weak self] error in
            self?.handleSignOutResponse(error: error, completionHandler: completionHandler)
        }
    }

    @available(iOS 13, *)
    private func signOutWithASWebAuthenticationSession(window: UIWindow,
                                                       localSignOut: Bool,
                                                       completionHandler: @escaping SignOutCompletion) {
        guard localSignOut == false else {
            awsMobileClient.signOutLocally()
            completionHandler(.success(()))
            return
        }

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        awsMobileClient.signOut(uiwindow: window,
                                options: SignOutOptions(invalidateTokens: true)) { [weak self] error in
            self?.handleSignOutResponse(error: error, completionHandler: completionHandler)
        }
    }

    private func handleSignOutResponse(error: Error?,
                                       completionHandler: @escaping SignOutCompletion) {
        guard error == nil else {
            let authError = AuthErrorHelper.toAuthError(error!)
            if case .notAuthorized = authError {
                // signOut globally might return notAuthorized when the current token is expired or invalidated
                // In this case, we just signOut the user locally and return a success result back.
                self.awsMobileClient.signOutLocally()
                completionHandler(.success(()))
            } else {
                completionHandler(.failure(authError))
            }
            return
        }
        completionHandler(.success(()))
    }
}
