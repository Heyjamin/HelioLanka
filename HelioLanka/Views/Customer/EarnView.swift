//
//  EarnView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-19.
//

import Charts
import SwiftUI

struct EarnView: View {
    let session: SessionManager
    @State private var vm: EarnViewModel
    
    init(session: SessionManager) {
        self.session = session
        _vm = State(initialValue: EarnViewModel(session: session))
    }
    
    var body: some View {
        ZStack {
            HelioBackground()
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                    HelioBrandLockup(height: 36, showsTagline: false)
                    HStack {
                        Text("Earn")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(HelioTheme.navy)
                        Spacer()
                        MeterPicker(session: session)
                    }
                    
                    if vm.isLoading && vm.forecastDays.isEmpty{
                        ProgressView("Loading earinings...")
                            .tint(HelioTheme.ocean)
                    }
                    
                    EarnCard {
                        Toggle("Use history average kWh/day", isOn: $vm.useHistoryAverage)
                            .tint(HelioTheme.leaf)
                        if let historyAverage = vm.historyAverage{
                            Text("History average: \(HelioFormat.energyKwh(historyAverage))/day")
                                .font(.caption)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }
                        labeledField("Avg kWh / day", value: $vm.avgKwhPerDay)
                            .disabled(vm.useHistoryAverage && (vm.historyAverage ?? 0) > 0)
                        
                        Toggle("Use site tariff", isOn:$vm.useTariffFromSite)
                            .tint(HelioTheme.leaf)
                        labeledField("LKR / kWh", value: $vm.unitRateLkr)
                            .disabled(vm.useTariffFromSite && (vm.tariffFromSite ?? 0) > 0)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(vm.projections) { row in
                            EarnCard{
                                Text(row.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(HelioTheme.inkMuted)
                                Text(HelioFormat.energyKwh(row.generationKwh))
                                    .font(.headline)
                                    .foregroundStyle(HelioTheme.navy)
                                Text(HelioFormat.currency(row.incomeLkr))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HelioTheme.gold)
                            }
                        }
                    }
                    
                    EarnCard {
                        Text("30-day forecast")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        Text("On-device . \(session.forecast.engineName)")
                            .font(.caption)
                            .foregroundStyle(HelioTheme.inkMuted)
                        HStack{
                            Text("Predicted generation")
                                .foregroundStyle(HelioTheme.inkMuted)
                            Spacer()
                            Text(HelioFormat.energyKwh(vm.forecastMonthKwh))
                                .foregroundStyle(HelioTheme.navy)
                        }
                        .font(.subheadline)
                        HStack{
                            Text("Predicted income")
                                .foregroundStyle(HelioTheme.inkMuted)
                            Spacer()
                            Text(HelioFormat.currency(vm.forecastMonthIncome))
                                .foregroundStyle(HelioTheme.gold)
                        }
                        .font(.subheadline)
                        
                        Chart(vm.forecastDays) { day in
                           BarMark(
                            x: .value("Day", day.day, unit: .day),
                            y: .value("kWh", day.predictedKwh)
                           )
                           .foregroundStyle(HelioTheme.leaf)
                        }
                        .frame(height: 160)
                    }
                    
                    if let errorMessage = vm.errorMessage {
                        Text (errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HelioTheme.danger)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
            .refreshable {
                await vm.load()
            }
        }
        .task(id: session.selectedMeterId){
            await vm.load()
        }
    }
    
    private func labeledField(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(HelioTheme.inkMuted)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .foregroundStyle(HelioTheme.navy)
        }
        .font(.subheadline)
    }
}


private struct EarnCard<Content: View> : View {
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
