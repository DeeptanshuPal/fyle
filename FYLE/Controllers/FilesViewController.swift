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

class FilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filesTableView: UITableView?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation tint color is white
        self.navigationController?.navigationBar.tintColor = .white
        
        // Refresh data when the view appears
        fetchDocuments()
        filesTableView?.reloadData()
        updateTableViewHeight()
        
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
        print("Fetched \(filteredDocuments.count) documents. Updated height to: \(tableViewHeightConstraint?.constant ?? 0)")
    }
    
    private func updateTableViewHeight() {
        guard let tableView = filesTableView, let constraint = tableViewHeightConstraint else {
            print("Error: Unable to update table view height - tableView or constraint is nil.")
            return
        }
        let rowHeight: CGFloat = 51.5
        let totalHeight = CGFloat(filteredDocuments.count) * rowHeight
        constraint.constant = totalHeight
        tableView.layoutIfNeeded()
        print("Updated table view height to: \(totalHeight) for \(filteredDocuments.count) rows.")
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
        cell.accessoryType = .disclosureIndicator
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
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf")
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if let url = try? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf") {
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
        print("Search updated. Filtered documents: \(filteredDocuments.count), Height: \(tableViewHeightConstraint?.constant ?? 0)")
    }
}
