//
//  CoreDataManager.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 03/03/25.
//

import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FyleModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Document Management
    func createDocument(name: String, summaryData: Data?, expiryDate: Date?, thumbnail: Data?, pdfData: Data?, reminderDate: Date?, categories: NSSet) -> Document {
        let document = Document(context: context)
        document.name = name
        document.summaryData = summaryData
        document.expiryDate = expiryDate
        document.thumbnail = thumbnail
        document.pdfData = pdfData
        document.reminderDate = reminderDate
        document.categories = categories
        saveContext()
        return document
    }
    
    // MARK: - Category Management
    func createCategory(name: String, image: String, color: UIColor) -> Category {
        let category = Category(context: context)
        category.name = name
        category.categoryImage = image
        category.categoryColour = colorToString(color) // Convert UIColor to string
        saveContext()
        return category
    }
    
    private func colorToString(_ color: UIColor) -> String {
        // Map UIColor to a string representation (e.g., system color names)
        if color == .systemYellow { return "systemYellow" }
        if color == .systemBrown { return "systemBrown" }
        if color == .systemTeal { return "systemTeal" }
        if color == .systemGreen { return "systemGreen" }
        if color == .systemPink { return "systemPink" }
        if color == .systemBlue { return "systemBlue" }
        if color == .green { return "green" }
        if color == .systemPurple { return "systemPurple" }
        if color == .orange { return "orange" }
        if color == .systemIndigo { return "systemIndigo" }
        if color == .darkGray { return "darkGray" }
        if color == .systemOrange { return "systemOrange" }
        if color == .systemRed { return "systemRed" }
        return "unknown" // Default fallback
    }
    
    func populateSampleCategories() {
        let categoriesData = [
            ("Home", "house.fill", UIColor.systemYellow),
            ("Vehicle", "car.fill", UIColor.systemBrown),
            ("Personal IDs", "person.text.rectangle.fill", UIColor.systemBlue),
            ("School", "book.fill", UIColor.systemGray),
            ("Bank", "dollarsign.bank.building.fill", UIColor.systemGreen),
            ("Medical", "cross.case.fill", UIColor.systemPink),
            ("College", "graduationcap.fill", UIColor.systemTeal),
            ("Land", "map.fill", UIColor.green),
            ("Warranty", "scroll.fill", UIColor.systemPurple),
            ("Family", "figure.2.and.child.holdinghands", UIColor.orange),
            ("Travel", "airplane", UIColor.systemBrown),
            ("Business", "coat", UIColor.systemIndigo),
            ("Insurance", "shield.fill", UIColor.darkGray),
            ("Education", "a.book.closed.fill", UIColor.systemOrange),
            ("Emergency", "phone.fill", UIColor.systemRed),
            ("Miscellaneous", "tray.full.fill", UIColor.systemYellow)
        ]
        
        // Check if categories are already populated to avoid duplicates
        let existingCategories = fetchCategories()
        let existingNames = Set(existingCategories.map { $0.name ?? "" })
        
        for (name, image, color) in categoriesData {
            if !existingNames.contains(name) {
                let _ = createCategory(name: name, image: image, color: color)
            }
        }
        print("Sample categories populated or already exist.")
    }
    
    func fetchAllCategories() -> [Category] { // Renamed to avoid conflict
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            let categories = try context.fetch(fetchRequest)
            return categories
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
}
