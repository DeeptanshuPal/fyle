//
//  Category.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 03/03/25.
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var categoryImage: String?
    @NSManaged public var categoryColour: String?
    @NSManaged public var documents: NSSet?

    // Class method for fetch request
    public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
}

// MARK: Generated accessors for documents
extension Category {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}

extension Category: Identifiable {
    public var id: UUID {
        return UUID()
    }
}
