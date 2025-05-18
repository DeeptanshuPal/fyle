//
//  SpecificCategoryViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit
import CoreData
import QuickLook
import PDFKit // Added for loadImagesFromDocument

class SpecificCategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, QLPreviewControllerDelegate, AddDocumentViewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filesTableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyTrayImageView: UIImageView!
    @IBOutlet weak var emptyTrayLabel: UILabel!
    
    // MARK: - Properties
    private var documents: [Document] = []
    private var filteredDocuments: [Document] = [] // Array for search results
    private var searchController: UISearchController!
    var category: Category? // Property to receive the selected category
    private var selectedDocument: Document? // To store the document to preview
    private var tableViewHeightConstraint: NSLayoutConstraint? // To dynamically adjust table view height
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        filesTableView.layer.cornerRadius = 11
        
        // Apply bottom blur
        applyBlurGradient()
        
        // Set up navigation bar title to the category name
        if let categoryName = category?.name {
            navigationItem.title = categoryName
            print("Set title to: \(categoryName)")
        } else {
            navigationItem.title = "Category"
            print("Set default title: Category")
        }
        
        // Set up search bar
        setupSearchController()
        
        // Set up table view
        setupTableView()
        
        // Fetch documents for the category
        fetchDocuments()
        
        // Style empty state view
        emptyStateView.layer.cornerRadius = 25
        emptyStateView.layer.shadowColor = UIColor.black.cgColor
        emptyStateView.layer.shadowOpacity = 0.5
        emptyStateView.layer.shadowOffset = .zero
        emptyStateView.layer.shadowRadius = 5.0
        emptyStateView.layer.masksToBounds = false
        
        // Update empty state visibility
        updateEmptyStateVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        fetchDocuments()
        filesTableView.reloadData()
        updateTableViewHeight() // Update height when view appears
        updateEmptyStateVisibility()
        
        // Ensure navigation tint colour is white
        self.navigationController?.navigationBar.tintColor = .white
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        navigationController?.navigationBar.standardAppearance = appearance
        appearance.backgroundColor = UIColor.clear
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true
        
        print("View will appear, table view frame: \(String(describing: filesTableView?.frame))")
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

        // Insert Blur View BELOW `addButton`
        view.insertSubview(blurView, aboveSubview: filesTableView!)
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        // Initialize the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        searchController.searchBar.tintColor = .white
        
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
        guard let tableView = filesTableView else {
            print("Error: filesTableView outlet is not connected.")
            return
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear // Set table view background to transparent
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell") // Register a basic cell
        
        // Apply insetGrouped style for margins around cells
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // Adjust margins
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // Match margins
        
        // Remove programmatic constraints if storyboard has them
        tableView.translatesAutoresizingMaskIntoConstraints = true // Let storyboard constraints take over
        
        // Add height constraint for dynamic sizing
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        
        print("Table view setup complete, frame: \(tableView.frame), separatorInset: \(tableView.separatorInset), layoutMargins: \(tableView.layoutMargins)")
    }
    
    private func updateTableViewHeight() {
        guard let tableView = filesTableView else { return }
        let rowHeight: CGFloat = 51
        let totalHeight = CGFloat(filteredDocuments.count) * rowHeight
        tableViewHeightConstraint?.constant = totalHeight
        tableView.layoutIfNeeded()
        print("Updated table view height to: \(totalHeight) for \(filteredDocuments.count) rows")
    }
    
    // MARK: - Update Empty State Visibility
    private func updateEmptyStateVisibility() {
        let isEmpty = filteredDocuments.isEmpty
        emptyStateView.isHidden = !isEmpty
        emptyTrayLabel.isHidden = !isEmpty
        emptyTrayImageView.isHidden = !isEmpty
        filesTableView.isHidden = isEmpty
    }
    
    private func fetchDocuments() {
        guard let category = category else {
            print("No category set for fetching documents")
            return
        }
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY categories == %@", category)
        print("Fetching documents for category: \(category.name ?? "Unnamed") with predicate: \(fetchRequest.predicate?.description ?? "None")")
        
        do {
            documents = try context.fetch(fetchRequest)
            print("Fetched \(documents.count) documents")
            for document in documents {
                print("Fetched document: \(document.name ?? "Unnamed"), Categories: \(document.categories?.allObjects as? [Category] ?? []), PDF Data: \(document.pdfData != nil ? "Available" : "Missing")")
            }
            filteredDocuments = documents
            filesTableView.reloadData()
            updateTableViewHeight() // Update height after fetching
            updateEmptyStateVisibility() // Update empty state visibility after fetching
        } catch {
            print("Error fetching documents: \(error)")
            documents = []
            filteredDocuments = []
        }
    }
    
    // MARK: - Helper Methods
    private func createSamplePDFData() -> Data? {
        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage()
        let textAnnotation = PDFAnnotation(bounds: CGRect(x: 100, y: 100, width: 200, height: 50), forType: .freeText, withProperties: nil)
        textAnnotation.contents = "Sample PDF for Testing"
        pdfPage.addAnnotation(textAnnotation)
        pdfDocument.insert(pdfPage, at: 0)
        return pdfDocument.dataRepresentation()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {
            filteredDocuments = documents // Show all documents if search is empty
        } else {
            // Filter documents based on name
            filteredDocuments = documents.filter { document in
                guard let name = document.name?.lowercased() else { return false }
                return name.contains(searchText)
            }
        }
        
        filesTableView.reloadData()
        updateTableViewHeight() // Update height after filtering
        updateEmptyStateVisibility() // Update empty state visibility after filtering
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount = filteredDocuments.count
        print("Returning \(rowCount) rows for table view")
        return rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        let document = filteredDocuments[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = document.name ?? "Unnamed Document"
        
        // Create a custom button for the disclosure indicator
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        button.tintColor = .systemGray4
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.addTarget(self, action: #selector(disclosureTapped(_:)), for: .touchUpInside)
        cell.accessoryView = button
        
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDocument = filteredDocuments[indexPath.row]
        presentPDFViewer()
    }

    @objc func disclosureTapped(_ sender: UIButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = filesTableView.indexPath(for: cell) else {
            print("Error: Could not determine cell or indexPath from disclosure tap.")
            return
        }
        let document = filteredDocuments[indexPath.row]
        showDetails(for: document)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let document = filteredDocuments[indexPath.row]
        
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
                self.filesTableView.reloadData()
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
    
    // MARK: - PDF Viewer
    private func presentPDFViewer() {
        guard let document = selectedDocument else {
            showAlert(title: "Error", message: "No document selected.")
            return
        }
        
        guard let pdfData = document.pdfData else {
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
        // Use the document name, sanitized for file system compatibility
        let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }

    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Clean up temporary file using the document name
        if let document = selectedDocument {
            let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
            let fileName = "\(documentName).pdf"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Context Menu Actions
    private func showDetails(for document: Document) {
        guard let addDocumentVC = storyboard?.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController else {
            print("Error: Could not instantiate AddDocumentViewController from storyboard.")
            return
        }
        
        // Set the delegate
        addDocumentVC.delegate = self
        
        // Set flags to indicate editing an existing document and read-only mode
        addDocumentVC.isEditingExistingDocument = true
        addDocumentVC.isReadOnly = true
        addDocumentVC.existingDocument = document
        
        // Force view loading to connect outlets
        addDocumentVC.loadViewIfNeeded()
        
        // Debug print to check outlet connections
        print("favoriteSwitch after load: \(String(describing: addDocumentVC.favoriteSwitch))")
        print("nameTextField after load: \(String(describing: addDocumentVC.nameTextField))")
        print("summaryTableView after load: \(String(describing: addDocumentVC.summaryTableView))")
        print("thumbnailImageView after load: \(String(describing: addDocumentVC.thumbnailImageView))")
        print("categoryButton after load: \(String(describing: addDocumentVC.categoryButton))")
        print("reminderSwitch after load: \(String(describing: addDocumentVC.reminderSwitch))")
        print("expiryDatePicker after load: \(String(describing: addDocumentVC.expiryDatePicker))")
        print("expiryDateLabel after load: \(String(describing: addDocumentVC.expiryDateLabel))")
        
        // Pass the selected document's data to AddDocumentViewController
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
        
        // Manually trigger UI update
        addDocumentVC.updateUIWithExistingDocument()
        
        let navController = UINavigationController(rootViewController: addDocumentVC)
        present(navController, animated: true, completion: nil)
    }
    
    // Helper to load images from document
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
    
    // Helper to load summary data from document
    private func loadSummaryData(from document: Document) -> [String: String] {
        guard let summaryData = document.summaryData,
              let json = try? JSONSerialization.jsonObject(with: summaryData, options: []) as? [String: String] else {
            return [:]
        }
        return json
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
            self.documents.removeAll { $0 == document }
            self.filteredDocuments.remove(at: indexPath.row)
            self.filesTableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateTableViewHeight()
            self.updateEmptyStateVisibility()
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
    
    // MARK: - AddDocumentViewControllerDelegate
    func didUpdateDocument() {
        fetchDocuments() // Refresh the data
        filesTableView.reloadData() // Update the table view
        updateTableViewHeight() // Adjust the table view height
        updateEmptyStateVisibility() // Update empty state visibility
    }
}
