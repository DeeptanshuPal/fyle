//
//  FilesViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 08/03/25.
//

import UIKit
import CoreData
import PDFKit
import QuickLook

class FilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, QLPreviewControllerDelegate, AddDocumentViewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filesTableView: UITableView?
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyTrayImageView: UIImageView!
    @IBOutlet weak var emptyTrayLabel: UILabel!
    
    // MARK: - Properties
    private var documents: [Document] = []
    private var filteredDocuments: [Document] = []
    private var searchController: UISearchController!
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var selectedDocument: Document?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Validate and configure table view
        guard let tableView = filesTableView else {
            print("Error: filesTableView outlet is not connected.")
            return
        }
        tableView.layer.cornerRadius = 11
        tableView.backgroundColor = .clear
        
        // Apply bottom blur
        applyBlurGradient()
        
        // Set up navigation bar with large title
        navigationItem.title = "Files"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Set up search controller
        setupSearchController()
        
        // Set up table view
        setupTableView()
        
        // Fetch documents from Core Data
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
        
        // Ensure navigation tint color is white
        self.navigationController?.navigationBar.tintColor = .white
        
        // Refresh data when the view appears
        fetchDocuments()
        filesTableView?.reloadData()
        updateTableViewHeight()
        updateEmptyStateVisibility()
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        navigationController?.navigationBar.standardAppearance = appearance
        appearance.backgroundColor = UIColor.clear
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Ensure large title appears when at the top
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        scrollEdgeAppearance.backgroundColor = .clear
        navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        
        navigationController?.navigationBar.isTranslucent = true
    }
    
    // MARK: Set up bottom Blur
    private func applyBlurGradient() {
        // Create Blur Effect View
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Set the Frame to Cover Bottom 120pt
        blurView.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        // Create Gradient Mask (90% -> 0% opacity)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.9).cgColor,
            UIColor(white: 1.0, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        // Apply Gradient as a Mask to Blur View
        let maskLayer = CALayer()
        maskLayer.frame = blurView.bounds
        maskLayer.addSublayer(gradientLayer)
        blurView.layer.mask = maskLayer
        
        // Insert Blur View at the bottom of the view hierarchy (above table view)
        if let tableView = filesTableView {
            view.insertSubview(blurView, aboveSubview: tableView)
        } else {
            view.addSubview(blurView)
        }
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
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
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 11
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.priority = .defaultHigh // Ensure this constraint is not overridden
        tableViewHeightConstraint?.isActive = true
        
        print("Table view setup complete. Initial height constraint: \(tableViewHeightConstraint?.constant ?? 0)")
    }
    
    private func fetchDocuments() {
        documents = CoreDataManager.shared.fetchDocuments()
        filteredDocuments = documents
        filesTableView?.reloadData()
        updateTableViewHeight()
        updateEmptyStateVisibility()
    }
    
    private func updateTableViewHeight() {
        guard let tableView = filesTableView, let constraint = tableViewHeightConstraint else {
            print("Error: Unable to update table view height - tableView or constraint is nil.")
            return
        }
        let rowHeight: CGFloat = 51
        let totalHeight = CGFloat(filteredDocuments.count) * rowHeight
        constraint.constant = totalHeight
        tableView.layoutIfNeeded()
        print("Updated table view height to: \(totalHeight) for \(filteredDocuments.count) rows.")
    }
    
    // MARK: - Update Empty State Visibility
    private func updateEmptyStateVisibility() {
        guard let tableView = filesTableView else { return }
        let isEmpty = filteredDocuments.isEmpty
        emptyStateView.isHidden = !isEmpty
        emptyTrayLabel.isHidden = !isEmpty
        emptyTrayImageView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDocuments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableView = filesTableView else {
            fatalError("filesTableView is not connected.")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FilesTableViewCell
        let document = filteredDocuments[indexPath.row]
        cell.fileNameLabel.text = document.name ?? "Unnamed Document"
        
        // Create a custom button for the disclosure indicator
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        button.tintColor = .systemGray4
        
        // Explicitly set the button size
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        // Ensure the image scales appropriately
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        
        // Add target for tap action
        button.addTarget(self, action: #selector(disclosureTapped(_:)), for: .touchUpInside)
        
        // Set as accessory view
        cell.accessoryView = button
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableView = filesTableView else {
            print("Error: filesTableView is not connected.")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDocument = filteredDocuments[indexPath.row]
        presentPDFViewer()
    }
    
    @objc func disclosureTapped(_ sender: UIButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = filesTableView?.indexPath(for: cell) else {
            print("Error: Could not determine cell or indexPath from disclosure tap.")
            return
        }
        let document = filteredDocuments[indexPath.row]
        showDetails(for: document)
    }
    
    // MARK: - Context Menu for Tap-and-Hold
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
                self.filesTableView?.reloadData()
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
    
    // MARK: - Delete Confirmation
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
            self.filteredDocuments.removeAll { $0 == document }
            self.filesTableView?.deleteRows(at: [indexPath], with: .automatic)
            self.updateTableViewHeight()
            self.updateEmptyStateVisibility()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Share Document
    private func shareDocument(_ document: Document) {
        guard let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available to share.")
            return
        }
        
        // Create a temporary file URL
        let fileName = (document.name ?? "Unnamed Document") + ".pdf"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            // Write the PDF data to the temporary file
            try pdfData.write(to: tempURL)
            
            // Create the activity view controller with the file URL
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // Set the source view and rect for iPad compatibility
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Present the sharing sheet
            present(activityViewController, animated: true) {
                // Optional: Clean up the temporary file after sharing (though iOS usually handles this)
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            showAlert(title: "Error", message: "Failed to prepare document for sharing: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Show Details Action
    private func showDetails(for document: Document) {
        guard let addDocumentVC = storyboard?.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController else {
            print("Error: Could not instantiate AddDocumentViewController from storyboard.")
            return
        }
        
        // Set the delegate
        addDocumentVC.delegate = self
        
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
        
        // Set flags to indicate editing an existing document and read-only mode
        addDocumentVC.isEditingExistingDocument = true
        addDocumentVC.isReadOnly = true
        addDocumentVC.existingDocument = document // Pass the document object
        
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
    
    // Helper to load images from document (assuming images are stored as PDF or need conversion)
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
    
    // MARK: - PDF Viewer
    func presentPDFViewer() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        previewController.navigationItem.title = selectedDocument?.name ?? "Document" // Set the title here
        previewController.modalPresentationStyle = .fullScreen
        present(previewController, animated: true, completion: nil)
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let pdfData = selectedDocument?.pdfData else {
            fatalError("No PDF data available for preview.")
        }
        
        // Use the document name, sanitized for file system compatibility
        let documentName = (selectedDocument?.name ?? "Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        let documentName = (selectedDocument?.name ?? "Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        if let url = try? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {
            filteredDocuments = documents
        } else {
            filteredDocuments = documents.filter { document in
                guard let name = document.name?.lowercased() else { return false }
                return name.contains(searchText)
            }
        }
        
        filesTableView?.reloadData()
        updateTableViewHeight()
        updateEmptyStateVisibility()
        print("Search updated. Filtered documents: \(filteredDocuments.count), Height: \(tableViewHeightConstraint?.constant ?? 0)")
    }
    
    // MARK: - AddDocumentViewControllerDelegate
    func didUpdateDocument() {
        fetchDocuments() // Refresh the data
        filesTableView?.reloadData() // Update the table view
        updateTableViewHeight() // Adjust the table view height
        updateEmptyStateVisibility() // Update empty state visibility
    }
}
