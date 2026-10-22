//
//  AuthViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-15.
//

import Foundation
import LocalAuthentication
import Observation


@MainActor
@Observable
final class LoginViewModel {
    var usernameOrEmail = ""
    var password = ""
    var isBusy = false
    var errorMessage: String?
    var biometricAvailable = false
    var biometricKind = BiometricAuthService.BiometricKind.none
    
    private let session: SessionManager
    
    init (session: SessionManager) {
        self.session = session
        refreshBiometricState()
    }
  
    func submit() async {
        errorMessage = nil
        let user = usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !user.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your username and password."
            return
        }
        isBusy = true
        defer { isBusy = false }
        session.rememberPendingLogin(username: user, password: password)
        do {
            let challenge = try await session.auth.login(
                usernameOrEmail: user,
                password: password
            )
            session.beginOtp(challenge: challenge, usernameHint: user)
        } catch {
            session.clearPendingCredentials()
            errorMessage = error.localizedDescription
        }
    }

    func refreshBiometricState() {
        biometricKind = BiometricAuthService.kind
        biometricAvailable = AppPreferences.shared.biometricLoginEnabled
            && biometricKind != .none
            && (BiometricCredentialStore.load() != nil || TokenStore.shared.load() != nil)
    }

    /// Unlock a saved session, or start password login with the Keychain credential.
    /// A cleared session still needs the emailed OTP.
    func submitWithBiometrics() async {
        errorMessage = nil
        isBusy = true
        defer {
            isBusy = false
            refreshBiometricState()
        }
        do {
            try await BiometricAuthService.authenticate(
                reason: "Sign in to HelioLanka with \(biometricKind.settingsLabel)"
            )
            if TokenStore.shared.load() != nil {
                let user = try await session.auth.me()
                session.apply(user: user, offerBiometrics: false)
                return
            }
            guard let creds = BiometricCredentialStore.load() else {
                errorMessage = "Sign in with your username and password once, then enable \(biometricKind.settingsLabel)."
                AppPreferences.shared.biometricLoginEnabled = false
                return
            }
            usernameOrEmail = creds.username
            password = creds.password
            session.rememberPendingLogin(username: creds.username, password: creds.password)
            let challenge = try await session.auth.login(
                usernameOrEmail: creds.username,
                password: creds.password
            )
            session.beginOtp(challenge: challenge, usernameHint: creds.username)
        } catch {
            errorMessage = friendlyBiometricError(error)
        }
    }

    private func friendlyBiometricError(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == "com.apple.LocalAuthentication", ns.code == LAError.userCancel.rawValue {
            return "\(biometricKind.settingsLabel) cancelled. Use your password."
        }
        return error.localizedDescription
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
