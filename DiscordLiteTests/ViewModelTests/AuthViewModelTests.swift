 import XCTest
 import SwiftMockk
 @testable import DiscordLite

 @MainActor
 final class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockAuthRepository: MockAuthRepository!
    var mockLoggerService: MockLoggerService!

    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        mockLoggerService = MockLoggerService()

        sut = AuthViewModel(
            authRepository: mockAuthRepository,
            logger: mockLoggerService
        )
    }

    override func tearDown() {
        sut = nil
        mockAuthRepository = nil
        mockLoggerService = nil
        super.tearDown()
    }

    func testInitialStateIsUnauthenticated() {
        // Then
        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testCheckExistingSessionWithValidSessionSetsAuthenticated() async {
        // Given
        let session: AuthSession? = AuthSession(
            sessionID: "valid-session",
        )

        await every {
            await mockAuthRepository.getStoredSession()
        }.returnsSuccess(session, failureType: AuthRepositoryError.self)

        // When
        await sut.checkExistingSession()

        // Then
        XCTAssertEqual(sut.state, .authenticated(session: session!))
    }

    func testCheckExistingSessionWithNoSessionSetsUnauthenticated() async {
        // Given
        await every {
            await mockAuthRepository.getStoredSession()
        }.returns(Result<AuthSession?, AuthRepositoryError>.success(nil))

        // When
        await sut.checkExistingSession()

        // Then
        XCTAssertEqual(sut.state, .unauthenticated)
    }

     // TODO: Skipping test because the actual implementation taps into native platform api for opening url, which should be abstracted away in order to be properly testable
    func skippedtestStartAuthUpdatesStateToAuthenticating() async {
        // Given
        let authURL = URL(string: "https://discord.com/oauth2/authorize?client_id=test")!
        let sessionID = "session-123"

        await every {
            await mockAuthRepository.initAuth()
        }.returnsSuccess((authURL: authURL, sessionID: sessionID), failureType: AuthRepositoryError.self)

        await every {
            await mockAuthRepository.pollAuthStatus(sessionID: any())
        }.returnsFailure(AuthRepositoryError.failedToFetchStatus, successType: AuthSession.self)

        // When
        await sut.startAuth()

        // Give polling a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(sut.state, .authenticating)
    }

    func testCancelAuthSetsStateToUnauthenticated() async {
        // Given
        sut.state = .authenticating

        // When
        sut.cancelAuth()

        // Then
        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testLogoutCallsRevokeAuthAndSetsUnauthenticated() async {
        // Given
        let session = AuthSession(
            sessionID: "session-to-logout",
        )
        sut.state = .authenticated(session: session)

        await every {
            await mockAuthRepository.revokeAuth(sessionID: any())
        }.returnsSuccess((), failureType: AuthRepositoryError.self)

        // When
        await sut.logout()

        // Then
        XCTAssertEqual(sut.state, .unauthenticated)
        await verify(times: .exactly(1)) {
            await mockAuthRepository.revokeAuth(sessionID: "session-to-logout")
        }
    }

    func testLogoutWhenNotAuthenticatedDoesNotCallRevoke() async {
        // Given
        sut.state = .unauthenticated

        // When
        await sut.logout()

        // Then
        await verify(times: .exactly(0)) {
            await mockAuthRepository.revokeAuth(sessionID: any())
        }
    }
 }
