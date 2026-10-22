//
//  CustomerTabShell.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-17.
//

import SwiftUI

struct CustomerTabShell: View {
    let user: UserMe
    let session: SessionManager
    
    var body: some View{
        TabView {
            HomeView(user: user, session: session)
            .tabItem { Label("Home", systemImage: "sun.max.fill")}
            
            HistoryView(session:session)
            .tabItem {Label("History", systemImage:"chart.xyaxis.line")}
            
            WeatherView(session: session)
            .tabItem { Label("Weather", systemImage:"cloud.sun.fill")}
            
            EarnView(session: session)
            .tabItem{Label("Earn", systemImage: "banknote.fill")}
            
            CalendarView(session: session)
            .tabItem { Label("Calendar", systemImage:"calendar")}
            
            AccountView(user: user, session: session)
            .tabItem { Label("Account", systemImage: "person.crop.circle")}
        }
        .tint(HelioTheme.brandTeal)
    }
}

private struct PlaceholderTab:View{
    let title: String
    let systemImage: String
    let user: UserMe
    let session: SessionManager
    var showsSignOut = false
    
    var body: some View{
        ZStack{
            HelioBackground()
            VStack(alignment: .leading, spacing:12){
                Label(title, systemImage: systemImage)
                    .font(.system(size:28, weight: .bold, design: .rounded))
                    .foregroundStyle(HelioTheme.navy)
                
                Text(user.displayName)
                    .font(.title3)
                    .foregroundStyle(HelioTheme.ink)
                
                Text(user.email)
                    .foregroundStyle(HelioTheme.inkMuted)
                
                Text(meterLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HelioTheme.ocean)
                
                Text("Phase 05 - placeholder")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(HelioTheme.leaf)
                    .padding(.top,8)
                
                if showsSignOut {
                    Button("Sign out"){
                        Task {await session.signOut()}
                    }
                    .buttonStyle(.bordered)
                    .tint(HelioTheme.navy)
                    .padding(.top,12)
                }
                
                Spacer()
            }
            .padding(HelioTheme.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private var meterLine: String{
        if session.selectedMeterId.isEmpty{
            return "No meter selected"
        }
        return "Meter \(session.selectedMeterId)"
    }
}
