//
//  AppEnvironment.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import Foundation

enum AppEnvironment {
    /// Used later for widgets / shared defaults.
    static let appGroupId = "group.lk.heliolanka.app"
    
    static var apiBaseURL: URL {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["HELIO_API_BASE"],
           let url = URL(string: override){
            return url
        }
        #endif
        // Production / UAT API
        return URL (string: "https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws")!
    }
}
