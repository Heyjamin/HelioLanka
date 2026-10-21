//
//  NotificationService.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private(set) var authorized = false

    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    func requestPermission() async {
        do {
            authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            authorized = false
        }
    }

    func scheduleNamedReminder(id: String, title: String, body: String, date: Date) async {
        if !authorized {
            await requestPermission()
        }
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "note-\(id)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["note-\(id)"])
    }

    func notifyGenerationAnomaly(_ alert: GenerationAnomalyEvaluator.Alert) async {
        let prefs = AppPreferences.shared
        guard prefs.notificationsEnabled, prefs.generationAlertsEnabled else { return }
        if !authorized {
            await requestPermission()
        }
        guard authorized else { return }

        let dayKey = Int(Calendar.current.startOfDay(for: alert.day).timeIntervalSince1970)
        let id = "gen-\(alert.kind.rawValue)-\(dayKey)"
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: id) { return }

        let delta = alert.baselineKwh <= 0.01
            ? 0
            : ((alert.exportKwh - alert.baselineKwh) / alert.baselineKwh) * 100

        let content = UNMutableNotificationContent()
        content.sound = .default
        switch alert.kind {
        case .high:
            content.title = "HelioLanka · Exceptional solar day"
            content.body = String(
                format: "%.1f kWh exported (%.0f%% above your recent average of %.1f kWh). Strong sun — check your earnings.",
                alert.exportKwh, delta, alert.baselineKwh
            )
        case .low:
            content.title = "HelioLanka · Low generation alert"
            content.body = String(
                format: "Only %.1f kWh today vs %.1f kWh average (%.0f%%). Cloud, shade, or inverter? Open the app to review.",
                alert.exportKwh, alert.baselineKwh, delta
            )
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        defaults.set(true, forKey: id)
    }

    /// Repeating local notification. Identifier is always `daily-summary`.
    func applyDailySummary(enabled: Bool, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-summary"])
        guard enabled else { return }
        if !authorized {
            await requestPermission()
        }
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "HelioLanka daily summary"
        content.body = "Review today’s solar export and tomorrow’s on-device forecast."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

private final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
