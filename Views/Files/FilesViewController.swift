//
//  FilesViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//

import UIKit

class FilesViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentInteractionControllerDelegate {

    // Array for file names in the table view
    var files = ["Aadhar Card", "Health Insurance", "Warranty Card", "Mark Sheet", "Car Insurance", "Passport", "Driving License", "Pollution Control", "Certification", "Birth Certificate"]
    var filteredFiles: [String] = []

    // Document interaction controller
    var documentInteractionController: UIDocumentInteractionController?

    // Outlets for Buttons and TableView
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet var AddButtonView: UIView!

    // Search controller
    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize filtered files array with all files
        filteredFiles = files

        // Set up search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Change search bar appearance
        searchController.searchBar.isTranslucent = true // Make it translucent
        searchController.searchBar.barTintColor = .clear // Ensure the bar itself is clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Semi-transparent text field

        // Set table view delegates
        tableView.dataSource = self
        tableView.delegate = self

        // Register a default UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")

        // Configure button titles (modify as needed)
        button1.setTitle("Vehicle", for: .normal)
        button2.setTitle("Health", for: .normal)
        button3.setTitle("Education", for: .normal)

        // Configure AddButtonView appearance
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false

        tableView.layer.cornerRadius = 13
    }

    // MARK: - TableView DataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = filteredFiles[indexPath.row]
        return cell
    }

    // MARK: - Open Document on Cell Tap

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = filteredFiles[indexPath.row]
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            // Initialize and set up the document interaction controller
            documentInteractionController = UIDocumentInteractionController(url: fileURL)
            documentInteractionController?.delegate = self
            
            // Present the document preview
            documentInteractionController?.presentPreview(animated: true)
        } else {
            print("Document \(fileName) not found.")
        }

        // Deselect the row after selection
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }

    // MARK: - Search Results Updating Delegate Method

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredFiles = files
        } else {
            filteredFiles = files.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
}

