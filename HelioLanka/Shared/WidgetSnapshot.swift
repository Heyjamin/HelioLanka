//
//  WidgetSnapshot.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {
    var meterId: String
    var installationName: String
    var todayExportKwh: Double
    var tomorrowForecastKwh: Double
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        meterId: "—",
        installationName: "HelioLanka",
        todayExportKwh: 0,
        tomorrowForecastKwh: 0,
        updatedAt: .distantPast
    )

    /// Widget gallery only. The Home Screen uses a real snapshot, or asks you to open the app.
    static let preview = WidgetSnapshot(
        meterId: "MTR-000001",
        installationName: "Rooftop Site 1",
        todayExportKwh: 4.2,
        tomorrowForecastKwh: 7.4,
        updatedAt: .now
    )
}

enum WidgetSnapshotStore {
    /// Must match AppEnvironment.appGroupId on the app target.
    static let suiteName = "group.lk.heliolanka.app"
    private static let key = "widget.snapshot"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}
