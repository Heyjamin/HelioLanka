//
//  GenerationAnomalyEvaluator.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//

import Foundation

/// High or low daily export compared with earlier positive days.
enum GenerationAnomalyEvaluator {
    enum Kind: String {
        case high = "HighGeneration"
        case low = "LowGeneration"
    }

    struct Alert: Equatable {
        let kind: Kind
        let day: Date
        let exportKwh: Double
        let baselineKwh: Double
    }

    static let highFactor = 1.35
    static let highAbsoluteDelta = 3.0
    static let lowFactor = 0.55
    static let lowAbsoluteDelta = 2.5
    static let minBaseline = 2.0

    static func evaluate(history: [DailyGeneration]) -> Alert? {
        guard history.count >= 4 else { return nil }
        let sorted = history.sorted { $0.dayStart < $1.dayStart }
        guard let latest = sorted.last, latest.exportKwh > 0.05 else { return nil }

        let prior = sorted.dropLast().suffix(14).map(\.exportKwh).filter { $0 > 0.05 }
        guard prior.count >= 3 else { return nil }
        let baseline = prior.reduce(0, +) / Double(prior.count)
        guard baseline >= minBaseline else { return nil }

        let kwh = latest.exportKwh
        if kwh >= max(baseline * highFactor, baseline + highAbsoluteDelta) {
            return Alert(kind: .high, day: latest.dayStart, exportKwh: kwh, baselineKwh: baseline)
        }
        if kwh <= min(baseline * lowFactor, baseline - lowAbsoluteDelta) {
            return Alert(kind: .low, day: latest.dayStart, exportKwh: kwh, baselineKwh: baseline)
        }
        return nil
    }
}
