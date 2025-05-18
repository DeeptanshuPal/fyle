//
//  FileViewModel.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class FileViewModel: ObservableObject {
    @Published var files: [File] = DataManager.shared.getFiles()

    // Define reminderLeadTime if it's missing, for example, 1 day before the expiration
    let reminderLeadTime: TimeInterval = 60 * 60 * 24 // 1 day in seconds

    // Add a new file
    func addFile(data: Data, fileName: String, category: String, summary: String, isConfidential: Bool, expirationDate: Date?, fileType: String, lastModified: Date) {
        guard let filePath = FileManagerService.shared.saveFile(data: data, fileName: fileName) else { return }

        let newFile = File(
            id: UUID(),
            name: fileName,
            category: category,
            createdDate: Date(),
            expirationDate: expirationDate,
            summary: summary,
            isConfidential: isConfidential,
            isFavorite: false,
            sharedWith: [],
            filePath: filePath,
            fileType: fileType, // Add file type here
            lastModified: lastModified // Add last modified date here
        )

        DataManager.shared.addFile(newFile)
        files = DataManager.shared.getFiles()

        // If expiration date exists, create a reminder
        if let expirationDate = expirationDate {
            let reminderDate = expirationDate.addingTimeInterval(-reminderLeadTime) // Adjust reminder based on user preferences
            createReminder(for: newFile, reminderDate: reminderDate)
        }
    }

    private func createReminder(for file: File, reminderDate: Date) {
        let reminder = Reminder(
            id: UUID(),
            fileID: file.id,
            reminderDate: reminderDate,
            notificationFrequency: .once, // Adjust this based on user's preference (once, daily, etc.)
            reminderType: .once, // Adjust this based on user's preference (one-time, recurring, etc.)
            status: .active // Adjust the status (active, pending, completed)
        )
        DataManager.shared.reminders.append(reminder)
    }

    // Delete a file
    func deleteFile(file: File) {
        FileManagerService.shared.deleteFile(at: file.filePath)
        DataManager.shared.removeFile(file)
        files = DataManager.shared.getFiles() // Update the view
    }

    // Mark a file as favorite
    func toggleFavorite(for file: File) {
        var updatedFile = file
        updatedFile.isFavorite.toggle()
        DataManager.shared.updateFile(updatedFile)
        files = DataManager.shared.getFiles() // Update the view
    }

    // Share a file with a user
    func shareFile(file: File, withUser username: String) {
        var updatedFile = file
        if !updatedFile.sharedWith.contains(username) {
            updatedFile.sharedWith.append(username)
            DataManager.shared.updateFile(updatedFile)
            files = DataManager.shared.getFiles() // Update the view
        }
    }
}
