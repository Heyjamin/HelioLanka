//
//  AuthViews.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-15.
//

import SwiftUI

struct HelioPasswordField: View {
    var title: String = "Password"
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 8){
            Group {
                if isVisible {
                    TextField(title, text: $text)
                }else{
                    SecureField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.password)
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(HelioTheme.inkMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .helioField()
    }
}


extension View {
    func helioField() -> some View {
        self
            .padding(12)
            .background(HelioTheme.surface, in: RoundedRectangle(cornerRadius: HelioTheme.fieldRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HelioTheme.fieldRadius, style: .continuous)
                    .strokeBorder(HelioTheme.hairline, lineWidth: 1)
            )
    }
}


struct LoginView: View {
    private let session: SessionManager
    @State private var vm: LoginViewModel
    @State private var showRegister = false
    
    init(session: SessionManager){
        self.session = session
        _vm = State(initialValue: LoginViewModel(session:session))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20){
                HelioBrandLockup(height: 56)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)

                Text("Your rooftop solar, elevated.")
                    .font(.subheadline)
                    .foregroundStyle(HelioTheme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12){
                    Text("Sign in")
                        .font(.headline)
                        .foregroundStyle(HelioTheme.navy)
                    
                    TextField("Username or email", text: $vm.usernameOrEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .helioField()
                    
                    HelioPasswordField(text: $vm.password)
                    
                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                    
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        if vm.isBusy {
                            ProgressView().tint(.white)
                        }else{
                            Text("Continue")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isBusy)
                    
                    if vm.biometricAvailable {
                        Button {
                            Task { await vm.submitWithBiometrics() }
                        } label: {
                            Label(vm.biometricKind.buttonTitle, systemImage: vm.biometricKind.systemImage)
                        }
                        .buttonStyle(.bordered)
                        .tint(HelioTheme.navy)
                        .disabled(vm.isBusy)
                    }

                }
                .padding(HelioTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                        .fill(HelioTheme.surface)
                        .shadow(color: HelioTheme.cardShadow, radius: 16, y: 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                        .strokeBorder(HelioTheme.hairline, lineWidth: 1)
                )
                
                Button ("Create customer account"){
                    showRegister = true
                }
                .foregroundStyle(HelioTheme.ocean)
            }
            .padding(HelioTheme.screenPadding)
        }
        .sheet(isPresented: $showRegister){
            RegisterView(session:session)
        }
        .onAppear { vm.refreshBiometricState() }
    }
}

struct RegisterView: View {
    @Environment(\.dismiss) private var dismis
    @State private var vm: RegisterViewModel
    
    init(session: SessionManager){
        _vm = State(initialValue: RegisterViewModel(session:session))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12){
                    HelioBrandLockup(height: 44)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    TextField("10-digit account number", text: $vm.accountNumber)
                        .keyboardType(.numberPad)
                        .helioField()
                    TextField("Username (optional)", text: $vm.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .helioField()
                    TextField("Email", text:$vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .helioField()
                    TextField("Phone (optional)", text: $vm.phone)
                        .keyboardType(.phonePad)
                        .helioField()
                    TextField("First name", text: $vm.firstName)
                        .helioField()
                    TextField("Last name", text: $vm.lastName)
                        .helioField()
                    HelioPasswordField(text: $vm.password)
                    
                    if let err = vm.errorMessage {
                        Text(err).font(.footnote).foregroundStyle(HelioTheme.danger)
                    }
                    if let ok = vm.successMessage {
                        Text(ok).font(.footnote).foregroundStyle(HelioTheme.leaf)
                    }
                    
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        if vm.isBusy { ProgressView() } else {Text("Register") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isBusy)
                }
                .padding(HelioTheme.screenPadding)
            }
            .background(HelioBackground())
            .navigationTitle("Create account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button("Close"){
                        dismis()
                    }
                }
            }
        }
    }
}

struct OtpView : View {
    @State private var vm: OtpViewModel
    private let session: SessionManager
    
    init (session: SessionManager, challenge: LoginChallenge){
        self.session = session
        _vm = State(initialValue: OtpViewModel(session: session, challenge: challenge))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16){
                HelioBrandLockup(height: 56)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)

                Text("Enter your code")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(HelioTheme.navy)
                    .frame(maxWidth: .infinity)

                Text(vm.infoMessage)
                    .font(.subheadline)
                    .foregroundStyle(HelioTheme.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                OtpCodeBoxes(code: $vm.otp)
                
                if let err = vm.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(HelioTheme.danger)
                }
                
                Button {
                    Task { await vm.verify () }
                } label: {
                    if vm.isBusy { ProgressView().tint(.white)} else {
                        Text ("Verify")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isBusy)
                
                Button ("Resend code"){
                    Task {await vm.resend()}
                }
                .disabled(vm.isBusy)
                
                Button("Back to sign in"){
                    Task { await session.signOut()}
                }
                .foregroundStyle(HelioTheme.inkMuted)
            }
            .padding(HelioTheme.screenPadding)
        }
    }
}

struct OtpCodeBoxes: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.02)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    code = String(digits.prefix(6))
                }

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    box(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("One-time code, \(code.count) of 6 digits")
    }

    private func box(at index: Int) -> some View {
        let digits = Array(code)
        let glyph = index < digits.count ? String(digits[index]) : ""
        let isActive = isFocused && index == min(code.count, 5)

        return Text(glyph)
            .font(.title2.monospacedDigit().weight(.bold))
            .foregroundStyle(HelioTheme.navy)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(HelioTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isActive ? HelioTheme.brandTeal : HelioTheme.hairline, lineWidth: isActive ? 2 : 1)
            }
    }
}

