//
//  VehicleViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//


//==============THIS View Controller Code HAS NO USE ANYMORE --- DELETE AFTER REVIEW=======================
//=========================================================================================================

import UIKit

class VehicleViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIDocumentInteractionControllerDelegate {
    
    var files = ["Driving License","Sample Document", "Vehicle Insurance", "Vehicle Registration", "Emission Test Certificate"]
    var filteredFiles: [String] = []
    var documentInteractionController: UIDocumentInteractionController?

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var AddButtonView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
            searchBar.searchTextField.backgroundColor = .white // Make the search bar text field white
            searchBar.barTintColor = .white                    // Set the search bar background color to white
            searchBar.backgroundImage = UIImage()              // Remove any default background
            
        filteredFiles = files
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        
        tableView.layer.cornerRadius = 13

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = filteredFiles[indexPath.row]
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredFiles = searchText.isEmpty ? files : files.filter { $0.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    // MARK: - Open Document on Cell Tap
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Open the specific document file
        if let fileURL = Bundle.main.url(forResource: "sampleDocument", withExtension: "pdf") {
            // Initialize and set up the document interaction controller
            documentInteractionController = UIDocumentInteractionController(url: fileURL)
            documentInteractionController?.delegate = self
            
            // Present the document preview
            documentInteractionController?.presentPreview(animated: true)
        } else {
            print("Document not found.")
        }
        
        // Deselect the row after selection
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }



}
