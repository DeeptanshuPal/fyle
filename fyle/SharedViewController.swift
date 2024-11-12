//
//  SharedViewController.swift
//  fyle
//
//  Created by User@77 on 08/11/24.
//

import UIKit

class SharedViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // Array for file names in the table view
    var files = ["Aadhar Card", "10th MarkSheet", "Birth Certificate","Heath Insurance"]
    var filteredFiles: [String] = []

    // Outlets for the Search Bar, Buttons, and TableView
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet var AddButtonView: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize filtered files array with all files
        filteredFiles = files
        
        // Set delegates for search bar and table view
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register a default UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Configure button titles (modify as needed)
        button1.setTitle("Deeptanshu", for: .normal)
        button2.setTitle("Sreeraj", for: .normal)
        button3.setTitle("Rose", for: .normal)
        
        button1.layer.cornerRadius = 10
        button2.layer.cornerRadius = 10
        button3.layer.cornerRadius = 10
        
        
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


