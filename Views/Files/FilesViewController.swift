//
//  FilesViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//

import UIKit

class FilesViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentInteractionControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // Array for file names in the table view
    var files = ["Aadhar Card", "Health Insurance", "Warranty Card", "Mark Sheet", "Car Insurance", "Passport", "Driving License", "Pollution Control", "Mark Sheet", "Car Insurance", "Passport", "Driving License"]
    var filteredFiles: [String] = []
    
    // List of header tags
    struct Tags {
        var title: String
        var image: String
    }
    
    let tags: [Tags] = [
        Tags(title: "Home", image: "house.fill"),
        Tags(title: "Vehicle", image: "car.fill"),
        Tags(title: "School", image: "book.fill"),
        Tags(title: "Bank", image: "dollarsign.bank.building.fill"),
        Tags(title: "Medical", image: "cross.case.fill")
    ]
    
    // Document interaction controller
    var documentInteractionController: UIDocumentInteractionController?

    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var AddButtonView: UIView!
    @IBOutlet weak var TagsCollectionView: UICollectionView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint! // Adjusts table view height dynamically

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
        
        // Style search bar
        searchController.searchBar.isTranslucent = true
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        // Set table view delegates
        tableView.dataSource = self
        tableView.delegate = self
        
        // Set collection view delegates
        TagsCollectionView.delegate = self
        TagsCollectionView.dataSource = self
        
        // Configure AddButtonView appearance
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false

        tableView.layer.cornerRadius = 13
        updateTableViewHeight() // Adjust table view height after filtering
    }
    
    // MARK: - Helper Function to Update Table View Height
    func updateTableViewHeight() {
        let rowHeight: CGFloat = 47.0
        let newHeight = rowHeight * CGFloat(filteredFiles.count)
        view.layoutIfNeeded() // Apply changes immediately
        
        // Animate the height change
        UIView.animate(withDuration: 0.15, animations: {
            self.tableViewHeightConstraint.constant = newHeight
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FilesTableViewCell
        cell.FileNameLabel.text = filteredFiles[indexPath.row]
        return cell
    }
    
    // MARK: - CollectionView DataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! HeaderTagsCollectionViewCell
        let tag = tags[indexPath.row]
        cell.HeaderTagImageView.image = UIImage(systemName: tag.image) // Set SF Symbol image
        cell.HeaderTagNameLabel.text = tag.title // Set label
        return cell
    }

    // CollectionView Flow Layout Delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt index: Int) -> CGFloat {
        return 10 // Spacing between cells
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
        updateTableViewHeight() // Adjust table view height after filtering
    }
}

