//
//  CalendarViewModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//
import Foundation
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    var monthCursor: Date = Calendar.current.startOfDay(for: Date())
    var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    var generationByDay: [Date: Double] = [:]
    var highGenerationThreshold: Double = 10
    var notes: [CalendarNote] = []
    var monthNotes: [CalendarNote] = []
    var draftTitle = ""
    var draftBody = ""
    var draftIsReminder = false
    var draftReminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var isLoading = false
    var message: String?
    var errorMessage: String?

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    /// Monday-first cells. `nil` is a blank before the 1st or after the last day.
    var daysInMonth: [Date?] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthCursor)
        guard let start = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: start),
              let firstWeekday = cal.dateComponents([.weekday], from: start).weekday
        else { return [] }
        let leading = (firstWeekday + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: start) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    func load() async {
        let meter = session.selectedMeterId
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if !meter.isEmpty {
                let readings = try await session.readings.listRecentHistory(meterId: meter)
                try session.dailyStore.sync(from: readings, meterId: meter)
                let history = try session.dailyStore.last90Days(meterId: meter)
                generationByDay = Dictionary(uniqueKeysWithValues: history.map {
                    (Calendar.current.startOfDay(for: $0.dayStart), $0.exportKwh)
                })
                if let peak = history.map(\.exportKwh).max() {
                    highGenerationThreshold = max(8, peak * 0.75)
                }
                if let alert = GenerationAnomalyEvaluator.evaluate(history: history) {
                    await session.notifications.notifyGenerationAnomaly(alert)
                }
            }
            try refreshNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ day: Date) {
        selectedDay = Calendar.current.startOfDay(for: day)
        try? refreshNotesForSelected()
    }

    func shiftMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: monthCursor) {
            monthCursor = next
            try? refreshNotes()
        }
    }

    func kwh(on day: Date) -> Double? {
        generationByDay[Calendar.current.startOfDay(for: day)]
    }

    func isHighGeneration(_ day: Date) -> Bool {
        guard let kwh = kwh(on: day) else { return false }
        return kwh >= highGenerationThreshold
    }

    func saveNote() async {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            errorMessage = "Add a title for the note."
            return
        }
        do {
            let timeComps = Calendar.current.dateComponents([.hour, .minute], from: draftReminderTime)
            let note = CalendarNote(
                dayStart: selectedDay,
                title: title,
                bodyText: draftBody,
                isReminder: draftIsReminder,
                reminderHour: timeComps.hour ?? 9,
                reminderMinute: timeComps.minute ?? 0
            )
            try session.noteStore.upsert(note)
            if draftIsReminder {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDay)
                comps.hour = note.reminderHour
                comps.minute = note.reminderMinute
                if let fire = Calendar.current.date(from: comps) {
                    await session.notifications.scheduleNamedReminder(
                        id: note.id.uuidString,
                        title: note.title,
                        body: note.bodyText.isEmpty ? "HelioLanka reminder" : note.bodyText,
                        date: fire
                    )
                }
                message = session.notifications.authorized
                    ? "Saved."
                    : "Note saved. The reminder was not scheduled."
            } else {
                message = "Saved."
            }
            draftTitle = ""
            draftBody = ""
            draftIsReminder = false
            errorMessage = nil
            try refreshNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteNote(_ note: CalendarNote) {
        do {
            try session.noteStore.delete(note)
            session.notifications.cancelReminder(id: note.id.uuidString)
            try refreshNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncHighGenToDeviceCalendar() async {
        await session.calendar.requestAccess()
        guard session.calendar.authorized else {
            errorMessage = "Calendar access denied. Notes are still on this phone."
            return
        }
        var count = 0
        for (day, kwh) in generationByDay where kwh >= highGenerationThreshold {
            try? session.calendar.addHighGenerationEvent(day: day, exportKwh: kwh)
            count += 1
        }
        message = count == 0 ? "No high-generation days to sync." : "Synced \(count) high-generation day(s)."
    }

    private func refreshNotes() throws {
        monthNotes = try session.noteStore.notesInMonth(containing: monthCursor)
        try refreshNotesForSelected()
    }

    private func refreshNotesForSelected() throws {
        notes = try session.noteStore.notes(on: selectedDay)
    }
}

