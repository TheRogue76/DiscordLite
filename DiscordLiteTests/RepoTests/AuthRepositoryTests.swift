 import XCTest
 import SwiftMockk
 @testable import DiscordLite
import Foundation

 final class AuthRepositoryTests: XCTestCase {
     var sut: AuthRepository!
     var mockAuthGrpcDataSource: MockAuthGRPCDatasource!
     var mockKeychain: MockKeychainService!
     var mockLogger: MockLoggerService!
     
     override func setUp() {
         super.setUp()
         mockAuthGrpcDataSource = MockAuthGRPCDatasource()
         mockKeychain = MockKeychainService()
         mockLogger = MockLoggerService()
         
         sut = AuthRepositoryImpl(
            authGRPCDataSource: mockAuthGrpcDataSource,
            keychain: mockKeychain,
            logger: mockLogger
         )
     }
     
     override func tearDown() {
         sut = nil
         mockAuthGrpcDataSource = nil
         mockKeychain = nil
         mockLogger = nil
         super.tearDown()
     }

    func testInitAuthReturnsURLAndSessionID() async throws {
        // Given
        let expectedURL = URL(string: "https://discord.com/oauth2/authorize?client_id=test")!
        let expectedSessionID = "test-session-123"

        // When
        await every {
            await mockAuthGrpcDataSource.getAuthUrl()
        }.returnsSuccess((url: expectedURL, sessionId: expectedSessionID), failureType: AuthGRPCDatasourceError.self)

        // Then
        let (authURL, sessionID) = try await sut.initAuth().get()

        XCTAssertEqual(authURL, expectedURL)
        XCTAssertEqual(sessionID, expectedSessionID)
    }

    func testGetStoredSessionReturnsNilWhenNoSession() async throws {
        // Given
        await every {
            mockKeychain.retrieve(key: any())
        }.returns(Result<String?, KeychainServiceError>.success(nil))

        // When
        let session = try await sut.getStoredSession().get()

        // Then
        XCTAssertNil(session)
    }

    func testGetStoredSessionReturnsSessionWhenExists() async throws {
        // Given
        let sessionID: String? = "stored-session-123"

        await every {
            mockKeychain.retrieve(key: any())
        }.returnsSuccess(sessionID, failureType: KeychainServiceError.self)

        // When
        let session = try await sut.getStoredSession().get()

        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.sessionID, sessionID)
    }

    func testRevokeAuthCallsClearSession() async throws {
        // Given
        let sessionID = "session-to-revoke"

        await every {
            await mockAuthGrpcDataSource.revokeAuth(sessionId: any())
        }.returnsSuccess(false, failureType: AuthGRPCDatasourceError.self)

        await every {
            mockKeychain.delete(key: any())
        }.returnsSuccess((), failureType: KeychainServiceError.self)

        // When
        try await sut.revokeAuth(sessionID: sessionID).get()

        // Then
        await verify(times: .atLeast(1)) {
            mockKeychain.delete(key: "discord_session_id")
        }
    }
 }
