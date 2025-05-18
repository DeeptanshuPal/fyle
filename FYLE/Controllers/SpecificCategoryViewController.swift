//
//  SpecificCategoryViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit
import CoreData
import QuickLook

class SpecificCategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filesTableView: UITableView! // Assuming this is the outlet name from FilesViewController
    
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
        
        // Populate sample data if needed (for testing)
        populateSampleDataIfNeeded()
        
        // Fetch documents for the category
        fetchDocuments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        fetchDocuments()
        filesTableView.reloadData()
        updateTableViewHeight() // Update height when view appears
        
        // ensure navigation tint colour is white
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
        let rowHeight: CGFloat = 51.5
        let totalHeight = CGFloat(filteredDocuments.count) * rowHeight
        tableViewHeightConstraint?.constant = totalHeight
        tableView.layoutIfNeeded()
        print("Updated table view height to: \(totalHeight) for \(filteredDocuments.count) rows")
    }
    
    private func populateSampleDataIfNeeded() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0, let category = category {
                // Populate sample data if no documents exist
                print("Populating sample data for category: \(category.name ?? "Unnamed")")
                let doc1 = Document(context: context)
                doc1.name = "\(category.name ?? "Category") Document 1"
                doc1.categories = NSSet(object: category)
                // Add sample PDF data for testing
                if let pdfData = createSamplePDFData() {
                    doc1.pdfData = pdfData
                }
                
                let doc2 = Document(context: context)
                doc2.name = "\(category.name ?? "Category") Document 2"
                doc2.categories = NSSet(object: category)
                if let pdfData = createSamplePDFData() {
                    doc2.pdfData = pdfData
                }
                
                CoreDataManager.shared.saveContext()
            }
        } catch {
            print("Error checking document count: \(error)")
        }
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
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount = filteredDocuments.count
        print("Returning \(rowCount) rows for table view")
        return rowCount // Use filtered array
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        
        let document = filteredDocuments[indexPath.row] // Use filtered array
        
        // Configure cell (allowing storyboard background color)
        cell.textLabel?.text = document.name ?? "Unnamed Document"
        cell.accessoryType = .disclosureIndicator // Add disclosure indicator for tappable rows
        cell.selectionStyle = .default // Allow selection highlight
        
        print("Configured cell at \(indexPath) with document: \(document.name ?? "Unnamed")")
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDocument = filteredDocuments[indexPath.row]
        print("Selected document: \(selectedDocument?.name ?? "Unnamed")")
        presentPDFViewer()
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
}
