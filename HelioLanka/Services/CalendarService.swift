//
//  CalendarService.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//
import EventKit
import Foundation

@MainActor
final class CalendarService {
    private let store = EKEventStore()
    private(set) var authorized = false

    func requestAccess() async {
        do {
            authorized = try await store.requestWriteOnlyAccessToEvents()
        } catch {
            authorized = false
        }
    }

    /// Writes one all-day event. Does not read other events.
    func addHighGenerationEvent(day: Date, exportKwh: Double) throws {
        guard authorized else { return }
        guard let calendar = store.defaultCalendarForNewEvents else { return }
        let event = EKEvent(eventStore: store)
        event.title = String(format: "HelioLanka · strong sun (~%.0f kWh)", exportKwh)
        event.startDate = Calendar.current.startOfDay(for: day)
        event.endDate = event.startDate.addingTimeInterval(24 * 3600)
        event.isAllDay = true
        event.calendar = calendar
        try store.save(event, span: .thisEvent)
    }
}
