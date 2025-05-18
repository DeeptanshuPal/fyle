//
//  Document+Extensions.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import CoreData
import UIKit
import PDFKit

extension Document {
    // MARK: - Computed Properties
    
    /// Converts summaryData (Binary Data) into a dictionary
    var summaryDictionary: [String: String]? {
        guard let data = summaryData else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
    }
    
    /// Returns a formatted expiry date string
    var formattedExpiryDate: String? {
        guard let date = expiryDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Returns the document's thumbnail as a UIImage
    var thumbnailImage: UIImage? {
        guard let data = thumbnail else { return nil }
        return UIImage(data: data)
    }
    
    /// Returns the document's PDF data as a PDF document
    var pdfDocument: PDFDocument? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)
    }
    
    // MARK: - Helper Methods
    
    /// Adds a category to the document
    func addCategory(_ category: Category) {
        self.addToCategories(category)
    }
    
    /// Removes a category from the document
    func removeCategory(_ category: Category) {
        self.removeFromCategories(category)
    }
}
