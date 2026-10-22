//
//  AccountViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    var nickname = ""
    var nicknamePublic = false
    var linkAccountNumber = ""
    var isBusy = false
    var message: String?
    var errorMessage: String?

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    func load() async {
        errorMessage = nil
        do {
            let profile = try await session.profile.get()
            nickname = profile.nickname ?? ""
            nicknamePublic = profile.nicknamePublic
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        isBusy = true
        message = nil
        errorMessage = nil
        defer { isBusy = false }
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let profile = try await session.profile.update(
                UpdateProfileBody(
                    nickname: trimmed.isEmpty ? nil : trimmed,
                    nicknamePublic: nicknamePublic
                )
            )
            nickname = profile.nickname ?? ""
            nicknamePublic = profile.nicknamePublic
            message = nicknamePublic
                ? "Saved. The leaderboard can show this nickname."
                : "Saved. The leaderboard will show Anonymous."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func link() async {
        let digits = linkAccountNumber.filter(\.isNumber)
        guard digits.count == 10 else {
            errorMessage = "Enter the 10-digit account number."
            return
        }
        isBusy = true
        message = nil
        errorMessage = nil
        defer { isBusy = false }
        do {
            let user = try await session.profile.linkAccount(digits)
            session.apply(user: user)
            linkAccountNumber = ""
            message = "Linked. You now have \(user.allMeters.count) meters."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class LeaderboardViewModel {
    var period = "monthly"
    var entries: [LeaderboardEntry] = []
    var isLoading = false
    var errorMessage: String?

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            entries = try await session.leaderboard.fetch(period: period)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
