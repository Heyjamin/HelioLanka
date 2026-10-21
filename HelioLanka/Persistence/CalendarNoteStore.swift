//
//  CalendarNoteStore.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-21.
//

import CoreData
import Foundation

/// Private calendar note. Stored on the phone and never sent to the API.
final class CalendarNote: Identifiable {
    var id: UUID
    var dayStart: Date
    var title: String
    var bodyText: String
    var isReminder: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dayStart: Date,
        title: String,
        bodyText: String = "",
        isReminder: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0
    ) {
        self.id = id
        self.dayStart = Calendar.current.startOfDay(for: dayStart)
        self.title = title
        self.bodyText = bodyText
        self.isReminder = isReminder
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@MainActor
final class CalendarNoteStore {
    private var context: NSManagedObjectContext { HelioPersistence.viewContext }

    func notes(on day: Date) throws -> [CalendarNote] {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return try fetch(from: start, to: end)
    }

    func notesInMonth(containing day: Date) throws -> [CalendarNote] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: day)
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start)
        else { return [] }
        return try fetch(from: start, to: end)
    }

    func upsert(_ note: CalendarNote) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CalendarNoteRecord")
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        request.fetchLimit = 1
        let row: NSManagedObject
        if let existing = try context.fetch(request).first {
            row = existing
        } else if let entity = NSEntityDescription.entity(forEntityName: "CalendarNoteRecord", in: context) {
            row = NSManagedObject(entity: entity, insertInto: context)
            row.setValue(note.id.uuidString, forKey: "id")
            row.setValue(note.createdAt, forKey: "createdAt")
        } else {
            return
        }
        row.setValue(note.dayStart, forKey: "dayStart")
        row.setValue(note.title, forKey: "title")
        row.setValue(note.bodyText, forKey: "bodyText")
        row.setValue(note.isReminder, forKey: "isReminder")
        row.setValue(Int16(note.reminderHour), forKey: "reminderHour")
        row.setValue(Int16(note.reminderMinute), forKey: "reminderMinute")
        row.setValue(Date(), forKey: "updatedAt")
        try context.save()
    }

    func delete(_ note: CalendarNote) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CalendarNoteRecord")
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        for row in try context.fetch(request) {
            context.delete(row)
        }
        try context.save()
    }

    private func fetch(from start: Date, to end: Date) throws -> [CalendarNote] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CalendarNoteRecord")
        request.predicate = NSPredicate(format: "dayStart >= %@ AND dayStart < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request).compactMap(Self.map)
    }

    private static func map(_ row: NSManagedObject) -> CalendarNote? {
        guard let idString = row.value(forKey: "id") as? String,
              let id = UUID(uuidString: idString),
              let day = row.value(forKey: "dayStart") as? Date,
              let title = row.value(forKey: "title") as? String
        else { return nil }
        let note = CalendarNote(
            id: id,
            dayStart: day,
            title: title,
            bodyText: row.value(forKey: "bodyText") as? String ?? "",
            isReminder: (row.value(forKey: "isReminder") as? NSNumber)?.boolValue ?? false,
            reminderHour: (row.value(forKey: "reminderHour") as? NSNumber)?.intValue ?? 9,
            reminderMinute: (row.value(forKey: "reminderMinute") as? NSNumber)?.intValue ?? 0
        )
        if let created = row.value(forKey: "createdAt") as? Date { note.createdAt = created }
        if let updated = row.value(forKey: "updatedAt") as? Date { note.updatedAt = updated }
        return note
    }
}
