//
//  ReminderViewModel.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = DataManager.shared.reminders

    // Add a reminder
    func addReminder(for file: File, reminderDate: Date, frequency: NotificationFrequency) {
        let reminder = Reminder(
            id: UUID(),
            fileID: file.id,
            reminderDate: reminderDate,
            notificationFrequency: frequency, // Frequency based on user's preference
            reminderType: .once, // Adjust this based on the user's preference
            status: .active // Adjust the status (active, completed, etc.)
        )
        DataManager.shared.addReminder(reminder)
        reminders = DataManager.shared.reminders // Update the view
    }
    
    // Remove a reminder
    func removeReminder(reminder: Reminder) {
        DataManager.shared.removeReminder(reminder)
        reminders = DataManager.shared.reminders // Update the view
    }
    
    // Update reminder frequency
    func updateReminderFrequency(for reminder: Reminder, newFrequency: NotificationFrequency) {
        var updatedReminder = reminder
        updatedReminder.notificationFrequency = newFrequency
        DataManager.shared.updateReminder(updatedReminder)
        reminders = DataManager.shared.reminders // Update the view
    }
}

