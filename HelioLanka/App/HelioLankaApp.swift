//
//  HelioLankaApp.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI

@main
struct HelioLankaApp: App {
    @State private var session = SessionManager()
    
    var body:some Scene{
        WindowGroup {
            ContentView()
                .environment(session)
                .task{
                    await session.bootstrap()
                }
        }
    }
}
