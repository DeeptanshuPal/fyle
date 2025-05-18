//
//  CategorySpecificViewModel.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class CategorySpecificViewModel: ObservableObject {
    @Published var filesInCategory: [File] = []
    
    // Filter files by category
    func loadFiles(for category: Category) {
        filesInCategory = DataManager.shared.getFiles().filter { $0.category == category.name }
    }
    
    // Add a file to a category
    func addFileToCategory(file: File, category: Category) {
        var updatedCategory = category
        updatedCategory.fileIDs.append(file.id)
        DataManager.shared.updateCategory(updatedCategory)
        loadFiles(for: category) // Reload files in the category
    }
}
