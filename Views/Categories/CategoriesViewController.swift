//
//  CategoriesViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit


// categories struct
struct Categories {
    let title: String
    let image: String
    let color: UIColor
    let numberOfFilesInCategory: Int
}

// instances of struct with all category data
let categories: [Categories] = [
    Categories(title: "Home", image: "house.fill", color: .systemYellow, numberOfFilesInCategory: 5),
    Categories(title: "Vehicle", image: "car.fill", color: .systemBrown, numberOfFilesInCategory: 8),
    Categories(title: "School", image: "book.fill", color: .systemTeal, numberOfFilesInCategory: 10),
    Categories(title: "Bank", image: "dollarsign.bank.building.fill", color: .systemGreen, numberOfFilesInCategory: 13),
    Categories(title: "Medical", image: "cross.case.fill", color: .systemPink, numberOfFilesInCategory: 7),
    Categories(title: "College", image: "graduationcap.fill", color: .systemBlue, numberOfFilesInCategory: 5),
    Categories(title: "Land", image: "map.fill", color: .green, numberOfFilesInCategory: 9),
    Categories(title: "Warranty", image: "scroll.fill", color: .systemPurple, numberOfFilesInCategory: 14),
    Categories(title: "Family", image: "figure.2.and.child.holdinghands", color: .orange, numberOfFilesInCategory: 23),
    Categories(title: "Travel", image: "airplane", color: .systemBrown, numberOfFilesInCategory: 3),
    Categories(title: "Business", image: "coat", color: .systemIndigo, numberOfFilesInCategory: 6),
    Categories(title: "Insurance", image: "shield.fill", color: .darkGray, numberOfFilesInCategory: 11),
    Categories(title: "Education", image: "a.book.closed.fill", color: .systemOrange, numberOfFilesInCategory: 10),
    Categories(title: "Emergency", image: "phone.fill", color: .systemRed, numberOfFilesInCategory: 0),
    Categories(title: "Miscellaneous", image: "tray.full.fill", color: .systemYellow, numberOfFilesInCategory: 19),
    Categories(title: "Miscellaneous", image: "tray.full.fill", color: .systemIndigo, numberOfFilesInCategory: 15)
]



class CategoriesViewController: GradientBGViewController, UISearchResultsUpdating {
    // UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredCategories = categories // Show all categories if search is empty
            CategoriesCollectionView.reloadData()
            return
        }
        // Filter categories based on the search text
        filteredCategories = categories.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        CategoriesCollectionView.reloadData()
    }
    
    
    @IBOutlet var AddButtonView: UIView!
    @IBOutlet var CategoriesCollectionView: UICollectionView!
    
    // Set up Search
    let searchController = UISearchController()
    var filteredCategories: [Categories] = categories // Initially display all categories
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // Makes the background translucent
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Text color for small titles
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white] // Text color for large titles
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3) // Adjust alpha for translucency
        navigationController?.navigationBar.standardAppearance = appearance
        appearance.backgroundColor = UIColor.clear
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true // Ensure the navigation bar is translucent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Search Controller
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        // change appearance
        searchController.searchBar.isTranslucent = true // Make it translucent
        searchController.searchBar.barTintColor = .clear // Ensure the bar itself is clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Semi-transparent text field
        
        
        // Set delegates
        CategoriesCollectionView.delegate = self
        CategoriesCollectionView.dataSource = self
        
        //making background of collection view transparent
        CategoriesCollectionView.backgroundColor = .clear
        
        
        
        // Configure AddButtonView
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        

        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSpecificCategory" {
            if let destinationVC = segue.destination as? SpecificCategoryViewController,
               let selectedIndexPath = CategoriesCollectionView.indexPathsForSelectedItems?.first { // Get the first selected item
                let selectedCategory = filteredCategories[selectedIndexPath.row]
                destinationVC.categoryTitle = selectedCategory.title
            }
        }
    }
    
}



extension CategoriesViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCategories.count // Use filteredCategories for the count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCollectionViewCell
        
        // Configure the cell
        let category = filteredCategories[indexPath.row] // Use filteredCategories here
        cell.CategoryImageView.image = UIImage(systemName: category.image)
        cell.CategoryImageBGView.backgroundColor = category.color
        cell.CategoryNameLabel.text = category.title
        cell.NumOfFilesInCategory.text = "\(category.numberOfFilesInCategory) files"
        
        // Apply corner radius
        cell.layer.cornerRadius = 11
        cell.CategoryImageBGView.layer.cornerRadius = cell.CategoryImageBGView.frame.height / 2
        
        return cell
    }
}

extension CategoriesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 173, height: 67) // Adjust height as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 13 // Vertical spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 13 // Horizontal spacing between items
    }
    // Ensure cells are left-aligned in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // Align all items to the left
    }
    

}
