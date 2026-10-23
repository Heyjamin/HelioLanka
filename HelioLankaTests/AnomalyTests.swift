//
//  AnomalyTests.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import Foundation
import Testing
@testable import HelioLanka

struct AnomalyTests {
    @Test func tooFewDaysReturnsNil() {
        #expect(GenerationAnomalyEvaluator.evaluate(history: rows([10, 10, 10])) == nil)
    }

    @Test func latestDayNearZeroReturnsNil() {
        #expect(GenerationAnomalyEvaluator.evaluate(history: rows([10, 10, 10, 0])) == nil)
    }

    @Test func baselineUnderTwoReturnsNil() {
        #expect(GenerationAnomalyEvaluator.evaluate(history: rows([1, 1, 1, 8])) == nil)
    }

    @Test func normalDayReturnsNil() {
        #expect(GenerationAnomalyEvaluator.evaluate(history: rows([10, 10, 10, 10])) == nil)
    }

    @Test func slightRiseBelowBothBarsReturnsNil() {
        // Baseline 10. High bar is max(13.5, 13) = 13.5. 12 stays inside it.
        #expect(GenerationAnomalyEvaluator.evaluate(history: rows([10, 10, 10, 12])) == nil)
    }

    @Test func latestDayFarAboveAverageIsHigh() throws {
        let history = rows([10, 10, 10, 20])
        let alert = try #require(GenerationAnomalyEvaluator.evaluate(history: history))
        #expect(alert.kind == .high)
        #expect(alert.exportKwh == 20)
        #expect(alert.baselineKwh == 10)
        #expect(alert.day == history[3].dayStart)
    }

    @Test func latestDayFarBelowAverageIsLow() throws {
        let history = rows([10, 10, 10, 4])
        let alert = try #require(GenerationAnomalyEvaluator.evaluate(history: history))
        #expect(alert.kind == .low)
        #expect(alert.exportKwh == 4)
        #expect(alert.baselineKwh == 10)
        #expect(alert.day == history[3].dayStart)
    }

    @Test func unsortedHistoryStillUsesTheLatestDay() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let older = day("a", start, 10)
        let middle = day("b", start.addingTimeInterval(86_400), 10)
        let newest = day("c", start.addingTimeInterval(86_400 * 2), 10)
        let latest = day("d", start.addingTimeInterval(86_400 * 3), 20)
        let alert = try #require(
            GenerationAnomalyEvaluator.evaluate(history: [latest, older, newest, middle])
        )
        #expect(alert.kind == .high)
        #expect(alert.day == latest.dayStart)
    }
}

private func rows(_ exports: [Double]) -> [DailyGeneration] {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    return exports.enumerated().map { index, kwh in
        day("m-\(index)", start.addingTimeInterval(Double(index) * 86_400), kwh)
    }
}

private func day(_ key: String, _ dayStart: Date, _ exportKwh: Double) -> DailyGeneration {
    DailyGeneration(key: key, meterId: "MTR-1", dayStart: dayStart, exportKwh: exportKwh)
}
