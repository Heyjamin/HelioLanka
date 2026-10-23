//
//  CalendarView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//
import SwiftUI

struct CalendarView: View {
    let session: SessionManager
    @State private var vm: CalendarViewModel
    @Bindable private var prefs = AppPreferences.shared

    private let weekdayLabels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    init(session: SessionManager) {
        self.session = session
        _vm = State(initialValue: CalendarViewModel(session: session))
    }

    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HelioBrandLockup(height: 36, showsTagline: false)
                    Text("Calendar")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(HelioTheme.navy)

                    if vm.isLoading && vm.generationByDay.isEmpty {
                        ProgressView("Loading calendar…")
                            .tint(HelioTheme.brandTeal)
                    }

                    CalendarCard {
                        HStack {
                            Button { vm.shiftMonth(-1) } label: {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text(vm.monthCursor.formatted(.dateTime.month(.wide).year()))
                                .font(.headline)
                                .foregroundStyle(HelioTheme.navy)
                            Spacer()
                            Button { vm.shiftMonth(1) } label: {
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundStyle(HelioTheme.brandTeal)

                        HStack {
                            ForEach(weekdayLabels, id: \.self) { label in
                                Text(label)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(HelioTheme.inkMuted)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        let cells = vm.daysInMonth
                        let weeks = stride(from: 0, to: cells.count, by: 7).map { index in
                            Array(cells[index..<min(index + 7, cells.count)])
                        }
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            HStack(spacing: 6) {
                                ForEach(0..<week.count, id: \.self) { column in
                                    if let day = week[column] {
                                        dayCell(day)
                                    } else {
                                        Color.clear.frame(maxWidth: .infinity, minHeight: 44)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            legend(HelioTheme.gold, "High generation")
                            legend(HelioTheme.brandTeal, "Note")
                        }
                        .font(.caption2)
                        .foregroundStyle(HelioTheme.inkMuted)
                        Text("High from \(HelioFormat.energyKwh(vm.highGenerationThreshold))")
                            .font(.caption2)
                            .foregroundStyle(HelioTheme.inkMuted)
                    }

                    CalendarCard {
                        Text(vm.selectedDay.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        if let kwh = vm.kwh(on: vm.selectedDay) {
                            Text("Recorded export: \(HelioFormat.energyKwh(kwh))")
                                .font(.subheadline)
                                .foregroundStyle(vm.isHighGeneration(vm.selectedDay) ? HelioTheme.gold : HelioTheme.navy)
                        } else {
                            Text("No generation record for this day")
                                .font(.subheadline)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }

                        ForEach(vm.notes) { note in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(note.title).fontWeight(.semibold)
                                        if note.isReminder {
                                            Image(systemName: "bell.fill").font(.caption)
                                        }
                                    }
                                    .foregroundStyle(HelioTheme.navy)
                                    if !note.bodyText.isEmpty {
                                        Text(note.bodyText)
                                            .font(.caption)
                                            .foregroundStyle(HelioTheme.inkMuted)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) { vm.deleteNote(note) } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }

                        TextField("Title", text: $vm.draftTitle)
                            .helioField()
                        TextField("Details", text: $vm.draftBody, axis: .vertical)
                            .lineLimit(2...4)
                            .helioField()
                        Toggle("Remind me on this day", isOn: $vm.draftIsReminder)
                            .tint(HelioTheme.leaf)
                        if vm.draftIsReminder {
                            DatePicker("Time", selection: $vm.draftReminderTime, displayedComponents: .hourAndMinute)
                        }
                        Button("Save note") { Task { await vm.saveNote() } }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Sync high-generation days") { Task { await vm.syncHighGenToDeviceCalendar() } }
                            .buttonStyle(.bordered)
                            .tint(HelioTheme.navy)
                    }

                    CalendarCard {
                        Toggle("Notifications", isOn: $prefs.notificationsEnabled)
                            .tint(HelioTheme.leaf)
                            .onChange(of: prefs.notificationsEnabled) { _, _ in
                                Task { await rescheduleSummary() }
                            }
                        Toggle("High / low generation alerts", isOn: $prefs.generationAlertsEnabled)
                            .tint(HelioTheme.leaf)
                        Toggle("Daily summary", isOn: $prefs.dailySummaryEnabled)
                            .tint(HelioTheme.leaf)
                            .onChange(of: prefs.dailySummaryEnabled) { _, _ in
                                Task { await rescheduleSummary() }
                            }
                        if prefs.dailySummaryEnabled {
                            DatePicker("Summary time", selection: summaryTime, displayedComponents: .hourAndMinute)
                        }
                        Text("The daily summary repeats every day. Default time is 18:00.")
                            .font(.caption)
                            .foregroundStyle(HelioTheme.inkMuted)
                    }

                    if let message = vm.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.leaf)
                    }
                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
            .refreshable { await vm.load() }
        }
        .task(id: session.selectedMeterId) {
            await vm.load()
        }
    }

    private var summaryTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: prefs.dailySummaryHour,
                    minute: prefs.dailySummaryMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                prefs.dailySummaryHour = parts.hour ?? 18
                prefs.dailySummaryMinute = parts.minute ?? 0
                Task { await rescheduleSummary() }
            }
        )
    }

    private func rescheduleSummary() async {
        if prefs.notificationsEnabled {
            await session.notifications.requestPermission()
        }
        await session.notifications.applyDailySummary(
            enabled: prefs.notificationsEnabled && prefs.dailySummaryEnabled,
            hour: prefs.dailySummaryHour,
            minute: prefs.dailySummaryMinute
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let selected = Calendar.current.isDate(day, inSameDayAs: vm.selectedDay)
        let high = vm.isHighGeneration(day)
        let hasNote = vm.monthNotes.contains { Calendar.current.isDate($0.dayStart, inSameDayAs: day) }
        return Button {
            vm.select(day)
        } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.subheadline.weight(selected ? .bold : .regular))
                HStack(spacing: 2) {
                    Circle().fill(high ? HelioTheme.gold : .clear).frame(width: 5, height: 5)
                    Circle().fill(hasNote ? HelioTheme.brandTeal : .clear).frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(HelioTheme.navy)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? HelioTheme.brandTeal.opacity(0.18) : HelioTheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
        }
    }
}

private struct CalendarCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(HelioTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .fill(HelioTheme.surface)
                .shadow(color: HelioTheme.cardShadow, radius: 16, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .strokeBorder(HelioTheme.hairline, lineWidth: 1)
        }
    }
}

