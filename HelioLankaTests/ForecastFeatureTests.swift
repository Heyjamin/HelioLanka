//
//  ForecastFeatureTests.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import Foundation
import Testing
@testable import HelioLanka

struct ForecastFeatureTests {
    @Test func emptyHistoryUsesTheDefaultLag() {
        let features = SolarForecastModel.featureVector(
            day: Date(),
            capacityKwp: 5,
            history: [],
            weather: .init()
        )
        #expect(features["lag_1_kwh"] == 6)
        #expect(features["lag_7_kwh"] == 6)
        #expect(features["capacity_kwp"] == 5)
        #expect(features["rolling_7_std_kwh"] == 1.2)
        #expect(features["humidity_pct"] == 75)
        #expect(features["avg_temp_c"] == 28)
        #expect(features["cloud_cover_pct"] == 55)
        #expect(features["precipitation_mm"] == 2)
        #expect(features["shortwave_radiation_wm2"] == 220)
    }

    @Test func shortHistoryCopiesLag1IntoLag7() {
        let features = SolarForecastModel.featureVector(
            day: Date(),
            capacityKwp: 5,
            history: [4, 5, 6],
            weather: .init()
        )
        #expect(features["lag_1_kwh"] == 6)
        #expect(features["lag_7_kwh"] == 6)
        #expect(features["rolling_7_mean_kwh"] == 5)
    }

    @Test func sevenDayWindowUsesTheFirstValueAsLag7() {
        let features = SolarForecastModel.featureVector(
            day: Date(),
            capacityKwp: 3.5,
            history: [1, 2, 3, 4, 5, 6, 7],
            weather: .init(
                avgTempC: 30,
                cloudCoverPct: 10,
                humidityPct: 60,
                precipitationMm: 0,
                shortwaveRadiationWm2: 400
            )
        )
        #expect(features["lag_1_kwh"] == 7)
        #expect(features["lag_7_kwh"] == 1)
        #expect(features["rolling_7_mean_kwh"] == 4)
        #expect(features["capacity_kwp"] == 3.5)
        #expect(features["avg_temp_c"] == 30)
        #expect(features["shortwave_radiation_wm2"] == 400)
        let weekday = features["day_of_week"] ?? -1
        #expect(weekday >= 0 && weekday <= 6)
    }

    @Test func oneStoredDayUsesTheFixedSpread() {
        let features = SolarForecastModel.featureVector(
            day: Date(),
            capacityKwp: 5,
            history: [9],
            weather: .init()
        )
        #expect(features["rolling_7_std_kwh"] == 1.2)
        #expect(features["lag_1_kwh"] == 9)
    }

    @Test func mondayIsWeekdayZero() throws {
        let calendar = Calendar.current
        let monday = try #require(
            calendar.nextDate(
                after: Date(timeIntervalSince1970: 0),
                matching: DateComponents(weekday: 2),
                matchingPolicy: .nextTime
            )
        )
        let features = SolarForecastModel.featureVector(
            day: monday,
            capacityKwp: 5,
            history: [8],
            weather: .init()
        )
        #expect(calendar.component(.weekday, from: monday) == 2)
        #expect(features["day_of_week"] == 0)
    }

    @Test func emptyHourlyListProducesNoDays() {
        #expect(SolarForecastModel.dailyWeatherFeatures(from: []).isEmpty)
    }

    @Test func hoursOnTheSameLocalDayAreAveraged() throws {
        let calendar = Calendar.current
        let morning = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 8))
        )
        let afternoon = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 16))
        )
        let days = SolarForecastModel.dailyWeatherFeatures(from: [
            WeatherPoint(
                timeUtc: morning,
                temperatureC: 20,
                cloudCoverPercent: 40,
                shortwaveRadiationWm2: 100,
                precipitationMm: 1
            ),
            WeatherPoint(
                timeUtc: afternoon,
                temperatureC: 30,
                cloudCoverPercent: 60,
                shortwaveRadiationWm2: 300,
                precipitationMm: 2
            )
        ])
        #expect(days.count == 1)
        #expect(days[0].avgTempC == 25)
        #expect(days[0].cloudCoverPct == 50)
        #expect(days[0].precipitationMm == 3)
        #expect(days[0].shortwaveRadiationWm2 == 200)
        #expect(days[0].humidityPct == 75)
    }

    @Test func missingWeatherFieldsUseTheTrainingDefaults() {
        let days = SolarForecastModel.dailyWeatherFeatures(from: [
            WeatherPoint(
                timeUtc: Date(),
                temperatureC: nil,
                cloudCoverPercent: nil,
                shortwaveRadiationWm2: nil,
                precipitationMm: nil
            )
        ])
        #expect(days.count == 1)
        #expect(days[0].avgTempC == 28)
        #expect(days[0].cloudCoverPct == 55)
        #expect(days[0].humidityPct == 75)
        #expect(days[0].precipitationMm == 0)
        #expect(days[0].shortwaveRadiationWm2 == 220)
    }
}

