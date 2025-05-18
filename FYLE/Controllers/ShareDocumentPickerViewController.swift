//
//  ShareDocumentPickerViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 16/03/25.
//


import UIKit
import CoreData

protocol ShareDocumentPickerDelegate: AnyObject {
    func didSelectDocument(_ document: Document)
}

class ShareDocumentPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private var documents: [Document] = []
    private var filteredDocuments: [Document] = []
    private var searchController: UISearchController!
    weak var delegate: ShareDocumentPickerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up navigation bar
        title = "Select Document"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))
        
        // Set up search controller
        setupSearchController()
        
        // Set up table view
        setupTableView()
        
        // Fetch documents
        fetchDocuments()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableViewHeight()
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Documents"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DocumentCell")
        tableView.tableFooterView = UIView() // Remove empty rows
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0) // Match native inset
        tableView.backgroundColor = .systemGroupedBackground // Use system background color
        tableView.separatorStyle = .singleLine
        tableView.layer.cornerRadius = 12
        tableView.layer.masksToBounds = true
        
        // Disable scrolling to make height dynamic
        tableView.isScrollEnabled = false
    }
    
    private func fetchDocuments() {
        documents = CoreDataManager.shared.fetchDocuments()
        filteredDocuments = documents
        tableView.reloadData()
        updateTableViewHeight()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDocuments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        let document = filteredDocuments[indexPath.row]
        
        // Configure cell with native appearance
        cell.textLabel?.text = document.name ?? "Unnamed Document"
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body) // Use system font
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .secondarySystemGroupedBackground // Match native cell background
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let document = filteredDocuments[indexPath.row]
        delegate?.didSelectDocument(document)
        dismiss(animated: true)
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
        
        tableView.reloadData()
        updateTableViewHeight()
    }
    
    // MARK: - Actions
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    // MARK: - Dynamic Table View Height
    private func updateTableViewHeight() {
        // Calculate the required height based on content size
        let height = tableView.contentSize.height
        tableViewHeightConstraint.constant = height
        
        // Animate the height change
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}
