//
//  BiometricAuthService.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import Foundation
import LocalAuthentication

enum BiometricAuthService {
    enum BiometricKind {
        case faceID
        case touchID
        case opticID
        case none

        var buttonTitle: String {
            switch self {
            case .faceID: return "Sign in with Face ID"
            case .touchID: return "Sign in with Touch ID"
            case .opticID: return "Sign in with Optic ID"
            case .none: return "Sign in with biometrics"
            }
        }

        var systemImage: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            case .none: return "lock.shield"
            }
        }

        var settingsLabel: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none: return "Biometrics"
            }
        }
    }

    static var kind: BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .none: return .none
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .none
        }
    }

    static var isAvailable: Bool { kind != .none }

    @MainActor
    static func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? LAError(.biometryNotAvailable)
        }
        try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}
