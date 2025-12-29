import XCTest
@testable import DiscordLite

final class KeychainServiceTests: XCTestCase {
    var sut: KeychainService!

    override func setUp() {
        super.setUp()
        sut = KeychainServiceImpl()
    }

    override func tearDown() {
        // Clean up any test data
        try? sut.delete(key: "test_key")
        try? sut.delete(key: "test_key_2")
        sut = nil
        super.tearDown()
    }

    func testSaveAndRetrieve() throws {
        // Given
        let key = "test_key"
        let value = "test_value"

        // When
        try sut.save(key: key, value: value)
        let retrieved = try sut.retrieve(key: key)

        // Then
        XCTAssertEqual(retrieved, value, "Retrieved value should match saved value")
    }

    func testRetrieveNonExistentKey() throws {
        // Given
        let key = "non_existent_key"

        // When
        let retrieved = try sut.retrieve(key: key)

        // Then
        XCTAssertNil(retrieved, "Non-existent key should return nil")
    }

    func testUpdateExistingKey() throws {
        // Given
        let key = "test_key"
        let originalValue = "original_value"
        let updatedValue = "updated_value"

        // When
        try sut.save(key: key, value: originalValue)
        try sut.save(key: key, value: updatedValue)
        let retrieved = try sut.retrieve(key: key)

        // Then
        XCTAssertEqual(retrieved, updatedValue, "Updated value should be retrieved")
    }

    func testDeleteExistingKey() throws {
        // Given
        let key = "test_key"
        let value = "test_value"
        try sut.save(key: key, value: value)

        // When
        try sut.delete(key: key)
        let retrieved = try sut.retrieve(key: key)

        // Then
        XCTAssertNil(retrieved, "Deleted key should return nil")
    }

    func testDeleteNonExistentKey() throws {
        // Given
        let key = "non_existent_key"

        // When/Then
        XCTAssertNoThrow(try sut.delete(key: key), "Deleting non-existent key should not throw")
    }

    func testMultipleKeys() throws {
        // Given
        let key1 = "test_key"
        let value1 = "test_value_1"
        let key2 = "test_key_2"
        let value2 = "test_value_2"

        // When
        try sut.save(key: key1, value: value1)
        try sut.save(key: key2, value: value2)

        // Then
        let retrieved1 = try sut.retrieve(key: key1)
        let retrieved2 = try sut.retrieve(key: key2)
        XCTAssertEqual(retrieved1, value1)
        XCTAssertEqual(retrieved2, value2)
    }
}
