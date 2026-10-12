//
//  APIModels.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-12.
//

import Foundation

// MARK: - Request bodies

struct RegisterBody: Encodable {
    let accountNumber: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String?
    let username: String?
}

struct LoginBody: Encodable {
    let usernameOrEmail: String
    let password: String
}

struct OtpVerifyBody: Encodable {
    let challengeCode: String
    let otp: String
}

struct OtpResendBody: Encodable {
    let challengeCode: String
}

// MARK: - Responses

struct LoginChallenge: Decodable, Equatable {
    let challengeCode: String
    let emailMasked: String
    let phoneMasked: String
    let expiresAtUtc: Date
    let message: String
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAtUtc: Date
    let refreshTokenExpiresAtUtc: Date
    let tokenType: String?
}

struct LinkedMeter: Decodable, Identifiable, Hashable {
    var id: String { meterId }
    let meterId: String
    let installationName: String
}

struct LinkedAccount: Decodable, Identifiable, Hashable {
    var id: String { accountNumber }
    let accountNumber: String
    let meters: [LinkedMeter]
}

struct UserMe: Decodable, Equatable {
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let role: String
    let provinceCode: String?
    let districtCode: String?
    let substationCode: String?
    let linkedMeterId: String?
    let linkedAccountNumber: String?
    let linkedAccounts: [LinkedAccount]?
    let isActive: Bool
    let lastLoginAtUtc: Date?

    var isCustomer: Bool { role.lowercased() == "customer" }

    var allMeters: [LinkedMeter] {
        linkedAccounts?.flatMap(\.meters) ?? []
    }

    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? username : full
    }
}
