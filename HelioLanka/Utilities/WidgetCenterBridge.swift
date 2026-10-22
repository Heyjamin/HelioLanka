//
//  WidgetCenterBridge.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import Foundation
import WidgetKit

enum WidgetCenterBridge {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum WidgetPublisher {
    @MainActor
    static func publish(
        meterId: String,
        installationName: String,
        todayExportKwh: Double?,
        tomorrowForecastKwh: Double?
    ) {
        guard AppPreferences.shared.widgetEnabled else { return }
        let existing = WidgetSnapshotStore.load()
        let trimmedName = installationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hadSnapshot = existing.updatedAt != .distantPast
        let snapshot = WidgetSnapshot(
            meterId: meterId.isEmpty ? existing.meterId : meterId,
            installationName: trimmedName.isEmpty ? existing.installationName : trimmedName,
            todayExportKwh: todayExportKwh ?? (hadSnapshot ? existing.todayExportKwh : 0),
            tomorrowForecastKwh: tomorrowForecastKwh ?? (hadSnapshot ? existing.tomorrowForecastKwh : 0),
            updatedAt: Date()
        )
        WidgetSnapshotStore.save(snapshot)
        WidgetCenterBridge.reload()
    }
}
