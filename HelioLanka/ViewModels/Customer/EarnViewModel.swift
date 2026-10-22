//
//  EarnViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-19.
//

import Foundation
import Observation

struct EarningsProjection: Identifiable, Equatable{
    var id: String { label }
    let label: String
    let days: Int
    let generationKwh: Double
    let incomeLkr: Double
}

@MainActor
@Observable
final class EarnViewModel {
    var avgKwhPerDay: Double = 12
    var unitRateLkr: Double = 22.5
    var useHistoryAverage = true
    var useTariffFromSite = true
    var tariffFromSite: Double?
    var historyAverage: Double?
    var isLoading = false
    var errorMessage: String?
    var forecastDays: [SolarForecastModel.DayForecast] = []
    
    private let session: SessionManager
    
    init(session: SessionManager) {
        self.session = session
    }
    
    /// History average when that wsitch is on and the store has days. Otherwise the typed value, and never below zero.
    var effectiveAvg: Double {
        if useHistoryAverage, let historyAverage, historyAverage > 0 {return historyAverage}
        return max(0, avgKwhPerDay)
    }
    
    var effectiveRate: Double {
        if useTariffFromSite, let tariffFromSite, tariffFromSite > 0 { return tariffFromSite}
        return max(0, unitRateLkr)
    }
    
    var projections: [EarningsProjection] {
        let avg = effectiveAvg
        let rate = effectiveRate
        return [
            .init(label: "per day", days: 1, generationKwh: avg, incomeLkr: avg * rate),
            .init(label: "30 days", days: 30, generationKwh: avg * 30, incomeLkr: avg * 30 * rate),
            .init(label: "90 days", days: 90, generationKwh: avg * 90, incomeLkr: avg * 90 * rate),
            .init(label: "365 days", days: 365, generationKwh: avg * 365, incomeLkr: avg * 365 * rate)
        ]
    }
    
    var forecastMonthKwh: Double {
        forecastDays.map(\.predictedKwh).reduce(0, +)
    }
    
    var forecastMonthIncome: Double { forecastMonthKwh * effectiveRate }
    
    func load() async {
        let meter = session.selectedMeterId
        guard !meter.isEmpty else
        {
            errorMessage = "No meter is linked to this account."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let readings = try await session.readings.listRecentHistory(meterId: meter)
            try session.dailyStore.sync(from: readings, meterId: meter)
            let history = try session.dailyStore.last90Days(meterId: meter)
            if !history.isEmpty {
                historyAverage = history.map(\.exportKwh).reduce(0, +) / Double(history.count)
                if useHistoryAverage { avgKwhPerDay = historyAverage ?? avgKwhPerDay }
            }
            
            let composite = try await session.installations.composite(meterId: meter)
            tariffFromSite = composite.installation.tariffRate
            if useTariffFromSite { unitRateLkr = composite.installation.tariffRate }
            
            let weather = try? await session.weather.forecast(meterId: meter)
            var weatherDays = SolarForecastModel.dailyWeatherFeatures(from: weather?.hourly ?? [])
            if weatherDays.isEmpty {
                weatherDays = Array(repeating: .init(), count: 30)
            }else{
                let pattern = weatherDays
                while weatherDays.count < 30 {
                    weatherDays.append(pattern[weatherDays.count % pattern.count])
                }
            }
            
            forecastDays = session.forecast.forecast(
                context: .init(
                    capacityKwp: composite.installation.capacityKw,
                    historyKwh: history.map(\.exportKwh),
                    weatherByDay: weatherDays
                ),
                days: 30
            )
            WidgetPublisher.publish(
                meterId: meter,
                installationName: composite.installation.installationName,
                todayExportKwh: nil,
                tomorrowForecastKwh: forecastDays.first?.predictedKwh
            )
        }catch{
            errorMessage = error.localizedDescription
        }
    }
}
