//
//  CoreDataManager+Document.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import CoreData

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
}
