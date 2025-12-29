import Foundation
//import SwiftMockk

enum KeychainServiceError: Error {
    case failedToEncodeData
    case failedToSaveItem
    case failedToFetchItem
    case failedToDecodeData
    case failedToDeleteItem
}

//@Mockable
protocol KeychainService {
    func save(key: String, value: String) -> Result<Void, KeychainServiceError>
    func retrieve(key: String) -> Result<String?, KeychainServiceError>
    func delete(key: String) -> Result<Void, KeychainServiceError>
}
