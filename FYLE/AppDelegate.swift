//
//  AppDelegate.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 28/02/25.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Clear expired notified documents
        clearExpiredNotifiedDocuments()
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Set the notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check for upcoming reminders
        checkForUpcomingReminders()
        
        
        // Get core data .sqlite database path
        if let directoryLocation = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last {
            print("Core Data Path : Documents Directory: \(directoryLocation)Application Support")
        }
        
        return true
    }
    
    // MARK: - In-App Notifications
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle in-app notifications when the app is in the foreground
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle user interaction with notifications (e.g., tapping on a notification)
        completionHandler()
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FyleModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: Core Data Saving support
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Notification Handling
    
    private func checkForMissedNotifications() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderDate < %@", Date() as NSDate)
        
        do {
            let expiredDocuments = try context.fetch(fetchRequest)
            if !expiredDocuments.isEmpty {
                showMissedNotificationsAlert(for: expiredDocuments)
            }
        } catch {
            print("Error fetching expired documents: \(error)")
        }
    }
    
    private func showMissedNotificationsAlert(for documents: [Document]) {
        let alert = UIAlertController(
            title: "Missed Reminders",
            message: "You have \(documents.count) expired documents.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func checkForUpcomingReminders() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        
        // Fetch documents with reminderDate within the next 7 days
        let now = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        fetchRequest.predicate = NSPredicate(format: "reminderDate >= %@ AND reminderDate <= %@", now as NSDate, sevenDaysFromNow as NSDate)
        
        do {
            let upcomingDocuments = try context.fetch(fetchRequest)
            
            if !upcomingDocuments.isEmpty {
                showUpcomingRemindersAlert(for: upcomingDocuments)
                scheduleLocalNotifications(for: upcomingDocuments)
            }
        } catch {
            print("Error fetching upcoming reminders: \(error)")
        }
    }
    
    private func showUpcomingRemindersAlert(for documents: [Document]) {
        let alert = UIAlertController(
            title: "⚠️ Upcoming Deadlines",
            message: "You have \(documents.count) document(s) with approaching deadlines:",
            preferredStyle: .alert
        )
        
        // Customize the title with red color
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.systemRed
        ]
        let titleString = NSAttributedString(string: "⚠️ Upcoming Deadlines", attributes: titleAttributes)
        alert.setValue(titleString, forKey: "attributedTitle")
        
        // Customize the message with structured formatting
        let messageText = NSMutableAttributedString(string: "You have \(documents.count) document(s) with approaching deadlines:\n\n")
        messageText.addAttributes([
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ], range: NSRange(location: 0, length: messageText.length))
        
        // Add details for each document
        for document in documents {
            if let name = document.name, let reminderDate = document.reminderDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: reminderDate).day ?? 0
                let documentDetails = "• \(name): \(daysRemaining) day(s) remaining\n"
                
                // Add red color for documents expiring in 1 or 2 days
                let documentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: daysRemaining <= 2 ? UIColor.systemRed : UIColor.label
                ]
                let attributedDocumentDetails = NSAttributedString(string: documentDetails, attributes: documentAttributes)
                messageText.append(attributedDocumentDetails)
            }
        }
        
        alert.setValue(messageText, forKey: "attributedMessage")
        
        // Add an OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Add a Snooze button
        alert.addAction(UIAlertAction(title: "Snooze for 1 Hour", style: .default) { _ in
            self.snoozeReminders(for: documents, duration: .hour)
        })
        
        alert.addAction(UIAlertAction(title: "Snooze for 1 Day", style: .default) { _ in
            self.snoozeReminders(for: documents, duration: .day)
        })
        
        // Present the alert on the main thread
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func snoozeReminders(for documents: [Document], duration: Calendar.Component) {
        for document in documents {
            guard let reminderDate = document.reminderDate else { continue }
            
            // Reschedule the reminder for the snooze duration
            let newReminderDate = Calendar.current.date(byAdding: duration, value: 1, to: reminderDate)!
            document.reminderDate = newReminderDate
            
            // Schedule a new notification
            scheduleLocalNotifications(for: [document])
        }
        
        // Save changes to Core Data
        CoreDataManager.shared.saveContext()
    }
    
    private func scheduleLocalNotifications(for documents: [Document]) {
        let center = UNUserNotificationCenter.current()
        
        for document in documents {
            guard let reminderDate = document.reminderDate else { continue }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Document Expiry Reminder"
            content.body = "\(document.name ?? "A document") is expiring in \(Calendar.current.dateComponents([.day], from: Date(), to: reminderDate).day ?? 0) day(s)."
            content.sound = .default
            
            // Set the trigger for the notification (1 day before expiry)
            let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: reminderDate)!
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            // Use document's ID as the request identifier
            let requestID = document.objectID.uriRepresentation().absoluteString
            let request = UNNotificationRequest(
                identifier: requestID,
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            center.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error)")
                } else {
                    print("✅ Scheduled notification for \(document.name ?? "unnamed document")")
                }
            }
        }
    }
    
    private func clearExpiredNotifiedDocuments() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        
        // Fetch documents with reminderDate in the past
        fetchRequest.predicate = NSPredicate(format: "reminderDate < %@", Date() as NSDate)
        
        do {
            let expiredDocuments = try context.fetch(fetchRequest)
            let expiredDocumentIDs = expiredDocuments.map { $0.objectID.uriRepresentation().absoluteString }
            
            // Remove expired document IDs from notifiedDocuments
            let notifiedDocuments = UserDefaults.standard.array(forKey: "notifiedDocuments") as? [String] ?? []
            let updatedNotifiedDocuments = notifiedDocuments.filter { !expiredDocumentIDs.contains($0) }
            UserDefaults.standard.set(updatedNotifiedDocuments, forKey: "notifiedDocuments")
        } catch {
            print("Error fetching expired documents: \(error)")
        }
    }
    
    
}
