//
//  HekioTheme.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI

enum HelioTheme{
    static let navy = Color(red: 0.06, green: 0.16, blue: 0.38)
    static let ocean = Color(red: 0.227, green: 0.486, blue: 0.647)
    static let oceanDark = Color(red: 0.169, green: 0.373, blue: 0.494)
    static let sky = Color(red: 0.55, green: 0.78, blue: 0.94)
    static let skySoft = Color(red: 0.72, green: 0.88, blue: 0.98)
    static let gold = Color(red: 0.788, green: 0.635, blue: 0.153)
    static let leaf = Color(red: 0.18, green: 0.62, blue: 0.42)
    static let deep = Color(red: 0.05, green: 0.12, blue: 0.18)

    static let ink = navy
    static let inkMuted = Color(red: 0.14, green: 0.28, blue: 0.42)

    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardRadius: CGFloat = 20
    static let fieldRadius: CGFloat = 12
    static let controlRadius: CGFloat = 14
    static let gridSpacing: CGFloat = 12
    
    static let ctaGradient = LinearGradient(colors: [navy,leaf], startPoint: .leading, endPoint: .trailing)
    
}

struct HelioBackground: View{
    var body: some View {
        LinearGradient(
            colors: [
                HelioTheme.sky.opacity(0.95),
                HelioTheme.ocean.opacity(0.35),
                HelioTheme.skySoft
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
