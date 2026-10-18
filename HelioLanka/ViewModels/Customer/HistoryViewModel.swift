//
//  HistoryViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    var days: [(date: Date, kwh: Double)] = []
    var isLoading = false
    var errorMessage: String?
    
    private let session: SessionManager
    
    init(session: SessionManager){
        self.session = session
    }
    
    func load() async{
        let meter = session.selectedMeterId
        guard !meter.isEmpty else {
            days = []
            errorMessage = "No meter is linked to this account."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let readings = try await session.readings.listRecentHistory(meterId: meter)
            try session.dailyStore.sync(from: readings, meterId: meter)
            let stored = try session.dailyStore.last90Days(meterId: meter)
            days = stored.map {(date: $0.dayStart, kwh: $0.exportKwh)}
            if days.isEmpty {
                errorMessage = "No export history yet for this meter."
            }
        }catch{
            errorMessage = error.localizedDescription
        }
    }
}
