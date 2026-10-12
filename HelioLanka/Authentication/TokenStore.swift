//
//  TokenStore.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-12.
//

import Foundation
import Security

final class TokenStore: @unchecked Sendable {
    static let shared = TokenStore()
    
    private let service = "lk.heliolanka.tokens"
    private let accessAccount = "access"
    private let refreshAccount = "refresh"
    
    func save(access: String, refresh: String) {
        set(access, account: accessAccount)
        set(refresh, account: refreshAccount)
    }
    
    func load() -> (access: String, refresh: String)? {
        guard let a = get(account: accessAccount),
              let r = get(account: refreshAccount) else {return nil}
        return (a, r)
    }
    
    func clear() {
        delete(account: accessAccount)
        delete(account: refreshAccount)
    }
    
    private func set(_ value: String, account: String){
        delete(account: account)
        let data = Data(value.utf8)
        let quary: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(quary as CFDictionary, nil)
    }
    
    private func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil}
        return String(data: data, encoding: .utf8)
    }
    
    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
