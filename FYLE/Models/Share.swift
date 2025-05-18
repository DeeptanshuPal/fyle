//
//  Share.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 03/03/25.
//

import Foundation
import CoreData

@objc(Share)
public class Share: NSManagedObject {
    @NSManaged public var userId: String?
    @NSManaged public var permissions: String?
    @NSManaged public var document: Document?

    // Class method for fetch request
    public class func fetchRequest() -> NSFetchRequest<Share> {
        return NSFetchRequest<Share>(entityName: "Share")
    }
}

extension Share: Identifiable {
    public var id: UUID {
        return UUID()
    }
}
