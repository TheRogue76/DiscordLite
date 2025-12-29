import XCTest
import SwiftMockk
@testable import DiscordLite

final class AuthRepositoryTests: XCTestCase {
    var sut: AuthRepository!
    var mockGRPCClient: MockGRPCClientService!
    var mockKeychain: MockKeychainService!
    var mockLogger: MockLoggerService!

    override func setUp() {
        super.setUp()
        mockGRPCClient = MockGRPCClientService()
        mockKeychain = MockKeychainService()
        mockLogger = MockLoggerService()

        sut = AuthRepositoryImpl(
            grpcClient: mockGRPCClient,
            keychain: mockKeychain,
            logger: mockLogger
        )
    }

    override func tearDown() {
        sut = nil
        mockGRPCClient = nil
        mockKeychain = nil
        mockLogger = nil
        super.tearDown()
    }

    func testInitAuthReturnsURLAndSessionID() async throws {
        // Given
        let expectedURL = URL(string: "https://discord.com/oauth2/authorize?client_id=test")!
        let expectedSessionID = "test-session-123"

        // Create a mock auth client
        let mockAuthClient = MockAuthServiceAsyncClient()

        // When
        try await every {
            try await mockGRPCClient.getAuthClient()
        }.returns(mockAuthClient)

        try await every {
            try await mockAuthClient.initAuth(any())
        }.returns(InitAuthResponse.with {
            $0.authURL = expectedURL.absoluteString
            $0.sessionID = expectedSessionID
        })

        // Then
        let (authURL, sessionID) = try await sut.initAuth()

        XCTAssertEqual(authURL, expectedURL)
        XCTAssertEqual(sessionID, expectedSessionID)
    }

    func testSaveSessionStoresInKeychain() async throws {
        // Given
        let session = AuthSession(
            sessionID: "test-session",
            createdAt: Date(),
            expiresAt: nil
        )

        try await every {
            try mockKeychain.save(key: any(), value: any())
        }.returns(())

        // When
        try await sut.saveSession(session)

        // Then
        try await verify {
            try mockKeychain.save(key: "discord_session_id", value: "test-session")
        }.wasCalled(exactly: 1)
    }

    func testGetStoredSessionReturnsNilWhenNoSession() async throws {
        // Given
        try await every {
            try mockKeychain.retrieve(key: any())
        }.returns(nil)

        // When
        let session = try await sut.getStoredSession()

        // Then
        XCTAssertNil(session)
    }

    func testGetStoredSessionReturnsSessionWhenExists() async throws {
        // Given
        let sessionID = "stored-session-123"

        try await every {
            try mockKeychain.retrieve(key: any())
        }.returns(sessionID)

        // When
        let session = try await sut.getStoredSession()

        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.sessionID, sessionID)
    }

    func testClearSessionDeletesFromKeychain() async throws {
        // Given
        try await every {
            try mockKeychain.delete(key: any())
        }.returns(())

        // When
        try await sut.clearSession()

        // Then
        try await verify {
            try mockKeychain.delete(key: "discord_session_id")
        }.wasCalled(exactly: 1)
    }

    func testRevokeAuthCallsClearSession() async throws {
        // Given
        let sessionID = "session-to-revoke"
        let mockAuthClient = MockAuthServiceAsyncClient()

        try await every {
            try await mockGRPCClient.getAuthClient()
        }.returns(mockAuthClient)

        try await every {
            try await mockAuthClient.revokeAuth(any())
        }.returns(RevokeAuthResponse())

        try await every {
            try mockKeychain.delete(key: any())
        }.returns(())

        // When
        try await sut.revokeAuth(sessionID: sessionID)

        // Then
        try await verify {
            try mockKeychain.delete(key: "discord_session_id")
        }.wasCalled(atLeast: 1)
    }
}
