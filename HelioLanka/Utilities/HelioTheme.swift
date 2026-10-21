//
//  HekioTheme.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI
import UIKit

enum HelioTheme {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let brandTeal = adaptive(
        light: UIColor(red: 13 / 255, green: 115 / 255, blue: 119 / 255, alpha: 1),
        dark: UIColor(red: 94 / 255, green: 212 / 255, blue: 208 / 255, alpha: 1)
    )

    static let navy = adaptive(
        light: UIColor(red: 0.086, green: 0.098, blue: 0.094, alpha: 1),
        dark: UIColor(red: 0.953, green: 0.961, blue: 0.953, alpha: 1)
    )
    static let ocean = brandTeal
    static let oceanDark = Color(red: 0.04, green: 0.28, blue: 0.29)
    static let sky = Color(red: 0.063, green: 0.071, blue: 0.067)
    static let skySoft = Color(red: 0.110, green: 0.129, blue: 0.122)
    static let gold = adaptive(
        light: UIColor(red: 0.659, green: 0.529, blue: 0.239, alpha: 1),
        dark: UIColor(red: 0.855, green: 0.710, blue: 0.396, alpha: 1)
    )
    static let leaf = adaptive(
        light: UIColor(red: 0.118, green: 0.478, blue: 0.310, alpha: 1),
        dark: UIColor(red: 0.345, green: 0.780, blue: 0.545, alpha: 1)
    )
    static let deep = Color(red: 0.063, green: 0.071, blue: 0.067)

    static let ink = navy
    static let inkMuted = adaptive(
        light: UIColor(red: 0.369, green: 0.408, blue: 0.384, alpha: 1),
        dark: UIColor(red: 0.659, green: 0.690, blue: 0.671, alpha: 1)
    )
    static let danger = adaptive(
        light: UIColor(red: 0.55, green: 0.18, blue: 0.20, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.72, blue: 0.70, alpha: 1)
    )

    static let canvas = adaptive(
        light: UIColor(red: 0.957, green: 0.949, blue: 0.925, alpha: 1),
        dark: UIColor(red: 0.063, green: 0.071, blue: 0.067, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor(white: 1, alpha: 1),
        dark: UIColor(red: 0.110, green: 0.129, blue: 0.122, alpha: 1)
    )
    static let hairline = adaptive(
        light: UIColor(white: 0, alpha: 0.06),
        dark: UIColor(white: 1, alpha: 0.10)
    )
    static let cardShadow = adaptive(
        light: UIColor(white: 0, alpha: 0.06),
        dark: UIColor(white: 0, alpha: 0.45)
    )

    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 28
    static let fieldRadius: CGFloat = 16
    static let controlRadius: CGFloat = 16
    static let gridSpacing: CGFloat = 12

    static let ctaGradient = LinearGradient(
        colors: [brandTeal, brandTeal],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Plate behind the Home “Today” figure.
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.42, blue: 0.43),
            Color(red: 0.05, green: 0.24, blue: 0.26)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct HelioBackground: View {
    var body: some View {
        ZStack {
            HelioTheme.canvas

            Circle()
                .fill(HelioTheme.brandTeal.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 150, y: -280)
        }
        .ignoresSafeArea()
    }
}

/// Capsule used by Continue, Register, Verify, and Save note.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule(style: .continuous).fill(HelioTheme.brandTeal))
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
