//
//  Category.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

struct Category: Identifiable {
    var id: UUID
    var name: String
    var fileIDs: [UUID] // Links to files that belong to this category
    var isCustom: Bool
    var displayOrder: Int? // Optional: Order for custom categories
}
