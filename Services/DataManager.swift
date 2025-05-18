//
//  DataManager.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class DataManager {
    static let shared = DataManager()

    private init() {}

    // MARK: - Data Storage
    var files: [File] = []  // Store files
    var categories: [Category] = []  // Store categories
    var reminders: [Reminder] = []  // Store reminders
    var users: [User] = []  // Store users

    // MARK: - File Management

    /// Add a new file
    func addFile(_ file: File) {
        files.append(file)
    }

    /// Save a file with detailed parameters
    func saveFile(name: String, category: String, createdDate: Date, expirationDate: Date?, summary: String, isConfidential: Bool, isFavorite: Bool, sharedWith: [String], filePath: URL, fileType: String, fileSize: Int64?, titleImage: URL?, reminderDate: Date?) {
        let newFile = File(
            id: UUID(),
            name: name,
            category: category,
            createdDate: createdDate,
            expirationDate: expirationDate,
            summary: summary,
            isConfidential: isConfidential,
            isFavorite: isFavorite,
            sharedWith: sharedWith,
            filePath: filePath,
            fileType: fileType,
            lastModified: Date(),
            fileSize: fileSize,
            titleImage: titleImage,
            reminderDate: reminderDate
        )
        addFile(newFile)
    }

    /// Fetch files by category or search term
    func fetchFiles(category: String? = nil, searchTerm: String? = nil) -> [File] {
        var filteredFiles = files

        // Filter by category
        if let category = category {
            filteredFiles = filteredFiles.filter { $0.category == category }
        }

        // Filter by search term
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            filteredFiles = filteredFiles.filter { $0.name.localizedCaseInsensitiveContains(searchTerm) }
        }

        return filteredFiles
    }

    /// Get all files
    func getFiles() -> [File] {
        return files
    }

    /// Update an existing file
    func updateFile(_ updatedFile: File) {
        if let index = files.firstIndex(where: { $0.id == updatedFile.id }) {
            files[index] = updatedFile
        }
    }

    /// Remove a file
    func removeFile(_ file: File) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files.remove(at: index)
        }
    }

    // MARK: - Category Management

    /// Add a new category
    func addCategory(_ category: Category) {
        categories.append(category)
    }

    /// Fetch categories (sorted by display order if applicable)
    func getCategories() -> [Category] {
        return categories.sorted { ($0.displayOrder ?? Int.max) < ($1.displayOrder ?? Int.max) }
    }

    /// Update a category
    func updateCategory(_ updatedCategory: Category) {
        if let index = categories.firstIndex(where: { $0.id == updatedCategory.id }) {
            categories[index] = updatedCategory
        }
    }

    /// Remove a category
    func removeCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories.remove(at: index)
        }
    }

    // MARK: - Reminder Management

    /// Add a new reminder
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
    }

    /// Fetch reminders for a file
    func getReminders(forFile fileID: UUID) -> [Reminder] {
        return reminders.filter { $0.fileID == fileID }
    }

    /// Update a reminder
    func updateReminder(_ updatedReminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == updatedReminder.id }) {
            reminders[index] = updatedReminder
        }
    }

    /// Remove a reminder
    func removeReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders.remove(at: index)
        }
    }

    // MARK: - User Management

    /// Add a user
    func addUser(_ user: User) {
        users.append(user)
    }

    /// Fetch users
    func getUsers() -> [User] {
        return users
    }

    /// Update a user
    func updateUser(_ updatedUser: User) {
        if let index = users.firstIndex(where: { $0.id == updatedUser.id }) {
            users[index] = updatedUser
        }
    }

    /// Remove a user
    func removeUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users.remove(at: index)
        }
    }
}
