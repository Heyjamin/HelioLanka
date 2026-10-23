//
//  WeatherView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Charts
import SwiftUI

struct WeatherView: View {
    let session: SessionManager
    @State private var vm: WeatherViewModel
    
    init(session: SessionManager){
        self.session = session
        _vm = State(initialValue: WeatherViewModel(session: session))
    }
    
    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                    HelioBrandLockup(height: 36, showsTagline: false)
                    HStack{
                        Text("Weather")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(HelioTheme.navy)
                        Spacer()
                        MeterPicker(session: session)
                    }
                    
                    if vm.isLoading && vm.weather == nil {
                        ProgressView("Loading forecast...")
                            .tint(HelioTheme.ocean)
                    }
                    
                    if let today = vm.featuredDay {
                        WeatherCard {
                            HStack(spacing: 16){
                                Image(systemName: weatherIcon(cloud: today.avgCloud, rain: today.rainMm))
                                    .font(.system(size: 40))
                                    .foregroundStyle(HelioTheme.brandTeal)
                                VStack(alignment: .leading, spacing: 4){
                                    Text(dayTitle(today.day))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(HelioTheme.inkMuted)
                                    Text(tempText(today.avgTempC))
                                        .font(.system(size:34, weight: .bold, design:.rounded))
                                        .foregroundStyle(HelioTheme.navy)
                                    Text("Clouds \(percent(today.avgCloud)) . Rain \(String(format: "%.1f", today.rainMm)) mm")
                                        .font(.footnote)
                                        .foregroundStyle(HelioTheme.inkMuted)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    if let site = vm.weather {
                        Text("\(site.provider ?? "Forecast") . \(String(format: "%.3f", site.latitude)), \(String(format: "%.3f", site.longitude))")
                            .font(.caption)
                            .foregroundStyle(HelioTheme.inkMuted)
                    }
                    
                    WeatherCard {
                        Text("Today . temperature")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        if vm.hourlyToday.isEmpty && !vm.isLoading {
                            Text("No hours fall on today.")
                                .font(.footnote)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }else{
                            Chart(vm.hourlyToday, id: \.timeUtc){ point in
                                if let temperature = point.temperatureC{
                                    LineMark(
                                        x: .value("Hour", point.timeUtc),
                                        y: .value("°C", temperature)
                                    )
                                    .foregroundStyle(HelioTheme.ocean)
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .chartXAxis{
                                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                    AxisValueLabel(format: .dateTime.hour())
                                }
                            }
                            .frame(height: 160)
                        }
                    }
                    
                    WeatherCard{
                        Text("Todaty . solar radiation")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        Chart(vm.hourlyToday, id: \.timeUtc) { point in
                            if let radiation = point.shortwaveRadiationWm2 {
                                BarMark(
                                    x: .value("Hour", point.timeUtc),
                                    y: .value("W/m²", radiation)
                                )
                                .foregroundStyle(HelioTheme.gold)
                            }
                        }
                        .chartXAxis{
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: 140)
                    }
                    
                    WeatherCard {
                        Text("Outlook")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        ForEach(vm.daySummaries) { day in
                            HStack {
                                Text(day.day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    .foregroundStyle(HelioTheme.inkMuted)
                                    .frame(width: 88, alignment: .leading)
                                Image(systemName: weatherIcon(cloud: day.avgCloud, rain: day.rainMm))
                                    .foregroundStyle(HelioTheme.gold)
                                Spacer()
                                Text(tempText(day.avgTempC))
                                    .foregroundStyle(HelioTheme.navy)
                                Text(String(format: "%.0f W/m²", day.avgRadiation ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(HelioTheme.inkMuted)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    if let errorMessage = vm.errorMessage{
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
            .refreshable { await vm.load()}
        }
        .task(id: session.selectedMeterId){
            await vm.load()
        }
    }
    
    private func dayTitle(_ day: Date) -> String {
        Calendar.current.isDateInToday(day) ? "Today" : day.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func tempText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.0f°C", value)
    }
    
    private func percent(_ value: Double?) -> String{
        guard let value else {return "-" }
        return String(format: "%.0f%%", value)
    }
    
    private func weatherIcon(cloud: Double?, rain: Double) -> String{
        if rain > 1 { return "cloud.rain.fill"}
        if (cloud ?? 0) > 70 { return "cloud.fill"}
        if (cloud ?? 0) > 35 { return "cloud.sun.fill"}
        return "sun.max.fill"
    }
}

private struct WeatherCard<Content: View>:View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6){
            content
        }
        .padding(HelioTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background{
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .fill(HelioTheme.surface)
                .shadow(color: HelioTheme.cardShadow, radius: 16, y:8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .strokeBorder(HelioTheme.hairline, lineWidth: 1)
        }
    }
}
