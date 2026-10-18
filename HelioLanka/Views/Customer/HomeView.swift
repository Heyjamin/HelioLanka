//
//  HomeView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import SwiftUI

struct MeterPicker: View {
    let session: SessionManager
    private var meters: [LinkedMeter] {
        if case .customer(let user) = session.phase {
            return user.allMeters
        }
        return[]
    }
    
    var body: some View {
        if meters.count > 1 {
            Menu {
                ForEach(meters) { meter in
                    Button {
                        session.selectedMeterId = meter.meterId
                    } label: {
                        if session.selectedMeterId == meter.meterId {
                            Label("\(meter.installationName) . \(meter.meterId)", systemImage: "checkmark")
                        }else{
                            Text("\(meter.installationName) . \(meter.meterId)")
                        }
                    }
                }
            } label: {
                Label(session.selectedMeterId, systemImage: "bolt.horizontal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HelioTheme.navy)
            }
        } else if let only = meters.first {
            Text(only.meterId)
                .font(.caption.weight(.semibold))
                .foregroundStyle(HelioTheme.inkMuted)
        }
    }
}

struct HomeView: View {
    let user: UserMe
    let session: SessionManager
    @State private var vm: HomeViewModel
    
    init(user:UserMe, session: SessionManager) {
        self.user = user
        self.session = session
        _vm = State(initialValue: HomeViewModel(session: session))
    }
    
    var body: some View {
        ZStack{
            HelioBackground()
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                    HStack{
                        VStack(alignment: .leading, spacing: 4){
                            Text("Home")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(HelioTheme.navy)
                            Text(user.displayName)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }
                        Spacer()
                        MeterPicker(session: session)
                    }
                    
                    if vm.isLoading && vm.composite == nil {
                        ProgressView("Loading your site...")
                            .tint(HelioTheme.ocean)
                    }
                    
                    if let site = vm.composite{
                        HomeCard{
                            Text(site.installation.installationName)
                                .font(.headline)
                                .foregroundStyle(HelioTheme.navy)
                            Text("\(site.provicne.name) . \(site.district.name) . \(site.substation.name)")
                                .font(.subheadline)
                                .foregroundStyle(HelioTheme.inkMuted)
                            if let address = site.installation.address, !address.isEmpty{
                                Text(address)
                                    .font(.footnote)
                                    .foregroundStyle(HelioTheme.inkMuted)
                            }
                        }
                        
                        HomeCard {
                            Text("Today")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HelioTheme.inkMuted)
                            Text(HelioFormat.energyKwh(vm.todayExportKwh))
                                .font(.system(size:36,weight: .bold, design: .rounded))
                                .foregroundStyle(HelioTheme.navy)
                            Text("Sum of today's intervals")
                                .font(.caption)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],spacing: 12) {
                            stat("Live", HelioFormat.powerKw(site.lastReading?.instantaneousPowerKw))
                            stat("Last interval", HelioFormat.energyKwh(site.lastReading?.intervalExportKwh))
                            stat("Cumilative", HelioFormat.energyKwh(site.lastReading?.cumilativeExportKwh))
                            stat("Capacity", HelioFormat.currency(site.installation.tariffRate))
                        }
                    }
                    
                    HomeCard {
                        Text("Recent intervals")
                            .font(.headline)
                            .foregroundStyle(HelioTheme.navy)
                        if vm.latestIntervals.isEmpty && !vm.isLoading{
                            Text("No intervals yet.")
                                .font(.footnote)
                                .foregroundStyle(HelioTheme.inkMuted)
                        }
                        ForEach(vm.latestIntervals) { row in
                            HStack {
                                Text(row.timestampUtc.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundStyle(HelioTheme.inkMuted)
                                Spacer()
                                Text(HelioFormat.energyKwh(row.intervalExportKwh))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(HelioTheme.navy)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(HelioTheme.screenPadding)
            }
            .refreshable {await vm.load() }
        }
        .task(id: session.selectedMeterId){
            await vm.load()
        }
    }
    
    
    private func stat(_ title: String, _ value: String) -> some View {
        HomeCard{
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(HelioTheme.inkMuted)
            Text(value)
                .font(.headline)
                .foregroundStyle(HelioTheme.navy)
        }
    }
    
}

private struct HomeCard<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6){
            content
        }
        .padding(HelioTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                .fill(.white.opacity(0.72))
        )
    }
}
