//
//  BiometricCredentialStore.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import Foundation
import Security

enum BiometricCredentialStore {
    private static let service = "lk.heliolanka.biometric.credentials"
    private static let usernameAccount = "username"
    private static let passwordAccount = "password"

    static func save(username: String, password: String) {
        set(username, account: usernameAccount)
        set(password, account: passwordAccount)
    }

    static func load() -> (username: String, password: String)? {
        guard let username = get(account: usernameAccount),
              let password = get(account: passwordAccount),
              !username.isEmpty, !password.isEmpty else { return nil }
        return (username, password)
    }

    static func clear() {
        delete(account: usernameAccount)
        delete(account: passwordAccount)
    }

    private static func set(_ value: String, account: String) {
        delete(account: account)
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
