import Foundation
import Security

final class KeychainServiceImpl: KeychainService {
    private let serviceName = "com.nasirimehr.DiscordLite"

    func save(key: String, value: String) -> Result<Void, KeychainServiceError> {
        guard let data = value.data(using: .utf8) else {
            return .failure(.failedToEncodeData)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item exists, update it
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key,
            ]

            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

            guard updateStatus == errSecSuccess else {
                return .failure(.failedToSaveItem)
            }
        } else if status != errSecSuccess {
            return .failure(.failedToSaveItem)
        }
        return .success(())
    }

    func retrieve(key: String) -> Result<String?, KeychainServiceError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return .success(nil)
        }

        guard status == errSecSuccess else {
            return .failure(.failedToFetchItem)
        }

        guard let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            return .failure(.failedToDecodeData)
        }

        return .success(value)
    }

    func delete(key: String) -> Result<Void, KeychainServiceError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound {
            // Already deleted, treat as success
            return .success(())
        }

        guard status == errSecSuccess else {
            return .failure(.failedToDeleteItem)
        }
        return .success(())
    }
}
