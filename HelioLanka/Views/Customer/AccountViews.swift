//
//  AccountViews.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import MapKit
import SwiftUI

struct AccountView: View {
    let user: UserMe
    let session: SessionManager

    var body: some View {
        NavigationStack {
            ZStack {
                HelioBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(HelioTheme.navy)
                        Text(user.displayName)
                            .foregroundStyle(HelioTheme.inkMuted)

                        AccountCard {
                            LabeledContent("Username", value: user.username)
                            LabeledContent("Email", value: user.email)
                            LabeledContent("Meters", value: "\(user.allMeters.count)")
                        }
                        .foregroundStyle(HelioTheme.navy)

                        NavigationLink {
                            ProfileView(session: session)
                        } label: {
                            accountRow("Profile", "person.text.rectangle", "Nickname and linked accounts")
                        }
                        NavigationLink {
                            SitesMapView(session: session)
                        } label: {
                            accountRow("Map", "map", "Pins for your meters")
                        }
                        NavigationLink {
                            LeaderboardView(session: session)
                        } label: {
                            accountRow("Leaderboard", "list.number", "Public monthly export")
                        }
                        AccountSecurityCard()
                        Button("Sign out") {
                            Task { await session.signOut() }
                        }
                        .buttonStyle(.bordered)
                        .tint(HelioTheme.navy)
                    }
                    .padding(HelioTheme.screenPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func accountRow(_ title: String, _ icon: String, _ subtitle: String) -> some View {
        AccountCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HelioTheme.brandTeal)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(HelioTheme.brandTeal.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(HelioTheme.navy)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(HelioTheme.inkMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(HelioTheme.inkMuted)
            }
        }
    }
}

struct ProfileView: View {
    let session: SessionManager
    @State private var vm: ProfileViewModel

    init(session: SessionManager) {
        self.session = session
        _vm = State(initialValue: ProfileViewModel(session: session))
    }

    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(HelioTheme.navy)

                    AccountCard {
                        Text("Public nickname")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        Text("Turn this on only if this name may appear on the public leaderboard.")
                            .font(.caption)
                            .foregroundStyle(HelioTheme.inkMuted)
                        TextField("Nickname", text: $vm.nickname)
                            .textInputAutocapitalization(.words)
                            .helioField()
                        Toggle("Show on leaderboard", isOn: $vm.nicknamePublic)
                            .tint(HelioTheme.leaf)
                            .foregroundStyle(HelioTheme.navy)
                        Button {
                            Task { await vm.save() }
                        } label: {
                            if vm.isBusy { ProgressView().tint(.white) } else { Text("Save profile") }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(vm.isBusy)
                    }

                    AccountCard {
                        Text("Link another account")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        TextField("10-digit account number", text: $vm.linkAccountNumber)
                            .keyboardType(.numberPad)
                            .helioField()
                        Button("Link account") {
                            Task { await vm.link() }
                        }
                        .buttonStyle(.bordered)
                        .tint(HelioTheme.navy)
                        .disabled(vm.isBusy)
                    }

                    if let message = vm.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.leaf)
                    }
                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }
}

struct SitesMapView: View {
    let session: SessionManager
    @State private var sites: [InstallationComposite] = []
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.87, longitude: 80.77),
            span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
        )
    )
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            HelioBackground()
            Map(position: $camera) {
                ForEach(sites, id: \.installation.id) { site in
                    let inst = site.installation
                    Annotation(inst.installationName, coordinate: CLLocationCoordinate2D(latitude: inst.latitude, longitude: inst.longitude)) {
                        VStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(HelioTheme.brandTeal)
                                .padding(8)
                                .background(HelioTheme.surface, in: Circle())
                            Text(inst.installationName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(HelioTheme.navy)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(HelioTheme.surface, in: Capsule())
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .clipShape(RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous))
            .padding(HelioTheme.screenPadding)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(HelioTheme.danger)
                    .padding(HelioTheme.screenPadding)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            var loaded: [InstallationComposite] = []
            for meter in sessionMeters {
                if let site = try? await session.installations.composite(meterId: meter.meterId) {
                    loaded.append(site)
                }
            }
            sites = loaded
            if loaded.isEmpty {
                errorMessage = "No site coordinates yet."
            } else if let first = loaded.first?.installation {
                camera = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                    )
                )
            }
        }
    }

    private var sessionMeters: [LinkedMeter] {
        if case .customer(let user) = session.phase {
            return user.allMeters
        }
        return []
    }
}

struct LeaderboardView: View {
    let session: SessionManager
    @State private var vm: LeaderboardViewModel

    init(session: SessionManager) {
        self.session = session
        _vm = State(initialValue: LeaderboardViewModel(session: session))
    }

    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Leaderboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(HelioTheme.navy)

                    Picker("Period", selection: $vm.period) {
                        Text("Day").tag("daily")
                        Text("Week").tag("weekly")
                        Text("Month").tag("monthly")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.period) { _, _ in
                        Task { await vm.load() }
                    }

                    if vm.isLoading && vm.entries.isEmpty {
                        ProgressView("Loading ranks…")
                            .tint(HelioTheme.brandTeal)
                    }

                    if vm.entries.isEmpty && !vm.isLoading {
                        Text("No export in this period yet.")
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.inkMuted)
                    }

                    ForEach(vm.entries) { entry in
                        let mine = entry.meterId == session.selectedMeterId
                        AccountCard {
                            HStack {
                                Text("\(entry.rank)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(mine ? HelioTheme.brandTeal : HelioTheme.navy)
                                    .frame(width: 32, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(HelioTheme.navy)
                                    Text(entry.meterId)
                                        .font(.caption)
                                        .foregroundStyle(HelioTheme.inkMuted)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(HelioFormat.energyKwh(entry.exportEnergyKwh))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(HelioTheme.leaf)
                                    if let earnings = entry.estimatedEarningsLkr {
                                        Text(HelioFormat.currency(earnings))
                                            .font(.caption)
                                            .foregroundStyle(HelioTheme.gold)
                                    }
                                }
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                                .strokeBorder(mine ? HelioTheme.brandTeal : .clear, lineWidth: 1)
                        }
                    }

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
            .refreshable { await vm.load() }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }
}

private struct AccountSecurityCard: View {
    @Bindable private var prefs = AppPreferences.shared
    @State private var hint: String?
    @State private var hintIsError = false

    var body: some View {
        let label = BiometricAuthService.kind.settingsLabel
        AccountCard {
            Text("Sign-in and widget")
                .font(.headline)
                .foregroundStyle(HelioTheme.navy)
            Text("Face ID stores a password in the Keychain only after a successful prompt. The widget reads a snapshot, not the API.")
                .font(.caption)
                .foregroundStyle(HelioTheme.inkMuted)

            Toggle("Sign in with \(label)", isOn: Binding(
                get: { prefs.biometricLoginEnabled },
                set: { turnedOn in
                    Task { await setBiometric(turnedOn, label: label) }
                }
            ))
            .tint(HelioTheme.leaf)
            .foregroundStyle(HelioTheme.navy)

            Toggle("Home Screen widget", isOn: $prefs.widgetEnabled)
                .tint(HelioTheme.leaf)
                .foregroundStyle(HelioTheme.navy)

            if prefs.widgetEnabled {
                Button("Reload widget") {
                    WidgetCenterBridge.reload()
                    hint = "Widget reload requested."
                    hintIsError = false
                }
                .buttonStyle(.bordered)
                .tint(HelioTheme.navy)
            }

            if let hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(hintIsError ? HelioTheme.danger : HelioTheme.leaf)
            }
        }
    }

    private func setBiometric(_ turnedOn: Bool, label: String) async {
        if !turnedOn {
            prefs.biometricLoginEnabled = false
            hint = "\(label) is off. The saved password was removed."
            hintIsError = false
            return
        }
        guard BiometricAuthService.isAvailable else {
            hint = "Enroll \(label) on this device first. Features → Face ID → Enrolled."
            hintIsError = true
            return
        }
        guard BiometricCredentialStore.load() != nil else {
            hint = "Sign out, sign in with your username and password, enter the OTP, and accept the prompt."
            hintIsError = true
            return
        }
        do {
            try await BiometricAuthService.authenticate(
                reason: "Enable \(label) for HelioLanka"
            )
            prefs.biometricLoginEnabled = true
            hint = "\(label) is on."
            hintIsError = false
        } catch {
            hint = "\(label) was not enabled. Password sign-in still works."
            hintIsError = true
        }
    }
}


private struct AccountCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(HelioTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .fill(HelioTheme.surface)
                .shadow(color: HelioTheme.cardShadow, radius: 16, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .strokeBorder(HelioTheme.hairline, lineWidth: 1)
        }
    }
}
