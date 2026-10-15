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
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: HelioTheme.fieldRadius))
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
                Text("HelioLanka")
                    .font(.system(size:34, weight: .bold, design: .rounded))
                    .foregroundStyle(HelioTheme.navy)
                Text("Your rooftop solar, elevated.")
                    .foregroundStyle(HelioTheme.inkMuted)
                
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
                            .foregroundStyle(.red)
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
                    .buttonStyle(.borderedProminent)
                    .tint(HelioTheme.ocean)
                    .disabled(vm.isBusy)
                }
                .padding(HelioTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: HelioTheme.cardRadius))
                
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
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }
                    if let ok = vm.successMessage {
                        Text(ok).font(.footnote).foregroundStyle(HelioTheme.leaf)
                    }
                    
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        if vm.isBusy { ProgressView() } else {Text("Register") }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HelioTheme.navy)
                    .disabled(vm.isBusy)
                }
                .padding(HelioTheme.screenPadding)
            }
            .background(HelioBackground())
            .navigationTitle("Create account")
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
                Text("Enter your code")
                    .font(.system(size:28, weight: .bold, design: .rounded))
                    .foregroundStyle(HelioTheme.navy)
                
                Text(vm.infoMessage)
                    .foregroundStyle(HelioTheme.inkMuted)
                
                TextField("6-digit code", text: $vm.otp)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title2.monospacedDigit())
                    .helioField()
                    .onChange(of: vm.otp) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        vm.otp = String(digits.prefix(6))
                    }
                
                if let err = vm.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(.red)
                }
                
                Button {
                    Task { await vm.verify () }
                } label: {
                    if vm.isBusy { ProgressView().tint(.white)} else {
                        Text ("Verify")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(HelioTheme.leaf)
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
