//
//  AuthViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-15.
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var usernameOrEmail = ""
    var password = ""
    var isBusy = false
    var errorMessage: String?
    
    private let session: SessionManager
    
    init (session: SessionManager) {
        self.session = session
    }
    
    func submit() async {
        errorMessage = nil
        let user = usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !user.isEmpty, !password.isEmpty else{
            errorMessage = "Enter your username and password."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let challenge = try await session.auth.login(
                usernameOrEmail: user,
                password: password
            )
            session.beginOtp(challenge: challenge, usernameHint: user)
        }catch{
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class RegisterViewModel {
    var accountNumber = ""
    var username = ""
    var email = ""
    var phone = ""
    var firstName = ""
    var lastName = ""
    var password = ""
    var isBusy = false
    var errorMessage : String?
    var successMessage: String?
    
    private let session: SessionManager
    
    init(session: SessionManager){
        self.session = session
    }
    
    func submit() async {
        errorMessage = nil
        successMessage = nil
        let account = accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard account.count == 10, account.allSatisfy(\.isNumber) else {
            errorMessage = "Account number must be exactly 10 digits."
            return
        }
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty else{
            errorMessage = "Email, password, and name are required."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await session.auth.register(
                RegisterBody(
                    accountNumber: account,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    phone: phone.isEmpty ? nil : phone,
                    username: username.isEmpty ? nil : username.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            successMessage = "Registered. Close this sheet and sign in. The App will email an OTP."
        }catch{
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class OtpViewModel {
    var otp = ""
    var isBusy = false
    var errorMessage: String?
    var infoMessage: String
    
    let challenge: LoginChallenge
    private let session: SessionManager
    
    init (session: SessionManager, challenge: LoginChallenge){
        self.session = session
        self.challenge = challenge
        self.infoMessage = "Code sent to \(challenge.emailMasked). \(challenge.message)"
    }
    
    func verify() async {
        errorMessage = nil
        let code = otp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            errorMessage = "Enter the 6-digit code."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await session.auth.verifyOtp(
                challengeCode: challenge.challengeCode,
                otp: code
            )
            let user = try await session.auth.me()
            session.apply(user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resend() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            let next = try await session.auth.resendOtp(challengeCode: challenge.challengeCode)
            infoMessage = "New code sent to \(next.emailMasked)."
            otp = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
