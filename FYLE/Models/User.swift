//
//  User.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 03/03/25.
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {
    @NSManaged public var username: String?
    @NSManaged public var email: String?

    // Class method for fetch request
    public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
}

extension User: Identifiable {
    public var id: UUID {
        return UUID()
    }
}
