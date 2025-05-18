//
//  SpecificCategoryViewController.swift
//  fyle
//
//  Created by User@77 on 19/11/24.
//


    
import UIKit

class SpecificCategoryViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    // Data array
    var files: [String] = [
        "Car Insurance Policy",
        "Vehicle Registration Certificate",
        "Service Invoice - March",
        "Emission Test Certificate",
        "Driving License Renewal Notice",
        "Tire Replacement Invoice",
        "Car Purchase Agreement",
        "Fuel Expense Tracker"
    ]
    var filteredFiles: [String] = []

    var categoryTitle: String?

    // Outlets
    @IBOutlet var AddButtonView: UIView!
    @IBOutlet weak var tableView: UITableView!

    // Search controller
    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view controller title
        self.title = categoryTitle

        // Initialize filteredFiles with all files
        filteredFiles = files

        // Configure search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        // change appearance
        searchController.searchBar.isTranslucent = true // Make it translucent
        searchController.searchBar.barTintColor = .clear // Ensure the bar itself is clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Semi-transparent text field

        // Set up the table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        tableView.layer.cornerRadius = 13

        // Configure AddButtonView
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
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

    // MARK: - Search Results Updating Method

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
