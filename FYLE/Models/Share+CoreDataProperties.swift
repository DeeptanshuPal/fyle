//
//  Share+CoreDataProperties.swift
//  FYLE
//
//  Created by admin41 on 12/03/25.
//
//

import Foundation
import CoreData


extension Share {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Share> {
        return NSFetchRequest<Share>(entityName: "Share")
    }

    @NSManaged public var permissions: String?
    @NSManaged public var userId: String?
    @NSManaged public var fileData: Data?
    @NSManaged public var fileName: String?
    @NSManaged public var document: Document?

}

extension Share : Identifiable {

}
