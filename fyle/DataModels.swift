//
//  DataModels.swift
//  fyle
//
//  Created by Sana Sreeraj on 12/11/24.
//

import Foundation
import UIKit

// MARK: - FileType Enum
enum FileType {
    case image, pdf, word, other
}

// MARK: - FileModel
struct FileModel {
    var id: String
    var name: String
    var type: FileType
    var creationDate: Date
    var expirationDate: Date?
    var categoryId: String  // Link to Category
    var isConfidential: Bool
    var url: URL
    var tags: [String]?
    var reminders: [ReminderModel]  // Relationship with reminders
    var isFavorite: Bool = false
    var sharedWithUserIds: [String]? = nil  // For tracking sharing

    init(id: String, name: String, type: FileType, creationDate: Date, expirationDate: Date?, categoryId: String, isConfidential: Bool, url: URL, reminders: [ReminderModel] = [], tags: [String]? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.categoryId = categoryId
        self.isConfidential = isConfidential
        self.url = url
        self.reminders = reminders
        self.tags = tags
        self.isFavorite = isFavorite
    }
    
    // Helper to convert images to PDF and set URL
    static func saveImagesAsPDF(images: [UIImage], pdfName: String) -> URL? {
        // Implementation to create PDF and return file URL
        return nil  // Placeholder for actual PDF URL
    }
}

// MARK: - ReminderModel
struct ReminderModel {
    var id: String
    var fileId: String
    var reminderDate: Date
    var isActive: Bool
    var reminderType: String  // e.g., "1 month before"
    var isRecurring: Bool = false

    init(id: String, fileId: String, reminderDate: Date, isActive: Bool = true, reminderType: String, isRecurring: Bool = false) {
        self.id = id
        self.fileId = fileId
        self.reminderDate = reminderDate
        self.isActive = isActive
        self.reminderType = reminderType
        self.isRecurring = isRecurring
    }
    
    // Helper for scheduling a reminder as a local notification
    func scheduleReminder() {
        // Implementation for setting up local notifications
    }
}

// MARK: - UserModel
struct UserModel {
    var id: String
    var username: String
    var email: String
    var name: String
    var age: Int
    var business: String
    var files: [FileModel]
    var reminders: [ReminderModel]
    var preferences: [String: Any]?  // User-specific settings

    init(id: String, username: String, email: String, name: String, age: Int, business: String, files: [FileModel], reminders: [ReminderModel], preferences: [String: Any]? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.name = name
        self.age = age
        self.business = business
        self.files = files
        self.reminders = reminders
        self.preferences = preferences
    }
    
    // Helper function to add a file
    mutating func addFile(_ file: FileModel) {
        files.append(file)
    }
    
    // Helper function to add a reminder
    mutating func addReminder(_ reminder: ReminderModel) {
        reminders.append(reminder)
    }
}

// MARK: - CategoryModel
struct CategoryModel {
    var id: String
    var name: String  // E.g., "Insurance", "Education"

    // Fetch all files in this category
    func getFilesInCategory(from user: UserModel) -> [FileModel] {
        return user.files.filter { $0.categoryId == self.id }
    }
}

// MARK: - SharedFileModel
struct SharedFileModel {
    var fileId: String
    var sharedByUserId: String
    var sharedWithUserIds: [String]  // List of users the file was shared with
    var sharedDate: Date
    var accessPermissions: String  // e.g., "view-only", "can-edit"

    init(fileId: String, sharedByUserId: String, sharedWithUserIds: [String], sharedDate: Date, accessPermissions: String = "view-only") {
        self.fileId = fileId
        self.sharedByUserId = sharedByUserId
        self.sharedWithUserIds = sharedWithUserIds
        self.sharedDate = sharedDate
        self.accessPermissions = accessPermissions
    }
}
