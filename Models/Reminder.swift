//
//  Reminder.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

struct Reminder: Identifiable {
    var id: UUID
    var fileID: UUID // Links to the associated file
    var reminderDate: Date
    var notificationFrequency: NotificationFrequency
    var reminderType: ReminderType // E.g., recurring or one-time
    var status: ReminderStatus // E.g., pending, acknowledged, completed
}

enum ReminderType: String, Codable {
    case once
    case recurring
}

enum ReminderStatus {
    case active
    case completed
    case pending
}

enum NotificationFrequency: String, Codable {
    case once
    case daily
    case weekly
    case none
}
