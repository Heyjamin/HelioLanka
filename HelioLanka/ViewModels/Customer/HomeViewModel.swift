//
//  HomeViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var composite: InstallationComposite?
    var recent: [ReadingRow] = []
    var isLoading = false
    var errorMessage: String?
    
    private let session: SessionManager
    
    init(session: SessionManager){
        self.session = session
    }
    
    /// Sum of interval export whose timestamps fall on today (device calendar).
    var todayExportKwh: Double {
        recent
            .filter { Calendar.current.isDateInToday($0.timestampUtc)}
            .reduce(0) { $0 + $1.intervalExportKwh}
    }
    
    var latestIntervals: [ReadingRow]{
        Array(recent.prefix(5))
    }
    
    func load() async {
        let meter = session.selectedMeterId
        guard !meter.isEmpty else {
            composite = nil
            recent = []
            errorMessage = "No meter is linked to this account."
            return
        }
        
        isLoading = true
        errorMessage =  nil
        defer { isLoading = false }
        
        do {
            async let site = session.installations.composite(meterId: meter)
            async let rows = session.readings.latest(meterId: meter)
            composite = try await site
            recent = try await rows
            WidgetPublisher.publish(
                meterId: meter,
                installationName: composite?.installation.installationName ?? "",
                todayExportKwh: todayExportKwh,
                tomorrowForecastKwh: nil
            )

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
