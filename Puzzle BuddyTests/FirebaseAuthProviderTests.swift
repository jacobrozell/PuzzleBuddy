//
//  FirebaseAuthProviderTests.swift
//  Puzzle BuddyTests
//

import AuthenticationServices
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class FirebaseAuthProviderTests: XCTestCase {
    func testLoginRejectsBlankEmail() async {
        let auth = FirebaseAuthProvider()
        auth.login = ""
        auth.password = "secret"

        await assertInvalidCredentials(await authResult(auth))
    }

    func testLoginRejectsBlankPassword() async {
        let auth = FirebaseAuthProvider()
        auth.login = "user@example.com"
        auth.password = ""

        await assertInvalidCredentials(await authResult(auth))
    }

    func testSendResetPasswordRequiresSignedInUser() async {
        let auth = FirebaseAuthProvider()
        auth.user = nil

        do {
            try await auth.sendResetPassword()
            XCTFail("Expected invalid credentials error")
        } catch let error as FirebaseAuthProvider.FirebaseAuthError {
            XCTAssertEqual(error.errorDescription, "No email on file")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateUserNoOpsWithoutSignedInUser() async throws {
        let auth = FirebaseAuthProvider()
        auth.user = nil

        try await auth.updateUser()
        XCTAssertNil(auth.user)
    }

    func testStartSignInWithAppleFlowConfiguresRequest() {
        let auth = FirebaseAuthProvider()
        let request = ASAuthorizationAppleIDProvider().createRequest()

        auth.startSignInWithAppleFlow(request: request)

        XCTAssertNotNil(auth.currentNonce)
        XCTAssertNotNil(request.nonce)
        XCTAssertEqual(request.requestedScopes, [.fullName, .email])
        XCTAssertNotEqual(request.nonce, auth.currentNonce)
    }

    private func authResult(_ auth: FirebaseAuthProvider) async -> Result<Void, Error> {
        do {
            try await auth.login()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func assertInvalidCredentials(_ result: Result<Void, Error>) async {
        switch result {
        case .success:
            XCTFail("Expected invalid credentials error")
        case .failure(let error as FirebaseAuthProvider.FirebaseAuthError):
            XCTAssertEqual(error.errorDescription, "Invalid or blank credentials")
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        }
    }
}
