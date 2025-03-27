// SecureStorageService handles the secure storage and retrieval of sensitive data,
// specifically the CourtListener API token. It uses the iOS Keychain to ensure
// the token is stored securely and can't be accessed by other apps.

import Foundation
import Security

// Possible errors that can occur when working with secure storage
enum SecureStorageError: Error {
    case duplicateEntry    // When trying to save an item that already exists
    case unknown(OSStatus) // When an unexpected Keychain error occurs
    case itemNotFound      // When trying to retrieve an item that doesn't exist
}

class SecureStorageService {
    // A shared instance that can be used throughout the app
    static let shared = SecureStorageService()
    
    // The service identifier used in the Keychain
    private let service = "com.legalweek.citechecker"
    // The account identifier used in the Keychain
    private let account = "courtlistener.api.token"
    
    // Private initializer to ensure we only use the shared instance
    private init() {}
    
    // Saves the API token to the Keychain
    // If the token already exists, it will be updated instead
    func saveAPIToken(_ token: String) throws {
        // Create the query dictionary for the Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // Try to add the item to the Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // If the item already exists, update it instead
        guard status != errSecDuplicateItem else {
            // Create a query to find the existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            // Create the attributes to update
            let attributes: [String: Any] = [
                kSecValueData as String: token.data(using: .utf8)!
            ]
            
            // Update the existing item
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecureStorageError.unknown(updateStatus)
            }
            return
        }
        
        // Check if the add operation was successful
        guard status == errSecSuccess else {
            throw SecureStorageError.unknown(status)
        }
    }
    
    // Retrieves the API token from the Keychain
    func getAPIToken() throws -> String {
        // Create the query dictionary for the Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        // Try to retrieve the item from the Keychain
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Check if the retrieval was successful and convert the data to a string
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.itemNotFound
        }
        
        return token
    }
    
    // Deletes the API token from the Keychain
    func deleteAPIToken() throws {
        // Create the query dictionary for the Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Try to delete the item from the Keychain
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.unknown(status)
        }
    }
    
    // Checks if an API token exists in the Keychain
    func hasAPIToken() -> Bool {
        do {
            _ = try getAPIToken()
            return true
        } catch {
            return false
        }
    }
} 