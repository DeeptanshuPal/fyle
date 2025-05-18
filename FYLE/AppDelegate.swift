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
        
        // delay launch screen
        Thread.sleep(forTimeInterval: 0.5)
        
        return true
    }
    
    // MARK: - In-App Notifications
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
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
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
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
    
    // Updated function: Replace the original here
    private func checkForUpcomingReminders() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        
        // Fetch documents with reminderDate within the next 7 days, sorted by reminderDate
        let now = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        fetchRequest.predicate = NSPredicate(format: "reminderDate >= %@ AND reminderDate <= %@", now as NSDate, sevenDaysFromNow as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "reminderDate", ascending: true)]
        
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
    
    // Updated function: Replace the original here
    private func showUpcomingRemindersAlert(for documents: [Document]) {
        let alert = UIAlertController(
            title: "Upcoming Deadlines",
            message: "",
            preferredStyle: .alert
        )
        
        // Customize the title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.systemRed
        ]
        let titleString = NSAttributedString(string: "Upcoming Deadlines", attributes: titleAttributes)
        alert.setValue(titleString, forKey: "attributedTitle")
        
        // Group documents by urgency
        var todayDocuments: [Document] = []
        var tomorrowDocuments: [Document] = []
        var soonDocuments: [Document] = []
        
        for document in documents {
            if let reminderDate = document.reminderDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: reminderDate).day ?? 0
                if daysRemaining == 0 {
                    todayDocuments.append(document)
                } else if daysRemaining == 1 {
                    tomorrowDocuments.append(document)
                } else {
                    soonDocuments.append(document)
                }
            }
        }
        
        // Build the structured message
        let messageText = NSMutableAttributedString(string: "\nYou have \(documents.count) document(s) with approaching deadlines:\n\n")
        messageText.addAttributes([
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ], range: NSRange(location: 0, length: messageText.length))
        
        // Expiring Today section
        if !todayDocuments.isEmpty {
            let todayHeader = NSAttributedString(string: "Expiring Today:\n", attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.systemRed
            ])
            messageText.append(todayHeader)
            for document in todayDocuments {
                let documentText = NSAttributedString(string: "• \(document.name ?? "Unnamed")\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemRed
                ])
                messageText.append(documentText)
            }
            messageText.append(NSAttributedString(string: "\n"))
        }
        
        // Expiring Tomorrow section
        if !tomorrowDocuments.isEmpty {
            let tomorrowHeader = NSAttributedString(string: "Expiring Tomorrow:\n", attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.systemOrange
            ])
            messageText.append(tomorrowHeader)
            for document in tomorrowDocuments {
                let documentText = NSAttributedString(string: "• \(document.name ?? "Unnamed")\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemOrange
                ])
                messageText.append(documentText)
            }
            messageText.append(NSAttributedString(string: "\n"))
        }
        
        // Expiring Soon section
        if !soonDocuments.isEmpty {
            let soonHeader = NSAttributedString(string: "Expiring Soon:\n", attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
            messageText.append(soonHeader)
            for document in soonDocuments {
                if let reminderDate = document.reminderDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: reminderDate).day ?? 0
                    let documentText = NSAttributedString(string: "• \(document.name ?? "Unnamed"): \n\(daysRemaining) day(s) remaining\n", attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ])
                    messageText.append(documentText)
                }
            }
        }
        
        alert.setValue(messageText, forKey: "attributedMessage")
        
        // Add actions
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Snooze for 1 Hour", style: .default) { _ in
            self.snoozeReminders(for: documents, duration: .hour)
        })
        alert.addAction(UIAlertAction(title: "Snooze for 1 Day", style: .default) { _ in
            self.snoozeReminders(for: documents, duration: .day)
        })
        
        // Present the alert
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
            
            let newReminderDate = Calendar.current.date(byAdding: duration, value: 1, to: reminderDate)!
            document.reminderDate = newReminderDate
            
            scheduleLocalNotifications(for: [document])
        }
        
        CoreDataManager.shared.saveContext()
    }
    
    private func scheduleLocalNotifications(for documents: [Document]) {
        let center = UNUserNotificationCenter.current()
        
        for document in documents {
            guard let reminderDate = document.reminderDate else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Document Expiry Reminder"
            content.body = "\(document.name ?? "A document") is expiring in \(Calendar.current.dateComponents([.day], from: Date(), to: reminderDate).day ?? 0) day(s)."
            content.sound = .default
            
            let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: reminderDate)!
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let requestID = document.objectID.uriRepresentation().absoluteString
            let request = UNNotificationRequest(
                identifier: requestID,
                content: content,
                trigger: trigger
            )
            
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
        
        fetchRequest.predicate = NSPredicate(format: "reminderDate < %@", Date() as NSDate)
        
        do {
            let expiredDocuments = try context.fetch(fetchRequest)
            let expiredDocumentIDs = expiredDocuments.map { $0.objectID.uriRepresentation().absoluteString }
            
            let notifiedDocuments = UserDefaults.standard.array(forKey: "notifiedDocuments") as? [String] ?? []
            let updatedNotifiedDocuments = notifiedDocuments.filter { !expiredDocumentIDs.contains($0) }
            UserDefaults.standard.set(updatedNotifiedDocuments, forKey: "notifiedDocuments")
        } catch {
            print("Error fetching expired documents: \(error)")
        }
    }
}
