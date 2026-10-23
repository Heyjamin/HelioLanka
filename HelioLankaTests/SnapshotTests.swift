//
//  SnapshotTests.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import Foundation
import Testing
@testable import HelioLanka

struct SnapshotTests {
    @Test func encodedSnapshotDecodesToTheSameValue() throws {
        let original = WidgetSnapshot(
            meterId: "MTR-000001",
            installationName: "Rooftop Site 1",
            todayExportKwh: 4.2,
            tomorrowForecastKwh: 7.4,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        #expect(decoded == original)
        #expect(decoded.meterId == "MTR-000001")
        #expect(decoded.todayExportKwh == 4.2)
        #expect(decoded.tomorrowForecastKwh == 7.4)
    }

    @Test func emptySnapshotMarksAnUnsetWidget() {
        #expect(WidgetSnapshot.empty.meterId == "—")
        #expect(WidgetSnapshot.empty.installationName == "HelioLanka")
        #expect(WidgetSnapshot.empty.todayExportKwh == 0)
        #expect(WidgetSnapshot.empty.tomorrowForecastKwh == 0)
        let unset = Date.distantPast
        #expect(WidgetSnapshot.empty.updatedAt == unset)
    }

    @Test func previewSnapshotUsesTheGallerySample() {
        #expect(WidgetSnapshot.preview.meterId == "MTR-000001")
        #expect(WidgetSnapshot.preview.installationName == "Rooftop Site 1")
        #expect(WidgetSnapshot.preview.todayExportKwh == 4.2)
        #expect(WidgetSnapshot.preview.tomorrowForecastKwh == 7.4)
    }

    @Test func emptySnapshotRoundTrips() throws {
        let data = try JSONEncoder().encode(WidgetSnapshot.empty)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        #expect(decoded == WidgetSnapshot.empty)
    }
}

