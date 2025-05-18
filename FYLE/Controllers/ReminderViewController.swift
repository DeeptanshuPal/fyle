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
    private var reminders: [Document] = []
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
        
        applyBlurGradient()
        navigationItem.title = "Reminders"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupSearchController()
        setupTableView()
        fetchReminders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchReminders()
        remindersTableView.reloadData()
        
        remindersTableView.setContentOffset(.zero, animated: false)
        navigationController?.navigationBar.tintColor = .white
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        navigationController?.navigationBar.standardAppearance = appearance
        
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
        remindersTableView.setContentOffset(.zero, animated: false)
    }
    
    // MARK: - Setup Bottom Blur
    private func applyBlurGradient() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        blurView.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.9).cgColor,
            UIColor(white: 1.0, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        let maskLayer = CALayer()
        maskLayer.frame = blurView.bounds
        maskLayer.addSublayer(gradientLayer)
        blurView.layer.mask = maskLayer
        
        view.insertSubview(blurView, aboveSubview: remindersTableView)
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Reminders"
        searchController.searchBar.tintColor = .white
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
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
        
        // Separator configuration
        tableView.separatorStyle = .none // Disable default separators
        
        // Enable self-sizing cells with increased estimated height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80.0
        
        // Ensure the table view uses the grouped style for section grouping
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeConstraints(tableView.constraints)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    private func fetchReminders() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderDate != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "reminderDate", ascending: true)]
        
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
        
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            filteredPastDueReminders = filteredPastDueReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
            filteredUpcomingReminders = filteredUpcomingReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
            filteredFutureReminders = filteredFutureReminders.filter { $0.name?.lowercased().contains(searchText) ?? false }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            switch section {
            case 0: return filteredPastDueReminders.isEmpty ? 1 : filteredPastDueReminders.count
            case 1: return filteredUpcomingReminders.isEmpty ? 1 : filteredUpcomingReminders.count
            case 2: return filteredFutureReminders.isEmpty ? 1 : filteredFutureReminders.count
            default: return 0
            }
        } else {
            switch section {
            case 0: return pastDueReminders.isEmpty ? 1 : pastDueReminders.count
            case 1: return upcomingReminders.isEmpty ? 1 : upcomingReminders.count
            case 2: return futureReminders.isEmpty ? 1 : futureReminders.count
            default: return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! RemindersTableViewCell
        
        var reminder: Document?
        var isEmptySection = false
        var placeholderText = ""
        var sectionCount = 0
        
        // Determine section data based on search state
        if isSearching {
            switch indexPath.section {
            case 0:
                sectionCount = filteredPastDueReminders.count
                if filteredPastDueReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No past files due"
                } else {
                    reminder = filteredPastDueReminders[indexPath.row]
                }
            case 1:
                sectionCount = filteredUpcomingReminders.count
                if filteredUpcomingReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No files expiring this month"
                } else {
                    reminder = filteredUpcomingReminders[indexPath.row]
                }
            case 2:
                sectionCount = filteredFutureReminders.count
                if filteredFutureReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No files due in the future"
                } else {
                    reminder = filteredFutureReminders[indexPath.row]
                }
            default: fatalError("Unexpected section")
            }
        } else {
            switch indexPath.section {
            case 0:
                sectionCount = pastDueReminders.count
                if pastDueReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No past files due"
                } else {
                    reminder = pastDueReminders[indexPath.row]
                }
            case 1:
                sectionCount = upcomingReminders.count
                if upcomingReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No files expiring this month"
                } else {
                    reminder = upcomingReminders[indexPath.row]
                }
            case 2:
                sectionCount = futureReminders.count
                if futureReminders.isEmpty {
                    isEmptySection = true
                    placeholderText = "No files due in the future"
                } else {
                    reminder = futureReminders[indexPath.row]
                }
            default: fatalError("Unexpected section")
            }
        }
        
        // Configure cell content
        if isEmptySection {
            cell.configureForEmptyState(placeholderText: placeholderText)
        } else {
            guard let reminder = reminder else { fatalError("Reminder is nil in non-empty section") }
            
            let fileName = reminder.name ?? "Unnamed Document"
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let dateText = reminder.reminderDate.map { dateFormatter.string(from: $0) } ?? "No Date"
            
            let dateColor: UIColor
            switch indexPath.section {
            case 0: dateColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0) // Past Due
            case 1: dateColor = .systemRed // This Month
            case 2: dateColor = .systemGreen // Upcoming
            default: dateColor = .black
            }
            
            cell.configureForNonEmptyState(
                fileName: fileName,
                dateText: dateText,
                dateColor: dateColor,
                chevronTarget: self,
                action: #selector(disclosureTapped(_:))
            )
        }
        
        // Create a custom background view to handle rounded corners and glassmorphic design
        let backgroundView = UIView(frame: cell.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let cornerRadius: CGFloat = 10.0
        backgroundView.layer.cornerRadius = cornerRadius
        
        if isEmptySection {
            // Create gradient layer for empty state cells
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = backgroundView.bounds
            gradientLayer.cornerRadius = cornerRadius
            
            // Define three colors for the gradient
            let color1 = #colorLiteral(red: 0.9215686275, green: 0.937254902, blue: 1, alpha: 0.2078849337)
            let color2 = #colorLiteral(red: 0.9215686275, green: 0.937254902, blue: 1, alpha: 0.323080505)
            let color3 = #colorLiteral(red: 0.9215686275, green: 0.937254902, blue: 1, alpha: 0.3972733858)
            
            // Convert UIColors to CGColors for the gradient layer
            gradientLayer.colors = [color1.cgColor, color2.cgColor, color3.cgColor]
            gradientLayer.locations = [0.0, 0.8, 1.0] // Adjust these values to control color distribution
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0) // Top-left
            gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0) // Bottom-right
            
            // Add gradient layer to background view
            backgroundView.layer.insertSublayer(gradientLayer, at: 0)
            
            // Glassmorphic effects
            backgroundView.layer.masksToBounds = false
            backgroundView.layer.shadowColor = UIColor.black.cgColor
            backgroundView.layer.shadowOpacity = 0.3
            backgroundView.layer.shadowOffset = .zero
            backgroundView.layer.shadowRadius = 2
            backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                                  .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            // Add border
            backgroundView.layer.borderWidth = 1.0 // Adjust thickness as needed
            backgroundView.layer.borderColor = #colorLiteral(red: 0.9215686275, green: 0.937254902, blue: 1, alpha: 0.0981218957)
        } else {
            // Solid background for non-empty cells
            backgroundView.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.9764705882, blue: 1, alpha: 1)
            backgroundView.layer.masksToBounds = true
            if sectionCount == 1 {
                backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                                      .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else if indexPath.row == 0 {
                backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else if indexPath.row == sectionCount - 1 {
                backgroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                backgroundView.layer.maskedCorners = []
            }
        }
        
        // Set the custom background view
        cell.backgroundView = backgroundView
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        // Reset margins to avoid interference
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    @objc func disclosureTapped(_ sender: UIButton) {
        print("Chevron tapped")
        
        let buttonPosition = sender.convert(sender.bounds.origin, to: remindersTableView)
        guard let indexPath = remindersTableView.indexPathForRow(at: buttonPosition) else {
            print("Error: Could not determine indexPath from button position")
            return
        }
        
        var reminder: Document?
        if isSearching {
            switch indexPath.section {
            case 0: reminder = filteredPastDueReminders[indexPath.row]
            case 1: reminder = filteredUpcomingReminders[indexPath.row]
            case 2: reminder = filteredFutureReminders[indexPath.row]
            default: return
            }
        } else {
            switch indexPath.section {
            case 0: reminder = pastDueReminders[indexPath.row]
            case 1: reminder = upcomingReminders[indexPath.row]
            case 2: reminder = futureReminders[indexPath.row]
            default: return
            }
        }
        
        guard let document = reminder else {
            print("Error: No document found")
            return
        }
        
        selectedDocument = document
        presentPDFViewer()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Remove any existing separator views to avoid duplicates
        cell.contentView.subviews.forEach { subview in
            if subview.tag == 999 { // Use a tag to identify separator views
                subview.removeFromSuperview()
            }
        }
        
        // Determine if the section is empty
        let isEmptySection: Bool
        let sectionCount: Int
        switch indexPath.section {
        case 0:
            isEmptySection = isSearching ? filteredPastDueReminders.isEmpty : pastDueReminders.isEmpty
            sectionCount = isSearching ? filteredPastDueReminders.count : pastDueReminders.count
        case 1:
            isEmptySection = isSearching ? filteredUpcomingReminders.isEmpty : upcomingReminders.isEmpty
            sectionCount = isSearching ? filteredUpcomingReminders.count : upcomingReminders.count
        case 2:
            isEmptySection = isSearching ? filteredFutureReminders.isEmpty : futureReminders.isEmpty
            sectionCount = isSearching ? filteredFutureReminders.count : futureReminders.count
        default:
            return
        }
        
        if isEmptySection {
            // No separator for empty sections
            return
        } else {
            // Add a separator at the bottom of the cell, but not for the last cell in the section
            if indexPath.row != sectionCount - 1 {
                let separator = UIView()
                separator.tag = 999 // Tag to identify separator views
                separator.backgroundColor = .separator // Use the system separator color
                separator.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(separator) // Add to cell instead of contentView
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 15),
                    separator.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -15),
                    separator.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 0.5)
                ])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let isEmptySection: Bool
        if isSearching {
            switch indexPath.section {
            case 0:
                isEmptySection = filteredPastDueReminders.isEmpty
            case 1:
                isEmptySection = filteredUpcomingReminders.isEmpty
            case 2:
                isEmptySection = filteredFutureReminders.isEmpty
            default:
                fatalError("Unexpected section")
            }
        } else {
            switch indexPath.section {
            case 0:
                isEmptySection = pastDueReminders.isEmpty
            case 1:
                isEmptySection = upcomingReminders.isEmpty
            case 2:
                isEmptySection = futureReminders.isEmpty
            default:
                fatalError("Unexpected section")
            }
        }
        
        if isEmptySection && indexPath.row == 0 {
            return 80.0 // Desired height for empty message cells
        } else {
            return UITableView.automaticDimension // Dynamic height for regular cells
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Past Due"
        case 1: return "This Month"
        case 2: return "Upcoming"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 50.0 : 40.0
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
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var reminder: Document?
        if isSearching {
            switch indexPath.section {
            case 0: reminder = filteredPastDueReminders.isEmpty ? nil : filteredPastDueReminders[indexPath.row]
            case 1: reminder = filteredUpcomingReminders.isEmpty ? nil : filteredUpcomingReminders[indexPath.row]
            case 2: reminder = filteredFutureReminders.isEmpty ? nil : filteredFutureReminders[indexPath.row]
            default: return
            }
        } else {
            switch indexPath.section {
            case 0: reminder = pastDueReminders.isEmpty ? nil : pastDueReminders[indexPath.row]
            case 1: reminder = upcomingReminders.isEmpty ? nil : upcomingReminders[indexPath.row]
            case 2: reminder = futureReminders.isEmpty ? nil : futureReminders[indexPath.row]
            default: return
            }
        }
        
        guard let document = reminder else { return }
        showDetails(for: document)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        var document: Document?
        if isSearching {
            switch indexPath.section {
            case 0: document = filteredPastDueReminders.isEmpty ? nil : filteredPastDueReminders[indexPath.row]
            case 1: document = filteredUpcomingReminders.isEmpty ? nil : filteredUpcomingReminders[indexPath.row]
            case 2: document = filteredFutureReminders.isEmpty ? nil : filteredFutureReminders[indexPath.row]
            default: return nil
            }
        } else {
            switch indexPath.section {
            case 0: document = pastDueReminders.isEmpty ? nil : pastDueReminders[indexPath.row]
            case 1: document = upcomingReminders.isEmpty ? nil : upcomingReminders[indexPath.row]
            case 2: document = futureReminders.isEmpty ? nil : futureReminders[indexPath.row]
            default: return nil
            }
        }
        
        guard let document = document else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let openFileAction = UIAction(title: "Open File", image: UIImage(systemName: "doc.text.viewfinder")) { [weak self] _ in
                guard let self = self else { return }
                self.selectedDocument = document
                self.presentPDFViewer()
            }
            
            let showDetailsAction = UIAction(title: "Show Details", image: UIImage(systemName: "info.circle")) { [weak self] _ in
                self?.showDetails(for: document)
            }
            
            let favoriteAction = UIAction(
                title: document.isFavorite ? "Unmark as Favourite" : "Mark as Favourite",
                image: UIImage(systemName: document.isFavorite ? "heart.fill" : "heart")
            ) { [weak self] _ in
                guard let self = self else { return }
                document.isFavorite.toggle()
                CoreDataManager.shared.saveContext()
                self.remindersTableView.reloadData()
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.confirmDelete(document: document, at: indexPath)
            }
            
            let sendCopyAction = UIAction(title: "Send a Copy", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                guard let self = self else { return }
                self.shareDocument(document)
            }
            
            return UIMenu(title: "", children: [openFileAction, showDetailsAction, favoriteAction, deleteAction, sendCopyAction])
        }
    }
    
    // MARK: - Context Menu Actions
    private func showDetails(for document: Document) {
        guard let addDocumentVC = storyboard?.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController else {
            print("Error: Could not instantiate AddDocumentViewController from storyboard.")
            return
        }
        
        addDocumentVC.isEditingExistingDocument = true
        addDocumentVC.isReadOnly = true
        addDocumentVC.existingDocument = document
        
        addDocumentVC.loadViewIfNeeded()
        
        addDocumentVC.selectedImages = loadImagesFromDocument(document)
        addDocumentVC.summaryData = loadSummaryData(from: document)
        addDocumentVC.selectedCategories = document.categories?.allObjects as? [Category] ?? []
        
        if let favoriteSwitch = addDocumentVC.favoriteSwitch {
            favoriteSwitch.isOn = document.isFavorite
        } else {
            print("Warning: favoriteSwitch is nil, cannot set favorite status.")
        }
        
        addDocumentVC.nameTextField?.text = document.name
        
        if let expiryDate = document.expiryDate {
            addDocumentVC.reminderSwitch?.isOn = true
            addDocumentVC.expiryDatePicker?.date = expiryDate
            addDocumentVC.expiryDatePicker?.isHidden = false
            addDocumentVC.expiryDateLabel?.isHidden = false
        } else {
            addDocumentVC.reminderSwitch?.isOn = false
            addDocumentVC.expiryDatePicker?.isHidden = true
            addDocumentVC.expiryDateLabel?.isHidden = true
        }
        
        addDocumentVC.updateUIWithExistingDocument()
        
        let navController = UINavigationController(rootViewController: addDocumentVC)
        present(navController, animated: true, completion: nil)
    }
    
    private func confirmDelete(document: Document, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Document",
            message: "Are you sure you want to delete \"\(document.name ?? "Unnamed Document")\"? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            CoreDataManager.shared.deleteDocument(document)
            self.fetchReminders()
            self.remindersTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func shareDocument(_ document: Document) {
        guard let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available to share.")
            return
        }
        
        let fileName = (document.name ?? "Unnamed Document") + ".pdf"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            present(activityViewController, animated: true) {
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            showAlert(title: "Error", message: "Failed to prepare document for sharing: \(error.localizedDescription)")
        }
    }
    
    private func loadImagesFromDocument(_ document: Document) -> [UIImage] {
        guard let pdfData = document.pdfData, let pdfDocument = PDFDocument(data: pdfData) else {
            return []
        }
        
        var images: [UIImage] = []
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                let pageBounds = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
                let image = renderer.image { context in
                    UIColor.white.setFill()
                    context.fill(pageBounds)
                    context.cgContext.translateBy(x: 0, y: pageBounds.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                images.append(image)
            }
        }
        return images
    }
    
    private func loadSummaryData(from document: Document) -> [String: String] {
        guard let summaryData = document.summaryData,
              let json = try? JSONSerialization.jsonObject(with: summaryData, options: []) as? [String: String] else {
            return [:]
        }
        return json
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
        previewController.navigationItem.title = document.name ?? "Document"
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
        let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if let document = selectedDocument {
            let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
            let fileName = "\(documentName).pdf"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
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
}
