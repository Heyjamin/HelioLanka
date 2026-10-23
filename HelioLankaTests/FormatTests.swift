//
//  FormatTests.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-23.
//

import Testing
@testable import HelioLanka

struct FormatTests {
    @Test func nilEnergyAndPowerUseDashes() {
        let missingEnergy: Double? = nil
        let missingPower: Double? = nil
        #expect(HelioFormat.energyKwh(missingEnergy) == "- kWh")
        #expect(HelioFormat.powerKw(missingPower) == "- kW")
    }

    @Test func energyAppendsTheUnit() {
        #expect(HelioFormat.energyKwh(1.5) == "1.50 kWh")
    }

    @Test func powerAppendsTheUnit() {
        #expect(HelioFormat.powerKw(3.25) == "3.25 kW")
    }

    @Test func currencyUsesTheLkrPrefix() {
        #expect(HelioFormat.currency(10) == "LKR 10.00")
        #expect(HelioFormat.currency(1234.5) == "LKR 1,234.50")
    }

    @Test func negativeAmountKeepsTwoFractionDigits() {
        #expect(HelioFormat.amount(-4, fractionDigits: 2) == "-4.00")
    }
}

