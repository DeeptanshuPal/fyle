//
//  User.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

struct User: Identifiable {
    var id: UUID
    var name: String
    var sharedFiles: [UUID] // Files shared with the user
    var preferences: UserPreferences
    var role: UserRole // Admin, Regular user, etc.
}

enum UserRole: String, Codable {
    case admin
    case regular
}

struct UserPreferences {
    var notificationEnabled: Bool
    var notificationFrequency: NotificationFrequency
}
