//
//  AuthServide.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-12.
//

import Foundation

actor AuthService {
    private let client: APIClient
    
    init(client: APIClient){
        self.client = client
    }
    
    func register(_ body: RegisterBody) async throws -> UserMe {
        try await client.request(
            "/api/vq/auth/register",
            method: .post,
            body: body,
            auth: false
        )
    }
    
    func login(usernameOrEmail: String, password: String) async throws -> LoginChallenge {
        try await client.request(
            "/api/v1/auth/login",
            method: .post,
            body: LoginBody(usernameOrEmail: usernameOrEmail, password: password),
            auth: false
        )
    }
    
    func verifyOtp(challengeCode: String, otp: String) async throws -> TokenResponse {
        let tokens: TokenResponse = try await client.request(
            "api/v1/auth/otp/verify",
            method: .post,
            body: OtpVerifyBody(challengeCode: challengeCode, otp: otp),
            auth: false
        )
        await client.setTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
        return tokens
    }
    
    func resendOtp(challengeCode: String) async throws -> LoginChallenge {
        try await client.request(
            "/api/v1/auth/otp/resend",
            method: .post,
            body: OtpResendBody(challengeCode: challengeCode),
            auth: false
        )
    }
    
    func me() async throws -> UserMe{
        try await client.request ("/api/v1/auth/me")
    }

    
    func logout() async throws {
        struct Body: Encodable { let refreshToken: String? }
        let refresh = TokenStore.shared.load()?.refresh
        _ = try? await client.request(
            "api/v1/auth/logout",
            method: .post,
            body: Body(refreshToken: refresh)
        ) as EmptyResponse
            await client.setTokens(access: nil, refresh: nil)
    }
    
}
