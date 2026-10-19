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
    
    init() {
        let client = APIClient()
        self.api = client
        self.auth = AuthService(client: client)
        self.installations = InstallationService(client: client)
        self.readings = ReadingService(client: client)
        self.dailyStore = DailyGenerationStore()
        self.weather = WeatherService(client: client)
        self.forecast = SolarForecastModel()
    }
    
    func bootstrap() async {
        lastError = nil
        guard TokenStore.shared.load() != nil else{
            phase = .unauthenticated
            return
        }
        do {
            let user = try await auth.me()
            apply(user:user)
        }catch {
            try? await auth.logout()
            phase = .unauthenticated
        }
    }
    
    func apply(user: UserMe){
        if user.isCustomer {
            let meters = user.allMeters
            if selectedMeterId.isEmpty || !meters.contains(where: { $0.meterId == selectedMeterId}){
                selectedMeterId = meters.first?.meterId ?? user.linkedMeterId ?? ""
            }
            phase = .customer(user)
        }else{
            phase = .staffBlocked(user)
        }
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
        phase = .unauthenticated
    }
    
}
