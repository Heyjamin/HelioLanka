//
//  HelioLankaWidget.swift
//  HelioLankaWidget
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-22.
//

import SwiftUI
import WidgetKit

struct HelioLankaWidget: Widget {
    let kind = "HelioLankaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HelioLankaWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.96, green: 0.97, blue: 0.96)
                }
        }
        .configurationDisplayName("HelioLanka")
        .description("Today’s export and tomorrow’s forecast.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.preview : WidgetSnapshotStore.load()
        completion(SimpleEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: .now, snapshot: WidgetSnapshotStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct HelioLankaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SimpleEntry

    /// Fixed dark ink. HelioTheme.navy becomes light in Dark Mode and would disappear on these chips.
    private enum Ink {
        static let primary = Color(red: 0.086, green: 0.098, blue: 0.094)
        static let secondary = Color(red: 0.29, green: 0.36, blue: 0.33)
        static let teal = Color(red: 13 / 255, green: 115 / 255, blue: 119 / 255)
    }

    var body: some View {
        Group {
            if entry.snapshot.updatedAt == .distantPast {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HelioLanka")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Ink.primary)
                    Text("Open the app and visit Home and Earn to fill today and tomorrow.")
                        .font(.caption)
                        .foregroundStyle(Ink.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else if family == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    header
                    metric("Today", entry.snapshot.todayExportKwh, "bolt.fill")
                    metric("Tomorrow", entry.snapshot.tomorrowForecastKwh, "sun.max.fill")
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    header
                    HStack(spacing: 8) {
                        metric("Today", entry.snapshot.todayExportKwh, "bolt.fill")
                        metric("Tomorrow", entry.snapshot.tomorrowForecastKwh, "sun.max.fill")
                    }
                }
            }
        }
        .padding(12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HelioLanka")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Ink.primary)
            Text(siteTitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Ink.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(chip)
    }

    private func metric(_ title: String, _ value: Double, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Ink.teal)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Ink.secondary)
            }
            Text(String(format: "%.2f", value))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Ink.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text("kWh")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Ink.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(chip)
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Ink.teal.opacity(0.35), lineWidth: 1)
            }
    }

    private var siteTitle: String {
        let name = entry.snapshot.installationName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "HelioLanka" : name
    }
}

@main
struct HelioLankaWidgetBundle: WidgetBundle {
    var body: some Widget {
        HelioLankaWidget()
    }
}
