//
//  Document.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 03/03/25.
//

import Foundation
import CoreData

@objc(Document)
public class Document: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var summaryData: Data?
    @NSManaged public var expiryDate: Date?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var pdfData: Data?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var reminderDate: Date?
    @NSManaged public var categories: NSSet?
    @NSManaged public var sharedWith: NSSet?


    // Class method for fetch request
    public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }
}

// MARK: Generated accessors for categories
extension Document {
    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)
}

// MARK: Generated accessors for sharedWith
extension Document {
    @objc(addSharedWithObject:)
    @NSManaged public func addToSharedWith(_ value: Share)

    @objc(removeSharedWithObject:)
    @NSManaged public func removeFromSharedWith(_ value: Share)

    @objc(addSharedWith:)
    @NSManaged public func addToSharedWith(_ values: NSSet)

    @objc(removeSharedWith:)
    @NSManaged public func removeFromSharedWith(_ values: NSSet)
}

extension Document: Identifiable {
    public var id: UUID {
        return UUID()
    }
}
