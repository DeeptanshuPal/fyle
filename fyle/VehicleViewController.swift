//
//  VehicleViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//

import UIKit

class VehicleViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIDocumentInteractionControllerDelegate {
    
    var files = ["Driving License","Sample Document", "Vehicle Insurance", "Vehicle Registration", "Emission Test Certificate"]
    var filteredFiles: [String] = []
    var documentInteractionController: UIDocumentInteractionController?

    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
            searchBar.searchTextField.backgroundColor = .white // Make the search bar text field white
            searchBar.barTintColor = .white                    // Set the search bar background color to white
            searchBar.backgroundImage = UIImage()              // Remove any default background
            
        
        mainTitleLabel.text = "Vehicle"
        filteredFiles = files
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        tableView.layer.cornerRadius = 13
        
        makeNavigationBarTransparent()
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
    func makeNavigationBarTransparent() {
        // Check if there is a navigation controller
        if let navigationController = self.navigationController {
            // Set the navigation bar to be transparent
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
            navigationController.navigationBar.isTranslucent = true
        }
    }

}
