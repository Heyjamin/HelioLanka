//
//  AppPreferences.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//

import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class AppPreferences {
    static let shared = AppPreferences()

    private enum Keys {
        static let notifications = "helio.prefs.notificationsEnabled"
        static let generationAlerts = "helio.prefs.generationAlertsEnabled"
        static let dailySummary = "helio.prefs.dailySummaryEnabled"
        static let dailyHour = "helio.prefs.dailySummaryHour"
        static let dailyMinute = "helio.prefs.dailySummaryMinute"
        static let widget = "helio.prefs.widgetEnabled"
        static let biometric = "helio.prefs.biometricLoginEnabled"
    }

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    var generationAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(generationAlertsEnabled, forKey: Keys.generationAlerts) }
    }

    var dailySummaryEnabled: Bool {
        didSet { UserDefaults.standard.set(dailySummaryEnabled, forKey: Keys.dailySummary) }
    }

    var dailySummaryHour: Int {
        didSet { UserDefaults.standard.set(dailySummaryHour, forKey: Keys.dailyHour) }
    }

    var dailySummaryMinute: Int {
        didSet { UserDefaults.standard.set(dailySummaryMinute, forKey: Keys.dailyMinute) }
    }
    
    var widgetEnabled: Bool {
        didSet {
            UserDefaults.standard.set(widgetEnabled, forKey: Keys.widget)
            if widgetEnabled {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// On/off only. The username and password stay in BiometricCredentialStore.
    var biometricLoginEnabled: Bool {
        didSet {
            UserDefaults.standard.set(biometricLoginEnabled, forKey: Keys.biometric)
            if !biometricLoginEnabled {
                BiometricCredentialStore.clear()
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        generationAlertsEnabled = defaults.object(forKey: Keys.generationAlerts) as? Bool ?? true
        dailySummaryEnabled = defaults.object(forKey: Keys.dailySummary) as? Bool ?? false
        dailySummaryHour = defaults.object(forKey: Keys.dailyHour) as? Int ?? 18
        dailySummaryMinute = defaults.object(forKey: Keys.dailyMinute) as? Int ?? 0
        widgetEnabled = defaults.object(forKey: Keys.widget) as? Bool ?? true
        biometricLoginEnabled = defaults.object(forKey: Keys.biometric) as? Bool ?? false

    }
}
