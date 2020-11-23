//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

class AuthenticationProviderSignupTests: XCTestCase {

    var authenticationProvider: AuthenticationProviderAdapter?
    var mockAWSMobileClient: MockAWSMobileClient?

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        authenticationProvider = AuthenticationProviderAdapter(awsMobileClient: mockAWSMobileClient!)

    }

    override func tearDown() {
        mockAWSMobileClient = nil
        authenticationProvider = nil
    }

    func testSignupWithSuccess() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])
        let signupRequest = AuthSignUpRequest(username: "username",
                                              password: "password",
                                              options: options)

        let resultExpectation = expectation(description: "Should receive a result")
        authenticationProvider?.signUp(request: signupRequest, completionHandler: { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let signupResult):
                guard case .done = signupResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signupResult.isSignupComplete, "Signup result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        })
        wait(for: [resultExpectation], timeout: 2)
    }

    func testSignupWithoutPassword() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])
        let signupRequest = AuthSignUpRequest(username: "username",
                                              password: nil,
                                              options: options)

        let resultExpectation = expectation(description: "Should receive a result")
        authenticationProvider?.signUp(request: signupRequest, completionHandler: { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let signupResult):
                guard case .done = signupResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signupResult.isSignupComplete, "Signup result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        })
        wait(for: [resultExpectation], timeout: 2)
    }

    func testSignupWithUnConfirmedUser() {

        let mockEmail = "someemail@email"
        let mockCodeDelivery = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                       destination: mockEmail,
                                                       attributeName: "email")
        let mockSignupResult = SignUpResult(signUpState: .unconfirmed, codeDeliveryDetails: mockCodeDelivery)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let signupRequest = AuthSignUpRequest(username: "username",
                                              password: "password",
                                              options: AuthSignUpRequest.Options())

        let resultExpectation = expectation(description: "Should receive a result")
        authenticationProvider?.signUp(request: signupRequest, completionHandler: { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let signupResult):
                guard case .confirmUser(let details, _) = signupResult.nextStep else {
                    XCTFail("Result should be .confirmUser for next step")
                    return
                }

                guard case .email(let deliveryDestination) = details?.destination else {
                    XCTFail("Destination should be .email for next step")
                    return
                }

                guard case .email = details?.attributeKey else {
                    XCTFail("Verifying attribute is email")
                    return
                }
                XCTAssertFalse(signupResult.isSignupComplete, "Signup result should be complete")
                XCTAssertEqual(deliveryDestination, mockEmail, "Destination of signup should be same")

            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        })
        wait(for: [resultExpectation], timeout: 2)
    }

    func testSignupWithInvalidResult() {

        mockAWSMobileClient?.signupMockResult = nil

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])
        let signupRequest = AuthSignUpRequest(username: "username",
                                              password: nil,
                                              options: options)

        let resultExpectation = expectation(description: "Should receive a result")
        authenticationProvider?.signUp(request: signupRequest, completionHandler: { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce an unknown error")
                    return
                }

            }
        })
        wait(for: [resultExpectation], timeout: 2)
    }
}
