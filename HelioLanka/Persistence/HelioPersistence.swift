//
//  HelioPersistence.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import CoreData

/// On-device store for daily export totals. The model is built  in code.
enum HelioPersistence {
    static let container: NSPersistentContainer = {
        let model = NSManagedObjectModel()
        model.entities = [dailyExportEntity(), calendarNoteEntity()]
        
        let container = NSPersistentContainer(name: "HelioLanka", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        description.url = support.appendingPathComponent("HelioLanka.sqlite")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores{ _, error in
            if let error{
                fatalError("Core Data store failed: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    static var viewContext: NSManagedObjectContext { container.viewContext }
    
    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription{
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
    
    private static func dailyExportEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DailyExport"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute("key", .stringAttributeType),
            attribute("meterId", .stringAttributeType),
            attribute("dayStart", .dateAttributeType),
            attribute("exportKwh", .doubleAttributeType),
            attribute("updatedAt", .dateAttributeType),
        ]
        return entity
    }
    
    private static func calendarNoteEntity() -> NSEntityDescription{
        let entity = NSEntityDescription()
        entity.name = "CalendarNoteRecord"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute("id", .stringAttributeType),
            attribute("dayStart", .dateAttributeType),
            attribute("title", .stringAttributeType),
            attribute("bodyText", .stringAttributeType, optional: true),
            attribute("isReminder", .booleanAttributeType),
            attribute("reminderHour", .integer16AttributeType),
            attribute("reminderMinute", .integer16AttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
        ]
        return entity
    }
}
