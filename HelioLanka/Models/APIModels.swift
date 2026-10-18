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

struct Installation: Decodable, Identifiable, Hashable {
    var id: String {meterId}
    let meterId: String
    let accountNumber: String
    let inverterId: String?
    let substationCode: String
    let installationName: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let capacityKw: Double
    let tariffRate: Double
    let commissionedAtUtc: Date?
    let status: String
    
}

struct ReadingBrief: Decodable {
    let timestampUtc: Date
    let cumulativeExportKwh: Double
    let intervalExportKwh: Double
    let instantaneousPowerKw: Double?
}

struct NamedCode: Decodable {
    let code: String
    let name: String
}

struct InstallationComposite: Decodable {
    let installation: Installation
    let substation: NamedCode
    let district: NamedCode
    let province: NamedCode
    let lastReading: ReadingBrief?
}

struct ReadingRow: Decodable, Identifiable {
    var id: String {"\(meterId ?? "")-\(timestampUtc.timeIntervalSince1970)"}
    let meterId: String?
    let timestampUtc: Date
    let cumulativeExportKwh: Double
    let intervalExportKwh: Double
    let instantaneousPowerKw: Double?
}

struct PageResult<T: Decodable>: Decodable{
    let data: [T]
    let offset: Int?
    let limit: Int?
    let count: Int?
}

struct WeatherPoint: Decodable {
    let timeUtc: Date
    let temperatureC: Double?
    let cloudCoverPercent: Double?
    let shortwaveRadiationWm2:Double?
    let precipitationMm: Double?
}

struct WeatherForecast: Decodable {
    let meterId: String
    let latitude: Double
    let longitude: Double
    let provider: String?
    let hourly: [WeatherPoint]
}
