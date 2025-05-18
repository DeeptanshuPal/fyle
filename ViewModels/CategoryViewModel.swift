//
//  CategoryViewModel.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = DataManager.shared.getCategories()

    // Add a new category
    func addCategory(name: String, isCustom: Bool) {
        let newCategory = Category(id: UUID(), name: name, fileIDs: [], isCustom: isCustom)
        DataManager.shared.addCategory(newCategory)
        categories = DataManager.shared.getCategories() // Update the view
    }
    
    // Remove a category
    func removeCategory(category: Category) {
        DataManager.shared.removeCategory(category)
        categories = DataManager.shared.getCategories() // Update the view
    }
}
