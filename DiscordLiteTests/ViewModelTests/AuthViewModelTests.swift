import XCTest
import SwiftMockk
import Factory
@testable import DiscordLite

@MainActor
final class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockAuthRepository: MockAuthRepository!

    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()

        // Register mock in Factory container
        Container.shared.authRepository.register { self.mockAuthRepository }

        sut = AuthViewModel()
    }

    override func tearDown() {
        sut = nil
        mockAuthRepository = nil
        Container.shared.reset()
        super.tearDown()
    }

    func testInitialStateIsUnauthenticated() {
        // Then
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    func testCheckExistingSessionWithValidSessionSetsAuthenticated() async {
        // Given
        let session = AuthSession(
            sessionID: "valid-session",
            createdAt: Date(),
            expiresAt: nil
        )

        try await every {
            try await mockAuthRepository.getStoredSession()
        }.returns(session)

        // When
        await sut.checkExistingSession()

        // Then
        XCTAssertEqual(sut.authState, .authenticated(session: session))
    }

    func testCheckExistingSessionWithNoSessionSetsUnauthenticated() async {
        // Given
        try await every {
            try await mockAuthRepository.getStoredSession()
        }.returns(nil)

        // When
        await sut.checkExistingSession()

        // Then
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    func testStartAuthUpdatesStateToAuthenticating() async {
        // Given
        let authURL = URL(string: "https://discord.com/oauth2/authorize?client_id=test")!
        let sessionID = "session-123"

        try await every {
            try await mockAuthRepository.initAuth()
        }.returns((authURL: authURL, sessionID: sessionID))

        try await every {
            try await mockAuthRepository.pollAuthStatus(sessionID: any())
        }.throws(AuthError.authTimeout) // Will timeout, but that's ok for this test

        // When
        await sut.startAuth()

        // Give polling a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        if case .authenticating(let sid) = sut.authState {
            XCTAssertEqual(sid, sessionID)
        } else {
            XCTFail("Expected authenticating state, got \(sut.authState)")
        }
    }

    func testCancelAuthSetsStateToUnauthenticated() async {
        // Given
        sut.authState = .authenticating(sessionID: "test-session")

        // When
        sut.cancelAuth()

        // Then
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    func testLogoutCallsRevokeAuthAndSetsUnauthenticated() async {
        // Given
        let session = AuthSession(
            sessionID: "session-to-logout",
            createdAt: Date(),
            expiresAt: nil
        )
        sut.authState = .authenticated(session: session)

        try await every {
            try await mockAuthRepository.revokeAuth(sessionID: any())
        }.returns(())

        // When
        await sut.logout()

        // Then
        XCTAssertEqual(sut.authState, .unauthenticated)
        try await verify {
            try await mockAuthRepository.revokeAuth(sessionID: "session-to-logout")
        }.wasCalled(exactly: 1)
    }

    func testLogoutWhenNotAuthenticatedDoesNotCallRevoke() async {
        // Given
        sut.authState = .unauthenticated

        // When
        await sut.logout()

        // Then
        try await verify {
            try await mockAuthRepository.revokeAuth(sessionID: any())
        }.wasNeverCalled()
    }
}
