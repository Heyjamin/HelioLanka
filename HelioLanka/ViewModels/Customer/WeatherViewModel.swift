//
//  WeatherViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    struct DaySummary: Identifiable {
        var id: Date {day}
        let day: Date
        let avgTempC: Double?
        let avgCloud: Double?
        let avgRadiation: Double?
        let rainMm: Double
    }
    
    var weather: WeatherForecast?
    var daySummaries: [DaySummary] = []
    var hourlyToday: [WeatherPoint] = []
    var isLoading = false
    var errorMessage: String?
    
    private let session: SessionManager
    
    init (session: SessionManager){
        self.session = session
    }
    
    /// Prefer the row for today. If none of the hours fall on today, use the first day.
    var featuredDay: DaySummary? {
        daySummaries.first { Calendar.current.isDateInToday($0.day)} ?? daySummaries.first
    }
    
    func load() async {
        let meter = session.selectedMeterId
        guard !meter.isEmpty else {
            weather = nil
            daySummaries = []
            hourlyToday = []
            errorMessage = "No meter is linked to this account"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false}
        
        do {
            weather = try await session.weather.forecast(meterId: meter)
            rebuildSummaries()
            if daySummaries.isEmpty{
                errorMessage = " No forecast hours were returned for this site."
            }
        }catch{
            errorMessage = error.localizedDescription
        }
    }
    
    private func rebuildSummaries(){
        guard let hourly = weather?.hourly else{
            daySummaries = []
            hourlyToday = []
            return
        }
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        hourlyToday = hourly
            .filter { cal.isDate($0.timeUtc, inSameDayAs: today)}
            .sorted { $0.timeUtc < $1.timeUtc }
        
        var map: [Date: [WeatherPoint]] = [:]
        for point in hourly {
            let day = cal.startOfDay(for: point.timeUtc)
            map[day, default: []].append(point)
        }
        
        daySummaries = map.keys.sorted().prefix(7).map { day in
        let points = map[day] ?? []
            let temps = points.compactMap(\.temperatureC)
            let clouds = points.compactMap(\.cloudCoverPercent)
            let radiation = points.compactMap(\.shortwaveRadiationWm2)
            let rain = points.compactMap(\.precipitationMm).reduce(0, +)
            return DaySummary(
                day: day,
                avgTempC: average(temps),
                avgCloud: average(clouds),
                avgRadiation: average(radiation),
                rainMm: rain
            )
        }
    }
    
    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else {return nil}
        return values.reduce(0, +) / Double(values.count)
    }
    
}

