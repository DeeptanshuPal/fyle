//
//  ReminderViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit
import CoreData
import PDFKit
import QuickLook

class RemindersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var remindersTableView: UITableView!
    
    // MARK: - Properties
    private var reminders: [Document] = [] // Assuming Document has a 'reminderDate' and 'pdfData' attribute
    private var pastDueReminders: [Document] = []
    private var upcomingReminders: [Document] = []
    private var futureReminders: [Document] = []
    private var filteredPastDueReminders: [Document] = []
    private var filteredUpcomingReminders: [Document] = []
    private var filteredFutureReminders: [Document] = []
    private var searchController: UISearchController!
    private var isSearching: Bool = false
    private var selectedDocument: Document?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply bottom blur
        applyBlurGradient()
        
        // Set up navigation bar with large title
        navigationItem.title = "Reminders"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Set up search bar
        setupSearchController()
        
        // Set up table view
        setupTableView()
        
        // Fetch reminders from Core Data
        fetchReminders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        fetchReminders()
        remindersTableView.reloadData()
        
        // Force scroll to top to ensure large title is displayed
        remindersTableView.setContentOffset(.zero, animated: false)
        
        // Ensure navigation tint colour is white
        self.navigationController?.navigationBar.tintColor = .white
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        navigationController?.navigationBar.standardAppearance = appearance
        
        // Ensure large title appears when at the top
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        scrollEdgeAppearance.backgroundColor = .clear
        navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        
        navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Additional check to ensure large title is displayed
        remindersTableView.setContentOffset(.zero, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure 16-point padding on leading and trailing edges
        adjustTableViewFrame()
    }
    
    // MARK: - Set up Bottom Blur
    private func applyBlurGradient() {
        // Create Blur Effect View
        let blurEffect = UIBlurEffect(style: .light) // Change to .dark if needed
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Set the Frame to Cover Bottom 120pt
        blurView.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin] // Adjust for different screen sizes

        // Create Gradient Mask (90% -> 0% opacity)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.9).cgColor, // 90% opacity at bottom
            UIColor(white: 1.0, alpha: 0.0).cgColor   // 0% opacity at top
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Start at bottom
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Fade to top

        // Apply Gradient as a Mask to Blur View
        let maskLayer = CALayer()
        maskLayer.frame = blurView.bounds
        maskLayer.addSublayer(gradientLayer)
        blurView.layer.mask = maskLayer

        // Insert Blur View BELOW `addButton` (if present) or above table view
        view.insertSubview(blurView, aboveSubview: remindersTableView)
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        // Initialize the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Reminders"
        searchController.searchBar.tintColor = .white // Match navigation bar style
        
        // Add the search bar to the navigation bar
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false // Show search bar by default
        
        // Ensure the search bar doesn't hide the navigation bar
        definesPresentationContext = true
        
        // Customize search bar appearance to match previous screens
        searchController.searchBar.isTranslucent = true
        searchController.searchBar.barTintColor = .clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6)
    }
    
    private func setupTableView() {
        guard let tableView = remindersTableView else {
            print("Error: remindersTableView outlet is not connected.")
            return
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        
        // Disable automatic content inset adjustment to prevent offset issues
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Ensure constraints are respected from storyboard
        tableView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    private func fetchReminders() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderDate != nil") // Fetch only documents with reminders
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "reminderDate", ascending: true)] // Sort by date
        
        do {
            reminders = try context.fetch(fetchRequest)
            categorizeReminders()
            remindersTableView.reloadData()
        } catch {
            print("Error fetching reminders: \(error)")
            reminders = []
        }
    }
    
    private func categorizeReminders() {
        let now = Date()
        let calendar = Calendar.current
        
        pastDueReminders.removeAll()
        upcomingReminders.removeAll()
        futureReminders.removeAll()
        
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        for reminder in reminders {
            guard let reminderDate = reminder.reminderDate else { continue }
            
            let reminderMonth = calendar.component(.month, from: reminderDate)
            let reminderYear = calendar.component(.year, from: reminderDate)
            
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)
            
            if let reminderDay = calendar.date(from: dateComponents),
               let nowDay = calendar.date(from: nowComponents) {
                
                if reminderDay < nowDay {
                    pastDueReminders.append(reminder)
                } else if reminderYear == currentYear && reminderMonth == currentMonth {
                    upcomingReminders.append(reminder)
                } else {
                    futureReminders.append(reminder)
                }
            }
        }
    }
    
    private func categorizeFilteredReminders() {
        let now = Date()
        let calendar = Calendar.current
        
        filteredPastDueReminders.removeAll()
        filteredUpcomingReminders.removeAll()
        filteredFutureReminders.removeAll()
        
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        for reminder in reminders {
            guard let reminderDate = reminder.reminderDate else { continue }
            
            let reminderMonth = calendar.component(.month, from: reminderDate)
            let reminderYear = calendar.component(.year, from: reminderDate)
            
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)
            
            if let reminderDay = calendar.date(from: dateComponents),
               let nowDay = calendar.date(from: nowComponents) {
                
                if reminderDay < nowDay {
                    filteredPastDueReminders.append(reminder)
                } else if reminderYear == currentYear && reminderMonth == currentMonth {
                    filteredUpcomingReminders.append(reminder)
                } else {
                    filteredFutureReminders.append(reminder)
                }
            }
        }
        
        // Filter based on search text
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            filteredPastDueReminders = filteredPastDueReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
            filteredUpcomingReminders = filteredUpcomingReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
            filteredFutureReminders = filteredFutureReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Past Due, Upcoming, Future
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            switch section {
            case 0: return filteredPastDueReminders.count
            case 1: return filteredUpcomingReminders.count
            case 2: return filteredFutureReminders.count
            default: return 0
            }
        } else {
            switch section {
            case 0: return pastDueReminders.count
            case 1: return upcomingReminders.count
            case 2: return futureReminders.count
            default: return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! RemindersTableViewCell
        
        let reminder: Document
        if isSearching {
            switch indexPath.section {
            case 0: reminder = filteredPastDueReminders[indexPath.row]
            case 1: reminder = filteredUpcomingReminders[indexPath.row]
            case 2: reminder = filteredFutureReminders[indexPath.row]
            default: fatalError("Unexpected section")
            }
        } else {
            switch indexPath.section {
            case 0: reminder = pastDueReminders[indexPath.row]
            case 1: reminder = upcomingReminders[indexPath.row]
            case 2: reminder = futureReminders[indexPath.row]
            default: fatalError("Unexpected section")
            }
        }
        
        // Configure cell
        cell.fileNameLabel.text = reminder.name ?? "Unnamed Document"
        
        if let reminderDate = reminder.reminderDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium // Only date
            dateFormatter.timeStyle = .none  // No time
            cell.dateLabel.text = dateFormatter.string(from: reminderDate)
        } else {
            cell.dateLabel.text = "No Date"
        }
        
        // Set date label color based on section
        switch indexPath.section {
        case 0: cell.dateLabel.textColor = .systemRed
        case 1: cell.dateLabel.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0)
        case 2: cell.dateLabel.textColor = .systemGreen
        default: cell.dateLabel.textColor = .black
        }
        
        // Set cell background
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        
        // Customize cell corners based on position in section
        let sectionRowCount = tableView.numberOfRows(inSection: indexPath.section)
        let isFirstRow = indexPath.row == 0
        let isLastRow = indexPath.row == sectionRowCount - 1
        
        cell.layer.cornerRadius = 11
        cell.layer.masksToBounds = true
        
        if isFirstRow && isLastRow {
            // Single row in section: round all corners
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirstRow {
            // First row: round top corners
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLastRow {
            // Last row: round bottom corners
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            // Intermediate row: no rounding
            cell.layer.maskedCorners = []
        }
        
        // Add disclosure indicator
        cell.accessoryType = .disclosureIndicator
        
        // Add shadow (optional, matches previous design)
        cell.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.3
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius = 4
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 11).cgPath
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Past Due"
        case 1: return "Upcoming"
        case 2: return "Future"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Add extra spacing above the first section ("Past Due") and ensure enough height for the title
        if section == 0 {
            return 40.0 + 10.0 // 40 for title height, 10 for extra spacing
        }
        return 40.0 // Standard height for other sections
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        titleLabel.textColor = .darkGray
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerView.addSubview(titleLabel)
        
        // Constraints for title label
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Add a small footer to ensure spacing between sections
        return 8.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Determine the selected document based on section
        let reminder: Document
        if isSearching {
            switch indexPath.section {
            case 0: reminder = filteredPastDueReminders[indexPath.row]
            case 1: reminder = filteredUpcomingReminders[indexPath.row]
            case 2: reminder = filteredFutureReminders[indexPath.row]
            default: fatalError("Unexpected section")
            }
        } else {
            switch indexPath.section {
            case 0: reminder = pastDueReminders[indexPath.row]
            case 1: reminder = upcomingReminders[indexPath.row]
            case 2: reminder = futureReminders[indexPath.row]
            default: fatalError("Unexpected section")
            }
        }
        
        selectedDocument = reminder
        presentPDFViewer()
    }
    
    // MARK: - PDF Viewer
    private func presentPDFViewer() {
        guard let document = selectedDocument, let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available for this document.")
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        // Set custom title based on document name
        previewController.navigationItem.title = document.name ?? "Document"
        
        // Present modally to use default QuickLook navigation bar
        previewController.modalPresentationStyle = .fullScreen
        present(previewController, animated: true, completion: nil)
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let document = selectedDocument, let pdfData = document.pdfData else {
            fatalError("PDF data is unexpectedly nil.")
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf")
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Clean up temporary file
        if let url = try? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf") {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = !searchController.searchBar.text!.isEmpty
        categorizeFilteredReminders()
        remindersTableView.reloadData()
    }
    
    // MARK: - Custom Methods
    private func adjustTableViewFrame() {
        guard let tableView = remindersTableView else { return }
        
        let padding: CGFloat = 16.0
        let newFrame = CGRect(
            x: padding,
            y: tableView.frame.origin.y,
            width: view.bounds.width - (2 * padding),
            height: tableView.frame.height
        )
        tableView.frame = newFrame
    }
}
