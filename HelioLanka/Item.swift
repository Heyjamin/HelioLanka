//
//  Item.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
