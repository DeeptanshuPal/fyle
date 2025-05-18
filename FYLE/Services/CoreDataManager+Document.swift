//
//  CoreDataManager+Document.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import CoreData
import UserNotifications

extension CoreDataManager {
    // MARK: - Document Operations
    
    /// Creates a new Document entity and saves it to Core Data
    func createDocument(
        name: String,
        summaryData: Data?,
        expiryDate: Date?,
        thumbnailData: Data?,
        pdfData: Data?,
        reminderDate: Date? = nil,
        isFavorite: Bool = false,
        categories: NSSet? = nil,
        sharedWith: NSSet? = nil
    ) -> Document {
        let document = Document(context: context)
        document.name = name
        document.summaryData = summaryData
        document.expiryDate = expiryDate
        document.thumbnail = thumbnailData
        document.pdfData = pdfData
        document.dateAdded = Date()
        document.reminderDate = reminderDate
        document.isFavorite = isFavorite
        document.categories = categories
        document.sharedWith = sharedWith
        saveContext()
        return document
    }
    
    /// Fetches all categories from Core Data
    func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    /// Fetches all documents from Core Data
    func fetchDocuments() -> [Document] {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching documents: \(error)")
            return []
        }
    }
    
    /// fetch all the documents with reminders
    func fetchDocumentsWithReminders() -> [Document] {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "reminderDate != nil")
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching documents with reminders: \(error)")
            return []
        }
    }
    
    /// fetch all shared documents
    func fetchShares() -> [Share] {
        let request: NSFetchRequest<Share> = Share.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching shares: \(error)")
            return []
        }
    }
    
    /// Deletes a document from Core Data
    func deleteDocument(_ document: Document) {
        context.delete(document)
        saveContext()
    }
    
    func scheduleNotification(for document: Document) {
            guard let reminderDate = document.reminderDate else { return }
            guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
            guard let reminderDate = document.reminderDate else { return }
            
            // Convert reminderDate to user's local time zone
            let calendar = Calendar.current
            let localReminderDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "📅 Document Expiry Reminder"
            content.body = "\(document.name ?? "Your document") expires on \(document.formattedExpiryDate ?? "soon")!"
            content.sound = .default
            
            // Set the trigger for the notification (1 day before expiry)
            let triggerDate = calendar.date(byAdding: .day, value: -1, to: reminderDate)!
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            // Use document's ID as the request identifier
            let requestID = document.objectID.uriRepresentation().absoluteString
            let request = UNNotificationRequest(
                identifier: requestID,
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                } else {
                    print("Scheduled notification for \(document.name ?? "unnamed document")")
                }
            }
        }
}
