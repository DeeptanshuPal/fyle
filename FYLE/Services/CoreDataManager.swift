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
        
        let existingCategories = fetchAllCategories()
        let existingNames = Set(existingCategories.map { $0.name ?? "" })
        
        for (name, image, color) in categoriesData {
            if !existingNames.contains(name) {
                let _ = createCategory(name: name, image: image, color: color)
            }
        }
        print("Sample categories populated or already exist.")
    }
    
    func fetchAllCategories() -> [Category] {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            let categories = try context.fetch(fetchRequest)
            return categories
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func fetchCategory(byName name: String) -> Category? {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.fetchLimit = 1
        do {
            let categories = try context.fetch(fetchRequest)
            return categories.first
        } catch {
            print("Failed to fetch category with name \(name): \(error)")
            return nil
        }
    }
    
    func fetchReceivedDocuments() -> [Document] {
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isReceived == %@", NSNumber(value: true))
        do {
            let documents = try context.fetch(fetchRequest)
            return documents
        } catch {
            print("Failed to fetch received documents: \(error)")
            return []
        }
    }
}
