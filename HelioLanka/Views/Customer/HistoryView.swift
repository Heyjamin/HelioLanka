//
//  HistoryView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Charts
import SwiftUI

struct HistoryView: View {
    let session: SessionManager
    @State private var vm: HistoryViewModel
    @State private var range: HistoryRange = .days30
    
    enum HistoryRange: String, CaseIterable {
        case days7 = "7D"
        case days30 = "30D"
        case days90 = "90D"
        
        var dayCount: Int {
            switch self {
            case .days7: 7
            case .days30: 30
            case .days90: 90
            }
        }
    }
    
    init (session: SessionManager){
        self.session = session
        _vm = State(initialValue: HistoryViewModel(session: session))
    }
    
    /// Newest N daily totals. 7D means seven stored days, not seven empty calendar slots.
    private var filtered: [(date: Date, kwh: Double)]{
        Array(vm.days.suffix(range.dayCount))
    }
    
    private var total: Double { filtered.map(\.kwh).reduce(0, +)}
    private var average: Double { filtered.isEmpty ? 0 : total / Double(filtered.count) }
    
    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                    HStack{
                        Text("History")
                            .font(.system(size: 28,weight: .bold, design: .rounded))
                            .foregroundStyle(HelioTheme.navy)
                        Spacer()
                        MeterPicker(session: session)
                    }
                    
                    Picker("Range", selection: $range){
                        ForEach(HistoryRange.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if vm.isLoading && vm.days.isEmpty {
                        ProgressView("Loading history...")
                            .tint(HelioTheme.ocean)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12){
                        stat("Total", HelioFormat.energyKwh(total))
                        stat("Daily avg", HelioFormat.energyKwh(average))
                    }
                    
                    HistoryCard{
                        Text("Export")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        if filtered.isEmpty && !vm.isLoading {
                            Text("No days in this range.")
                                .font(.footnote)
                                .foregroundStyle(HelioTheme.inkMuted)
                                .frame(maxWidth: .infinity, minHeight: 180)
                        }else{
                            Chart(filtered, id: \.date) { item in
                            BarMark(
                                x: .value("Day", item.date, unit: .day),
                                y: .value("kWh", item.kwh)
                            )
                            .foregroundStyle(HelioTheme.leaf)
                            }
                            .frame(height: 220)
                        }
                    }
                    
                    HistoryCard{
                        Text("Daily totals")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        ForEach(filtered.reversed().prefix(14), id: \.date) { day in
                            HStack{
                                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(HelioTheme.inkMuted)
                                Spacer()
                                Text(HelioFormat.energyKwh(day.kwh))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(HelioTheme.navy)
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
    
    private func stat(_ title: String, _ value: String) -> some View{
        HistoryCard{
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(HelioTheme.inkMuted)
            Text(value)
                .font(.headline)
                .foregroundStyle(HelioTheme.navy)
        }
    }
    
}


private struct HistoryCard<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading,spacing: 6){
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
