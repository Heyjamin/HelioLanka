//
//  EarningsTests.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import Foundation
import Testing
@testable import HelioLanka

@MainActor
struct EarningsTests {
    private func model() -> EarnViewModel {
        EarnViewModel(session: SessionManager())
    }

    @Test func historyAverageWinsWhenTheSwitchIsOn() {
        let vm = model()
        vm.useHistoryAverage = true
        vm.historyAverage = 8
        vm.avgKwhPerDay = 99
        #expect(vm.effectiveAvg == 8)
    }

    @Test func typedAverageIsUsedWhenHistoryIsMissing() {
        let vm = model()
        vm.useHistoryAverage = true
        vm.historyAverage = nil
        vm.avgKwhPerDay = 12
        #expect(vm.effectiveAvg == 12)
    }

    @Test func zeroHistoryDoesNotReplaceTheTypedAverage() {
        let vm = model()
        vm.useHistoryAverage = true
        vm.historyAverage = 0
        vm.avgKwhPerDay = 12
        #expect(vm.effectiveAvg == 12)
    }

    @Test func negativeTypedAverageIsClampedToZero() {
        let vm = model()
        vm.useHistoryAverage = false
        vm.avgKwhPerDay = -5
        #expect(vm.effectiveAvg == 0)
    }

    @Test func siteTariffWinsWhenTheSwitchIsOn() {
        let vm = model()
        vm.useTariffFromSite = true
        vm.tariffFromSite = 22.5
        vm.unitRateLkr = 1
        #expect(vm.effectiveRate == 22.5)
    }

    @Test func typedRateIsUsedWhenTheSiteSwitchIsOff() {
        let vm = model()
        vm.useTariffFromSite = false
        vm.unitRateLkr = 10
        #expect(vm.effectiveRate == 10)
    }

    @Test func negativeTypedRateIsClampedToZero() {
        let vm = model()
        vm.useTariffFromSite = false
        vm.unitRateLkr = -3
        #expect(vm.effectiveRate == 0)
    }

    @Test func projectionsScaleAverageAndRate() {
        let vm = model()
        vm.useHistoryAverage = false
        vm.avgKwhPerDay = 10
        vm.useTariffFromSite = false
        vm.unitRateLkr = 20

        let rows = vm.projections
        #expect(rows.map(\.label) == ["per day", "30 days", "90 days", "365 days"])
        #expect(rows.map(\.days) == [1, 30, 90, 365])
        #expect(rows[0].generationKwh == 10)
        #expect(rows[0].incomeLkr == 200)
        #expect(rows[1].generationKwh == 300)
        #expect(rows[1].incomeLkr == 6_000)
        #expect(rows[2].generationKwh == 900)
        #expect(rows[2].incomeLkr == 18_000)
        #expect(rows[3].generationKwh == 3_650)
        #expect(rows[3].incomeLkr == 73_000)
    }

    @Test func forecastIncomeIsPredictedEnergyTimesTheRate() {
        let vm = model()
        vm.useTariffFromSite = false
        vm.unitRateLkr = 10
        vm.forecastDays = [
            .init(day: Date(timeIntervalSince1970: 1), predictedKwh: 4),
            .init(day: Date(timeIntervalSince1970: 2), predictedKwh: 6)
        ]
        #expect(vm.forecastMonthKwh == 10)
        #expect(vm.forecastMonthIncome == 100)
    }
}

