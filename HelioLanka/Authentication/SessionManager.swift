//
//  SessionManager.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-12.
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionManager{
    enum Phase: Equatable {
        case launching
        case unauthenticated
        case needsOtp(challenge: LoginChallenge, usernameHint:String)
        case customer(UserMe)
        case staffBlocked(UserMe)
    }
    
    private(set) var phase: Phase = .launching
    var selectedMeterId: String = ""
    /// Held only until the Face ID offer is answered. Never written to UserDefaults.
    var pendingLoginUsername: String?
    var pendingLoginPassword: String?
    var showBiometricOffer = false
    var lastError: String?
    
    //    Temporary debug fields for Phase 03 (replaced by proper forms in Phase 04).
    //    var debugUsername = "customer"
    //    var debugPassword = "Customer@12345"
    //    var debugOtp = ""
    
    let api: APIClient
    let auth: AuthService
    let installations: InstallationService
    let readings: ReadingService
    let dailyStore: DailyGenerationStore
    let weather: WeatherService
    let forecast: SolarForecastModel
    let noteStore: CalendarNoteStore
    let notifications: NotificationService
    let calendar: CalendarService
    let profile: ProfileService
    let leaderboard: LeaderboardService

    
    init() {
        let client = APIClient()
        self.api = client
        self.auth = AuthService(client: client)
        self.installations = InstallationService(client: client)
        self.readings = ReadingService(client: client)
        self.dailyStore = DailyGenerationStore()
        self.weather = WeatherService(client: client)
        self.forecast = SolarForecastModel()
        self.noteStore = CalendarNoteStore()
        self.notifications = NotificationService()
        self.calendar = CalendarService()
        self.profile = ProfileService(client: client)
        self.leaderboard = LeaderboardService(client: client)
    }
    
    func bootstrap() async {
        lastError = nil
        guard TokenStore.shared.load() != nil else{
            phase = .unauthenticated
            return
        }
        
        if AppPreferences.shared.biometricLoginEnabled, BiometricAuthService.isAvailable {
            do {
                try await BiometricAuthService.authenticate(
                    reason: "Unlock HelioLanka with \(BiometricAuthService.kind.settingsLabel)"
                )
            } catch {
                phase = .unauthenticated
                return
            }
        }

        do {
            let user = try await auth.me()
            apply(user: user, offerBiometrics: false)
        }catch {
            try? await auth.logout()
            phase = .unauthenticated
        }
        
        let prefs = AppPreferences.shared
        await notifications.applyDailySummary(
            enabled: prefs.notificationsEnabled && prefs.dailySummaryEnabled,
            hour: prefs.dailySummaryHour,
            minute: prefs.dailySummaryMinute
        )
    }
    
    func apply(user: UserMe, offerBiometrics: Bool = true) {
        if user.isCustomer {
            let meters = user.allMeters
            if selectedMeterId.isEmpty || !meters.contains(where: { $0.meterId == selectedMeterId }) {
                selectedMeterId = meters.first?.meterId ?? user.linkedMeterId ?? ""
            }
            phase = .customer(user)
            if offerBiometrics,
               !AppPreferences.shared.biometricLoginEnabled,
               BiometricAuthService.isAvailable,
               pendingLoginUsername != nil,
               pendingLoginPassword != nil {
                showBiometricOffer = true
            } else {
                clearPendingCredentials()
            }
        } else {
            clearPendingCredentials()
            phase = .staffBlocked(user)
        }
    }

    func rememberPendingLogin(username: String, password: String) {
        pendingLoginUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingLoginPassword = password
    }

    func enableBiometricLogin() async {
        guard let user = pendingLoginUsername, let pass = pendingLoginPassword else {
            showBiometricOffer = false
            return
        }
        do {
            try await BiometricAuthService.authenticate(
                reason: "Enable \(BiometricAuthService.kind.settingsLabel) for HelioLanka"
            )
            BiometricCredentialStore.save(username: user, password: pass)
            AppPreferences.shared.biometricLoginEnabled = true
            clearPendingCredentials()
            showBiometricOffer = false
        } catch {
            showBiometricOffer = true
        }
    }

    func declineBiometricOffer() {
        clearPendingCredentials()
        showBiometricOffer = false
    }

    func clearPendingCredentials() {
        pendingLoginUsername = nil
        pendingLoginPassword = nil
    }

    func beginOtp(challenge: LoginChallenge, usernameHint: String){
        phase = .needsOtp(challenge: challenge, usernameHint: usernameHint)
    }
    
    
    
//    func debugLogin() async {
//        lastError = nil
//        do{
//            let user = debugUsername.trimmingCharacters(in: .whitespacesAndNewlines)
//            let challenge = try await auth.login(usernameOrEmail: user, password: debugPassword)
//            beginOtp(challenge: challenge, usernameHint: user)
//        }catch{
//            lastError = error.localizedDescription
//            phase = .unauthenticated
//        }
//    }
    
//    func debugVerifyOtp() async {
//        lastError = nil
//        guard case .needsOtp(let challenge, _) = phase else {
//            return
//        }
//        do {
//            _ = try await auth.verifyOtp(
//                challengeCode: challenge.challengeCode,
//                otp: debugOtp.trimmingCharacters(in: .whitespacesAndNewlines)
//            )
//            let user = try await auth.me()
//            apply (user: user)
//            
//        } catch{
//            lastError = error.localizedDescription
//        }
//
//    }
    
    func signOut() async {
        try? await auth.logout()
        selectedMeterId = ""
        // debugOtp = ""
        clearPendingCredentials()
        showBiometricOffer = false
        phase = .unauthenticated
    }
    
}
