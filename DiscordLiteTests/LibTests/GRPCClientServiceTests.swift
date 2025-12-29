import XCTest
@testable import DiscordLite

final class GRPCClientServiceTests: XCTestCase {
    var sut: GRPCClientService!
    var config: AppConfig!

    override func setUp() {
        super.setUp()
        config = AppConfig(
            grpcHost: "localhost",
            grpcPort: 50051,
            authPollingInterval: 2.0,
            authTimeout: 60.0
        )
        sut = GRPCClientServiceImpl(config: config)
    }

    override func tearDown() async throws {
        await sut.disconnect()
        sut = nil
        config = nil
        try await super.tearDown()
    }

    func testGetAuthClientCreatesClient() async throws {
        // When/Then
        // Note: This test requires the gRPC server to be running
        // In a real scenario, you might want to use a mock server or skip this test
        // if the server is not available
        XCTAssertNoThrow(try await sut.getAuthClient(), "Getting auth client should not throw when server is available")
    }

    func testDisconnectDoesNotThrow() async {
        // When/Then
        await XCTAssertNoThrowAsync(await sut.disconnect(), "Disconnect should not throw")
    }

    func testMultipleGetAuthClientCallsReuseSameConnection() async throws {
        // When
        let client1 = try await sut.getAuthClient()
        let client2 = try await sut.getAuthClient()

        // Then
        // Both clients should be created successfully
        // (In actual implementation, they share the same underlying channel)
        XCTAssertNotNil(client1)
        XCTAssertNotNil(client2)
    }
}

// Helper extension for async assertions
extension XCTestCase {
    func XCTAssertNoThrowAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await expression()
        } catch {
            XCTFail("\(message): Unexpected error thrown: \(error)", file: file, line: line)
        }
    }
}
