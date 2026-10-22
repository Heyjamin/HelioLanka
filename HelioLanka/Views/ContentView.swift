//
//  ContentView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI


struct ContentView: View {
    @Environment(SessionManager.self) private var session
    
    var body: some View {
        @Bindable var session = session
        let biometricLabel = BiometricAuthService.kind.settingsLabel

        ZStack {
            HelioBackground()
            switch session.phase {
            case .launching:
                ProgressView("Starting…")
            case .unauthenticated:
                LoginView(session: session)
            case .needsOtp(let challenge, _):
                OtpView(session: session, challenge: challenge)
            case .customer(let user):
                CustomerTabShell(user: user, session: session)
            case .staffBlocked(let user):
                staffBlocked(user)
            }
        }
        .alert(
            "Enable \(biometricLabel)?",
            isPresented: $session.showBiometricOffer
        ) {
            Button("Enable \(biometricLabel)") {
                Task { await session.enableBiometricLogin() }
            }
            Button("Not now", role: .cancel) {
                session.declineBiometricOffer()
            }
        } message: {
            Text("Next time you can use \(biometricLabel) instead of typing your password. Not now leaves password sign-in as it is. You can accept this only after another sign-in.")
        }
    }

    
//    private func signedIn(_ user: UserMe) -> some View {
//        VStack(alignment: .leading, spacing: 12){
//            Text("Signed in")
//                .font(.system(size:28, weight: .bold, design: .rounded))
//                .foregroundStyle(HelioTheme.navy)
//            Text(user.displayName)
//                .font(.title3)
//            Text(user.email)
//                .foregroundStyle(HelioTheme.inkMuted)
//            Text("Meters: \(user.allMeters.count)")
//            Text("Phase 4 complete")
//                .font(.footnote.weight(.semibold))
//                .foregroundStyle(HelioTheme.leaf)
//            Button("sign out"){
//                Task {await session.signOut() }
//            }
//            .buttonStyle(.bordered)
//        }
//        .padding(HelioTheme.screenPadding)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//    }
    
    private func staffBlocked(_ user: UserMe) -> some View {
        VStack(alignment: .leading, spacing: 12){
            Text ("This app is for customers.")
                .font(.title2.bold())
                .foregroundStyle(HelioTheme.navy)
            Text("\(user.username) is \(user.role). Use the web admin.")
                .foregroundStyle(HelioTheme.inkMuted)
            Button("Sign out"){
                Task { await session.signOut()}
            }
        }
        .padding(HelioTheme.screenPadding)
    }
}


//struct ContentView: View {
//    
//    @Environment(SessionManager.self) private var session
//    
//    var body: some View {
//        @Bindable var session = session
//        
//        ZStack {
//            HelioBackground()
//            
//            ScrollView{
//                VStack(spacing:16){
//                    Text("HelioLanka")
//                        .font(.system(size:34, weight:.bold, design:.rounded))
//                        .foregroundStyle(HelioTheme.navy)
//                    
//                    Text ("Phase 03 - Auth services")
//                        .font(.subheadline.weight(.semibold))
//                        .foregroundStyle(HelioTheme.ocean)
//                    
//                    phaseCard
//                    
//                    if let err = session.lastError {
//                        Text(err)
//                            .font(.footnote)
//                            .foregroundStyle(HelioTheme.danger)
//                            .padding(12)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .background(Color.red.opacity(0.08), in:RoundedRectangle(cornerRadius: 12))
//                    }
//                    
//                    switch session.phase{
//                    case .launching:
//                        ProgressView("Starting...")
//                        
//                    case .unauthenticated:
//                        TextField("Username", text: $session.debugUsername)
//                            .textInputAutocapitalization(.never)
//                            .autocorrectionDisabled()
//                            .padding(12)
//                            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
//                        SecureField("Password", text: $session.debugPassword)
//                            .padding(12)
//                            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
//                        Button("1) Login → OTP challenge"){
//                            Task { await session.debugLogin()}
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(HelioTheme.ocean)
//                        
//                    case .needsOtp(let challenge, let hint):
//                        Text("User: \(hint)")
//                            .foregroundStyle(HelioTheme.navy)
//                        Text("OTP sent to \(challenge.emailMasked)")
//                            .foregroundStyle(HelioTheme.inkMuted)
//                        Text(challenge.message)
//                            .font(.footnote)
//                            .foregroundStyle(HelioTheme.inkMuted)
//                        
//                        TextField("6-Digit OTP", text: $session.debugOtp)
//                            .keyboardType(.numberPad)
//                            .padding(12)
//                            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius:12))
//                        
//                        Button ("2) Verigy OTP") {
//                            Task {await session.debugVerifyOtp()}
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(HelioTheme.leaf)
//                        
//                        Button("Back"){
//                            Task {await session.signOut()}
//                        }
//                        
//                    case .customer(let user):
//                        Text ("Signed in as \(user.displayName)")
//                            .font(.headline)
//                            .foregroundStyle(HelioTheme.navy)
//                        Text("Role: \(user.role)")
//                        Text("Meters: \(user.allMeters.count)")
//                        Text("Selected meter: \(session.selectedMeterId.isEmpty ? "-" : session.selectedMeterId)")
//                        Text("Phase 03 colplete ✅")
//                            .foregroundStyle(HelioTheme.leaf)
//                            .padding(.top, 8)
//                        
//                        Button("Sign out"){
//                            Task {await session.signOut() }
//                        }
//                    case .staffBlocked(let user):
//                        Text("Staff account (\(user.role)) - use the web admin.")
//                            .foregroundStyle(HelioTheme.navy)
//                        Button("Sign out"){
//                            Task { await session.signOut()}
//                        }
//                    }
//                }
//                .padding(HelioTheme.screenPadding)
//            }
//        }
//    }
//    
//    private var phaseCard: some View {
//        Text(phaseLabel)
//            .font(.footnote.monospaced())
//            .foregroundStyle(HelioTheme.navy)
//            .padding(12)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(Color.white.opacity (0.7), in: RoundedRectangle(cornerRadius: 12))
//    }
//    
//    private var phaseLabel: String {
//        switch session.phase{
//        case .launching: return "phase = launching"
//        case .unauthenticated: return " phase = unauthenticated"
//        case .needsOtp: return "Phase = needsOtp"
//        case .customer: return "phase = customer"
//        case .staffBlocked: return "phase = staffBlocked"
//        }
//    }
//}

