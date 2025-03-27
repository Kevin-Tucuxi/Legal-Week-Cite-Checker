import Foundation
import Security

enum SecureStorageError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
}

class SecureStorageService {
    static let shared = SecureStorageService()
    
    private let service = "com.legalweek.citechecker"
    private let account = "courtlistener.api.token"
    
    private init() {}
    
    func saveAPIToken(_ token: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: token.data(using: .utf8)!
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecureStorageError.unknown(updateStatus)
            }
            return
        }
        
        guard status == errSecSuccess else {
            throw SecureStorageError.unknown(status)
        }
    }
    
    func getAPIToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.itemNotFound
        }
        
        return token
    }
    
    func deleteAPIToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.unknown(status)
        }
    }
    
    func hasAPIToken() -> Bool {
        do {
            _ = try getAPIToken()
            return true
        } catch {
            return false
        }
    }
} 