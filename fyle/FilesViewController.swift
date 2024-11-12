//
//  FilesViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//

import UIKit

class FilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // Array for file names in the table view
    var files = [ "Aadhar Card","Health Insurance.pdf", "Waranty Card", "Mark Sheet"]
    var filteredFiles: [String] = []

    // Outlets for the Title, Search Bar, Buttons, and TableView
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up main title
        mainTitleLabel.text = "Files"

        // Initialize filtered files array with all files
        filteredFiles = files
        
        // Set delegates for search bar and table view
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register a default UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Configure button titles (modify as needed)
        button1.setTitle("Vechicle", for: .normal)
        button2.setTitle("Health", for: .normal)
        button3.setTitle("Education", for: .normal)
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
    
    // MARK: - Search Bar Delegate Method for Filtering Files

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFiles = files
        } else {
            filteredFiles = files.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
}

