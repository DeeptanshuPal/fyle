//
//  CategoriesViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit
import CoreData

class CategoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating {
    
    // MARK: - IBOutlets
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    
    // MARK: - Properties
    private var categories: [Category] = []
    private var filteredCategories: [Category] = [] // Array for search results
    private var searchController: UISearchController!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply background gradient and bottom blur
        setupGradientBackground()
        applyBlurGradient()
        
        // Set up navigation bar
        navigationItem.title = "Categories"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Set up search bar
        setupSearchController()
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        // Change appearance
        searchController.searchBar.isTranslucent = true // Make it translucent
        searchController.searchBar.barTintColor = .clear // Ensure the bar itself is clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Semi-transparent text field
        
        // Set up collection view
        setupCollectionView()
        
        // Fetch categories from Core Data
        fetchCategories()
        
        //
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        fetchCategories()
        categoriesCollectionView.reloadData()
        
        // ensure navigation tint colour is white
        self.navigationController?.navigationBar.tintColor = .white
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        navigationController?.navigationBar.standardAppearance = appearance
        appearance.backgroundColor = UIColor.clear
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true
    }
    
    // MARK: Setup BG Gradient
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 65/255, green: 124/255, blue: 198/255, alpha: 1.0).cgColor, // #417CC6
            UIColor(red: 113/255, green: 195/255, blue: 247/255, alpha: 1.0).cgColor, // #71C3F7
            UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0).cgColor  // #F6F6F6
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: Set up bottom Blur
    private func applyBlurGradient() {
        // Create Blur Effect View
        let blurEffect = UIBlurEffect(style: .light) // Change to .dark if needed
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Set the Frame to Cover Bottom 120pt
        blurView.frame = CGRect(x: 0, y: view.bounds.height - 70, width: view.bounds.width, height: 70)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin] // Adjust for different screen sizes

        // Create Gradient Mask (90% -> 0% opacity)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.9).cgColor, // 90% opacity at bottom
            UIColor(white: 1.0, alpha: 0.0).cgColor   // 0% opacity at top
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Start at bottom
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Fade to top

        // Apply Gradient as a Mask to Blur View
        let maskLayer = CALayer()
        maskLayer.frame = blurView.bounds
        maskLayer.addSublayer(gradientLayer)
        blurView.layer.mask = maskLayer

        // Insert Blur View BELOW `addButton`
        view.insertSubview(blurView, aboveSubview: categoriesCollectionView)
    }
    
    // MARK: - Setup Methods
    private func setupSearchController() {
        // Initialize the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Categories"
        searchController.searchBar.tintColor = .white
        
        // Add the search bar to the navigation bar
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false // Show search bar by default
        
        // Ensure the search bar doesn't hide the navigation bar
        definesPresentationContext = true
    }
    
    private func setupCollectionView() {
        guard let collectionView = categoriesCollectionView else {
            print("Error: categoriesCollectionView outlet is not connected.")
            return
        }
        collectionView.dataSource = self
        collectionView.delegate = self
        // Ensure collection view can scroll and set transparent background
        collectionView.alwaysBounceVertical = true // Allows scrolling even with small content
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0) // Optional padding
        collectionView.backgroundColor = .clear // Set collection view background to transparent
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 10 // Space between items in the same row
            layout.minimumLineSpacing = 15     // Space between rows
            layout.scrollDirection = .vertical // Explicitly set to vertical scrolling
        }
    }
    
    private func fetchCategories() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            categories = try context.fetch(fetchRequest)
            for category in categories {
                let documentCount = countDocuments(in: category)
            }
            // Initialize filteredCategories with all categories
            filteredCategories = categories
            categoriesCollectionView.reloadData()
        } catch {
            print("Error fetching categories: \(error)")
            categories = []
            filteredCategories = []
        }
    }
    
    private func countDocuments(in category: Category) -> Int {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        // Use the 'categories' to-many relationship instead of 'category'
        fetchRequest.predicate = NSPredicate(format: "ANY categories == %@", category)
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("Error counting documents for category \(category.name ?? ""): \(error)")
            return 0
        }
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {
            filteredCategories = categories // Show all categories if search is empty
        } else {
            // Filter categories based on name
            filteredCategories = categories.filter { category in
                guard let name = category.name?.lowercased() else { return false }
                return name.contains(searchText)
            }
        }
        
        categoriesCollectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCategories.count // Use filtered array
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as? CategoryCollectionViewCell else {
            fatalError("Unable to dequeue CategoryCollectionViewCell")
        }
        
        let category = filteredCategories[indexPath.item] // Use filtered array
        
        // Set category name
        cell.categoryNameLabel.text = category.name ?? "Unnamed Category"
        
        // Set document count
        let documentCount = countDocuments(in: category)
//        cell.countLabel.text = "\(documentCount) Files"
        cell.countLabel.text = "\(documentCount)"
        
        // Set category color for the filled circle background
        if let colorName = category.categoryColour {
            // Map string color names to UIColor
            let color = colorNameFromString(colorName) ?? .gray // Use custom mapping function
            cell.categoryColorView.backgroundColor = color
        } else {
            cell.categoryColorView.backgroundColor = .gray // Default color if nil
            print("No color for \(category.name ?? "Unnamed"), using gray")
        }
        
        // Set category image
        if let imageName = category.categoryImage {
            if let image = UIImage(systemName: imageName) {
                cell.categoryImageView.image = image
            } else {
                cell.categoryImageView.image = UIImage(systemName: "questionmark.circle") // Default if invalid
            }
        } else {
            cell.categoryImageView.image = UIImage(systemName: "questionmark.circle") // Default if nil
        }
        
        // Ensure the categoryImageView is centered and clipped within the categoryColorView
        cell.categoryImageView.contentMode = .scaleAspectFit
        cell.categoryColorView.layer.cornerRadius = cell.categoryColorView.frame.width / 2 // Make it a circle
        cell.categoryColorView.clipsToBounds = true
        
        // Other UI setup for the cell
        // Force layout to resolve constraints
        cell.layoutIfNeeded()
        
//        //countPillView
//        cell.fileCountPillView.layer.cornerRadius = 13
//        cell.fileCountPillView.layer.shadowColor = UIColor.black.cgColor
//        cell.fileCountPillView.layer.shadowOpacity = 0.3
//        cell.fileCountPillView.layer.shadowOffset = .zero
//        cell.fileCountPillView.layer.shadowRadius = 3.0
//        /// Define the shadow path to match the bounds of the pill view
//        cell.fileCountPillView.layer.shadowPath = UIBezierPath(roundedRect: cell.fileCountPillView.bounds, cornerRadius: 13).cgPath
//        /// Ensure masksToBounds is false to allow the shadow to appear outside
//        cell.fileCountPillView.layer.masksToBounds = false
//        /// If the view's background is transparent, ensure it has a solid background color
//        cell.fileCountPillView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        
        //categoryImageView
        cell.categoryColorView.layer.cornerRadius = cell.categoryColorView.layer.frame.width / 2 - 4
        cell.categoryColorView.layer.shadowColor = UIColor.black.cgColor
        cell.categoryColorView.layer.shadowOpacity = 0.35
        cell.categoryColorView.layer.shadowOffset = .zero
        cell.categoryColorView.layer.shadowRadius = 4.0
        /// Ensure masksToBounds is false to allow the shadow to appear outside
        cell.categoryColorView.layer.masksToBounds = false
        
        // Add shadow to the cell
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.2
        cell.layer.shadowOffset = .zero
        cell.layer.shadowRadius = 5.0
        cell.layer.masksToBounds = false // Ensure shadow is visible
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 11).cgPath
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        // UI Setup
        cell.layer.cornerRadius = 11
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = filteredCategories[indexPath.item] // Use filtered array
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let destinationVC = storyboard.instantiateViewController(withIdentifier: "SpecificCategoryViewController") as? SpecificCategoryViewController {
            destinationVC.category = category
            navigationController?.pushViewController(destinationVC, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let minimumHorizontalGap: CGFloat = 16
        let padding: CGFloat = 20 // Total padding space (left + right edges)
        let maxItemWidth: CGFloat = 200
        
        // Set edge padding via section insets
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: padding / 2, bottom: 0, right: padding / 2)
        }
        
        // Calculate available width after accounting for edge padding
        let availableWidth = collectionView.frame.width - padding
        // Calculate base width for 2 columns with minimum gap
        let baseWidth = (availableWidth - minimumHorizontalGap) / 2
        
        // Determine actual item width and resulting horizontal gap
        let itemWidth: CGFloat
        var horizontalGap: CGFloat
        
        if baseWidth > maxItemWidth {
            itemWidth = maxItemWidth
            // Calculate new horizontal gap when width is capped
            horizontalGap = availableWidth - (2 * maxItemWidth)
        } else {
            itemWidth = baseWidth
            horizontalGap = minimumHorizontalGap
        }
        
        // Use the same gap value for vertical and horizontal spacing
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = horizontalGap
            flowLayout.minimumLineSpacing = horizontalGap
        }
        
        return CGSize(width: itemWidth, height: 80)
    }
    
    // MARK: - Helper Method for Color Mapping
    private func colorNameFromString(_ colorName: String) -> UIColor? {
        let lowercasedName = colorName.lowercased()
        switch lowercasedName {
        case "systemyellow":
            return .systemYellow
        case "systembrown":
            return .systemBrown
        case "systemteal":
            return .systemTeal
        case "systemgreen":
            return .systemGreen
        case "systempink":
            return .systemPink
        case "systemblue":
            return .systemBlue
        case "systempurple":
            return .systemPurple
        case "systemindigo":
            return .systemIndigo
        case "systemorange":
            return .systemOrange
        case "systemred":
            return .systemRed
        case "systemgray":
            return .systemGray
        case "green":
            return .green
        case "orange":
            return .orange
        case "darkgray":
            return .darkGray
        default:
            print("Unknown color name: \(colorName), defaulting to gray") // Debug unknown colors
            return UIColor(named: colorName) // Fallback to asset catalog or nil
        }
    }
}
