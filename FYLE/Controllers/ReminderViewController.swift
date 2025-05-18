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
        self.navigationController?.navigationBar.tintColor = .white
        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTableViewFrame()
    }
    
    // MARK: - Set up Bottom Blur
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
        
        // Ensure the table view uses the grouped style for section grouping
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeConstraints(tableView.constraints)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
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
            cell.fileNameLabel.text = placeholderText
            cell.dateLabel.text = ""
            cell.dateLabel.textColor = .gray
            cell.accessoryView = nil
            cell.isUserInteractionEnabled = false
        } else {
            guard let reminder = reminder else { fatalError("Reminder is nil when section is not empty") }
            
            cell.fileNameLabel.text = reminder.name ?? "Unnamed Document"
            
            if let reminderDate = reminder.reminderDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                cell.dateLabel.text = dateFormatter.string(from: reminderDate)
            } else {
                cell.dateLabel.text = "No Date"
            }
            
            switch indexPath.section {
            case 0: cell.dateLabel.textColor = .systemRed
            case 1: cell.dateLabel.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0)
            case 2: cell.dateLabel.textColor = .systemGreen
            default: cell.dateLabel.textColor = .black
            }
            
            let chevronButton = UIButton(type: .system)
            chevronButton.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)
            chevronButton.tintColor = .systemGray4
            chevronButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            chevronButton.imageView?.contentMode = .scaleAspectFit
            chevronButton.contentHorizontalAlignment = .center
            chevronButton.contentVerticalAlignment = .center
            chevronButton.addTarget(self, action: #selector(disclosureTapped(_:)), for: .touchUpInside)
            
            cell.accessoryView = chevronButton
            cell.isUserInteractionEnabled = true
        }
        
        // Apply rounded corners to section groups
        let cornerRadius: CGFloat = 10.0
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = cornerRadius
        
        if sectionCount == 1 {
            // Single row in section: round all corners
            backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            // First row in section: round top corners
            backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == sectionCount - 1 {
            // Last row in section: round bottom corners
            backgroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            // Middle rows: no rounded corners
            backgroundView.layer.maskedCorners = []
        }
        
        cell.backgroundView = isEmptySection ? nil : backgroundView
        cell.backgroundColor = .clear
        
        return cell
    }
    
    @objc func disclosureTapped(_ sender: UIButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = remindersTableView.indexPath(for: cell) else {
            print("Error: Could not determine cell or indexPath from disclosure tap.")
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
        
        guard let document = reminder else { return }
        selectedDocument = document
        presentPDFViewer()
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
        // Increase footer height for better spacing between rounded sections
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
