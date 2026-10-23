//
//  HelioBrandLookup.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import SwiftUI

struct HelioBrandLockup: View {
    var height: CGFloat = 36
    var showsTagline: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: height * 0.22) {
            Image("HelioMark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: height, height: height)
                .clipShape(RoundedRectangle(cornerRadius: height * 0.22, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("Helio")
                        .foregroundStyle(HelioTheme.brandTeal)
                    Text("Lanka")
                        .foregroundStyle(HelioTheme.navy)
                }
                .font(.system(size: height * 0.42, weight: .bold, design: .rounded))

                if showsTagline {
                    Text("Solar Export Intelligence")
                        .font(.system(size: max(9, height * 0.22), weight: .medium))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(HelioTheme.inkMuted)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            showsTagline ? "HelioLanka, Solar Export Intelligence" : "HelioLanka"
        )
    }
}
