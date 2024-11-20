//
//  File.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

struct File: Identifiable {
    var id: UUID
    var name: String // File name entered by the user
    var category: String // Category associated with the file
    var createdDate: Date
    var expirationDate: Date? // Optional, for files without reminders
    var summary: String // Summary or description of the file
    var isConfidential: Bool // Whether the file is confidential
    var isFavorite: Bool
    var sharedWith: [String] // List of usernames
    var filePath: URL // Location in app storage
    var fileType: String // e.g., "PDF", "Image", etc.
    var lastModified: Date // The last time the file was modified
    var fileSize: Int64? // Optional, for file size in bytes
    var titleImage: URL? // Link to the image associated with the file (optional)
    var reminderDate: Date? // Optional reminder date (if a reminder is set)
}
