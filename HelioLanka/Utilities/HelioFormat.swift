//
//  HelioFormat.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Foundation

enum HelioFormat{
    static func amount(_ value: Double, fractionDigits: Int = 2) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = fractionDigits
        nf.maximumFractionDigits = fractionDigits
        nf.usesGroupingSeparator = true
        nf.locale = Locale(identifier: "en_LK")
        return nf.string(from: NSNumber(value:value)) ?? String(format: "%.\(fractionDigits)f", value)
    }
    
    static func energyKwh(_ value: Double) -> String {"\(amount(value)) kWh"}
    
    static func energyKwh(_ value: Double?) -> String {
        guard let value else {return "- kWh"}
        return energyKwh(value)
    }
    
    static func powerKw(_ value: Double?) -> String {
        guard let value else {return "- kW"}
        return "\(amount(value)) kW"
    }
    
    static func currency(_ value: Double) -> String {"LKR \(amount(value))"}
}
