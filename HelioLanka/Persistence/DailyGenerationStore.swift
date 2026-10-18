//
//  DailyGenerationStore.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import CoreData
import Foundation

struct DailyGeneration: Identifiable {
    var id: String {key}
    var key: String
    let meterId: String
    let dayStart: Date
    let exportKwh: Double
}

@MainActor
final class DailyGenerationStore {
    private var context: NSManagedObjectContext { HelioPersistence.viewContext }
    
    /// Rebuilt daily totals from interval readings (sum of intervalExportKwh per calendar day).
    func sync(from readings: [ReadingRow], meterId: String) throws {
        var byDay: [Date: Double] = [:]
        let cal = Calendar.current
        for reading in readings{
            let day = cal.startOfDay(for: reading.timestampUtc)
            byDay[day, default: 0] += reading.intervalExportKwh
        }
        
        for (day, kwh) in byDay {
            let key = "\(meterId)|\(Int(day.timeIntervalSince1970))"
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyExport")
            request.predicate = NSPredicate(format: "key == %@", key)
            request.fetchLimit = 1
            if let existing = try context.fetch(request).first {
                existing.setValue(kwh, forKey: "exportKwh")
                existing.setValue(Date(), forKey: "updatedAt")
            } else if let entity = NSEntityDescription.entity(forEntityName: "DailyExport", in: context) {
                let row = NSManagedObject(entity: entity, insertInto: context)
                row.setValue(key, forKey: "key")
                row.setValue(meterId, forKey: "meterId")
                row.setValue(day, forKey: "dayStart")
                row.setValue(kwh, forKey: "exportKwh")
                row.setValue(Date(), forKey: "updatedAt")
            }
        }
        
        try prune(meterId: meterId)
        try context.save()
    }
    
    /// Oldest first, so the chart can take the newest 7, 30, or 90 with `suffix`.
    func last90Days(meterId: String) throws -> [DailyGeneration] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyExport")
        request.predicate = NSPredicate(format: "meterId == %@ AND dayStart >= %@", meterId, cutoff as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: true)]
        return try context.fetch(request).compactMap(Self.map)
    }
    
    private func prune(meterId: String) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyExport")
        request.predicate = NSPredicate(format: "meterId == %@ AND dayStart < %@", meterId, cutoff as NSDate)
        for row in try context.fetch(request){
            context.delete(row)
        }
    }
    
    private static func map(_ row: NSManagedObject) -> DailyGeneration? {
        guard let key = row.value(forKey: "key") as? String,
              let meterId = row.value(forKey: "meterId") as? String,
              let day = row.value(forKey: "dayStart") as? Date,
              let kwh = row.value(forKey: "exportKwh") as? Double
        else { return nil }
        return DailyGeneration(key: key, meterId: meterId, dayStart: day, exportKwh: kwh)
    }
}
