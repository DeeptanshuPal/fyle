//
//  CoreDataManager+Document.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import CoreData
import UIKit

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
        
        // Schedule notifications if reminderDate is set
        if reminderDate != nil, let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleLocalNotifications(for: [document])
        }
        
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
    
    /// Fetch all the documents with reminders
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
    
    /// Fetch all shared documents
    func fetchShares() -> [Share] {
        let request: NSFetchRequest<Share> = Share.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching shares: \(error)")
            return []
        }
    }
    
    /// Deletes a document from Core Data and removes its scheduled notifications
    func deleteDocument(_ document: Document) {
        let center = UNUserNotificationCenter.current()
        let objectIDString = document.objectID.uriRepresentation().absoluteString
        let suffixes = ["_7days", "_dayBefore", "_today", "_12hours"]
        let identifiers = suffixes.map { objectIDString + $0 }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        context.delete(document)
        saveContext()
    }
}
