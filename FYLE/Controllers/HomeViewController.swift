//
//  HomeViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 28/02/25.
//


import UIKit
import CoreData
import PhotosUI
import QuickLook
import VisionKit // Added for document scanning

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    @IBOutlet weak var tileCollectionView: UICollectionView!
    
    @IBOutlet weak var favouritesTableView: UITableView!
    @IBOutlet weak var favouritesImageBGView: UIView!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var profileButton: UIBarButtonItem!
    
    // MARK: - Setup Navigation Bar Appearance
    private func configureNavigationBar() {
        // Ensure large titles are enabled
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Create and configure a custom appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 238/255, green: 249/255, blue: 255/255, alpha: 1.0), // #EEF9FF
            .font: UIFont.systemFont(ofSize: 52, weight: .heavy)
        ]
        
        
        // Apply the appearance to the navigation bar
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
        // Set the title
        navigationItem.title = " fyle."
    }
    
    // MARK: - Properties
    private var selectedDocument: Document? // To store the selected document for preview
    private var tableViewHeightConstraint: NSLayoutConstraint? // To dynamically adjust table view height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply background gradient and bottom blur
        setupGradientBackground()
        applyBlurGradient()
        
        // initial nav bar setup
        configureNavigationBar()
        
        // Populate categories only if not already done
        if !UserDefaults.standard.bool(forKey: "categoriesPopulated") {
            CoreDataManager.shared.populateSampleCategories()
            UserDefaults.standard.set(true, forKey: "categoriesPopulated")
        }
        
        // Tile grid
        tileCollectionView.dataSource = self
        tileCollectionView.delegate = self
        tileCollectionView.backgroundColor = .clear
        if let layout = tileCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero // Disable automatic sizing
        }
        
        // Favourites table view setup
        setupTableView()
        
        // UI Misc.
        favouritesImageBGView.layer.cornerRadius = 20
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.5
        addButton.layer.shadowOffset = .zero
        addButton.layer.shadowRadius = 5.0
        addButton.layer.masksToBounds = false
        
        profileButton.isHidden = true // hide profile button (temporarily for review)
    }
    
    @IBAction func profileTapped(_ sender: Any) {
        // Add functionality here later
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
    
    // MARK: Set up Bottom Blur
    private func applyBlurGradient() {
        // Create Blur Effect View
        let blurEffect = UIBlurEffect(style: .light) // Change to .dark if needed
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Set the Frame to Cover Bottom 120pt
        blurView.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
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
        view.insertSubview(blurView, belowSubview: addButton)
    }
    
    // MARK: Setup Tile Info
    struct Tile {
        let title: String
        let imageName: String
        let count: Int
        let titleColor: UIColor // Title text color
        let imageColor: UIColor // Image tint color
        let countColor: UIColor // Count text color
        let bgColor: UIColor // Background color
    }
    
    var tiles: [Tile] {
        let documentsCount = CoreDataManager.shared.fetchDocuments().count
        let remindersCount = CoreDataManager.shared.fetchDocumentsWithReminders().count
        let categoriesCount = CoreDataManager.shared.fetchCategories().count
        let sharedCount = CoreDataManager.shared.fetchShares().count
        
        return [
            Tile(title: "Files", imageName: "folder", count: documentsCount,
                 titleColor: #colorLiteral(red: 0.2509803922, green: 0.4823529412, blue: 0.7725490196, alpha: 1),
                 imageColor: #colorLiteral(red: 0.2509803922, green: 0.4823529412, blue: 0.7725490196, alpha: 1),
                 countColor: #colorLiteral(red: 0.4078431373, green: 0.6901960784, blue: 0.8745098039, alpha: 1),
                 bgColor: #colorLiteral(red: 0.7568627451, green: 0.9019607843, blue: 1, alpha: 1)),
            
            Tile(title: "Reminders", imageName: "bell.badge", count: remindersCount,
                 titleColor: #colorLiteral(red: 0.7725490196, green: 0.2509803922, blue: 0.2509803922, alpha: 1),
                 imageColor: #colorLiteral(red: 0.7725490196, green: 0.2509803922, blue: 0.2509803922, alpha: 1),
                 countColor: #colorLiteral(red: 0.8745098039, green: 0.4078431373, blue: 0.4078431373, alpha: 1),
                 bgColor: #colorLiteral(red: 1, green: 0.7568627451, blue: 0.7568627451, alpha: 1)),
            
            Tile(title: "Categories", imageName: "square.grid.2x2", count: categoriesCount,
                 titleColor: #colorLiteral(red: 0.09803921569, green: 0.7764705882, blue: 0.3450980392, alpha: 1),
                 imageColor: #colorLiteral(red: 0.09803921569, green: 0.7764705882, blue: 0.3450980392, alpha: 1),
                 countColor: #colorLiteral(red: 0.3529411765, green: 0.8, blue: 0.4784313725, alpha: 1),
                 bgColor: #colorLiteral(red: 0.7568627451, green: 1, blue: 0.8549019608, alpha: 1)),
            
            Tile(title: "Shared", imageName: "person.2", count: sharedCount,
                 titleColor: #colorLiteral(red: 1, green: 0.5803921569, blue: 0.003921568627, alpha: 1),
                 imageColor: #colorLiteral(red: 1, green: 0.5803921569, blue: 0.003921568627, alpha: 1),
                 countColor: #colorLiteral(red: 0.9921568627, green: 0.7647058824, blue: 0.3176470588, alpha: 1),
                 bgColor: #colorLiteral(red: 1, green: 0.9333333333, blue: 0.7568627451, alpha: 1))
        ]
    }
    
    // MARK: - Setup Table View
    private func setupTableView() {
        favouritesTableView.dataSource = self
        favouritesTableView.delegate = self
        favouritesTableView.backgroundColor = .clear
        favouritesTableView.layer.cornerRadius = 11
        
        // Ensure the table view uses Auto Layout
        favouritesTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add height constraint for dynamic sizing
        tableViewHeightConstraint = favouritesTableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
    }
    
    // MARK: - Update Table View Height
    private func updateTableViewHeight() {
        let rowHeight: CGFloat = 51.5
        let totalHeight = CGFloat(favourites.count) * rowHeight
        tableViewHeightConstraint?.constant = totalHeight
        favouritesTableView.layoutIfNeeded()
    }
    
    // UICollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath) as! TileCollectionViewCell
        
        let tileInfo = tiles[indexPath.row]
        cell.configure(with: tileInfo) // Configure from TileCollectionViewCell.swift
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 17 // Space between cells
        let totalSpacing = (2 - 1) * spacing // 2 columns, so 1 space between them
        
        let collectionViewWidth = collectionView.frame.width
        let itemWidth = (collectionViewWidth - totalSpacing) / 2 // 2 items per row
        
        return CGSize(width: itemWidth, height: 112) // Adjust height as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 18 // Vertical spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 17 // Horizontal spacing between items
    }
    
    // Ensure cells are left-aligned in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // Align all items to the left
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tile = tiles[indexPath.row]
        if tile.title == "Files" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let filesVC = storyboard.instantiateViewController(withIdentifier: "FilesViewController") as? FilesViewController {
                navigationController?.pushViewController(filesVC, animated: true)
            }
        } else if tile.title == "Categories" { // Add navigation for Categories tile
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let categoriesVC = storyboard.instantiateViewController(withIdentifier: "CategoriesViewController") as? CategoriesViewController {
                navigationController?.pushViewController(categoriesVC, animated: true)
            }
        } else if tile.title == "Reminders" { // Add navigation for Reminders tile
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let remindersVC = storyboard.instantiateViewController(withIdentifier: "RemindersViewController") as? RemindersViewController {
                navigationController?.pushViewController(remindersVC, animated: true)
            }
        }
        
        else if tile.title == "Shared" { // Add navigation for Reminders tile
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let sharedVC = storyboard.instantiateViewController(withIdentifier: "sharedVC") as? sharedVC {
                navigationController?.pushViewController(sharedVC, animated: true)
            }
        }
    }
    
    // MARK: Favourites TableView
    var favourites: [Document] {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        do {
            return try CoreDataManager.shared.context.fetch(request)
        } catch {
            print("Error fetching favorites: \(error)")
            return []
        }
    }
    
    // Add viewWillAppear to refresh data and update height
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reapply navigation bar configuration
        configureNavigationBar()
        
        // Refresh data
        tileCollectionView.reloadData()
        favouritesTableView.reloadData()
        updateTableViewHeight() // Update height after reloading data
    }
    
    // Update table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favourites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteCell", for: indexPath) as! FavouriteTableViewCell
        let document = favourites[indexPath.row]
        cell.FavouriteFileName.text = document.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDocument = favourites[indexPath.row]
        presentPDFViewer()
    }
    
    // MARK: - PDF Viewer
    private func presentPDFViewer() {
        guard let document = selectedDocument else {
            showAlert(title: "Error", message: "No document selected.")
            return
        }
        
        guard let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available for this document.")
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        // Set custom title based on document name
        previewController.navigationItem.title = document.name ?? "Document"
        
        // Present modally to use default QuickLook navigation bar
        previewController.modalPresentationStyle = .fullScreen
        present(previewController, animated: true, completion: nil)
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let document = selectedDocument, let pdfData = document.pdfData else {
            fatalError("PDF data is unexpectedly nil.")
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf")
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Clean up temporary file
        if let url = try? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.pdf") {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Photo Picker
    private func presentPhotoPicker() {
        // Configure photo picker to allow multiple image selections
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0 means unlimited selections
        config.filter = .images // Restrict to images only
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Document Picker
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Set to true if you want to allow multiple PDFs
        present(documentPicker, animated: true)
    }
    
    // MARK: - Document Scanner
    private func presentDocumentScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            showAlert(title: "Error", message: "Document scanning is not supported on this device.")
            return
        }
        
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }
    
    // MARK: - Transition to AddDocumentViewController
    private func presentAddDocumentViewController(with images: [UIImage]) {
        // Instantiate AddDocumentViewController from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addVC = storyboard.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController {
            // Pass selected images
            addVC.selectedImages = images
            // Wrap in navigation controller for Cancel/Save buttons
            let navController = UINavigationController(rootViewController: addVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    // MARK: - Transition to AddDocumentViewController with PDF
    private func presentAddDocumentViewController(with pdfData: Data) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addVC = storyboard.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController {
            // Pass the PDF data instead of images
            addVC.pdfData = pdfData
            let navController = UINavigationController(rootViewController: addVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    // MARK: - Add Button Action
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Create action sheet with three options
        let alert = UIAlertController(title: "Upload a Document", message: nil, preferredStyle: .actionSheet)
        
        // Option 1: Scan and Upload
        alert.addAction(UIAlertAction(title: "Scan and Upload", style: .default, handler: { _ in
            self.presentDocumentScanner()
        }))
        
        // Option 2: Upload from Gallery
        alert.addAction(UIAlertAction(title: "Upload from Gallery", style: .default, handler: { _ in
            self.presentPhotoPicker()
        }))
        
        // Option 3: Upload PDF
        alert.addAction(UIAlertAction(title: "Upload from Files", style: .default, handler: { _ in
            self.presentDocumentPicker()
        }))
        
        // Cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present the action sheet
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss the picker
        picker.dismiss(animated: true)
        
        // Array to store selected images
        var selectedImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        // Load each selected image
        for result in results {
            dispatchGroup.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    selectedImages.append(image)
                }
                dispatchGroup.leave()
            }
        }
        
        // When all images are loaded, proceed
        dispatchGroup.notify(queue: .main) {
            if !selectedImages.isEmpty {
                self.presentAddDocumentViewController(with: selectedImages)
            } else {
                print("No images were selected")
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension HomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            // Access the file securely
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Read the PDF data
            let pdfData = try Data(contentsOf: url)
            
            // Dismiss the picker and present AddDocumentViewController
            controller.dismiss(animated: true) {
                self.presentAddDocumentViewController(with: pdfData)
            }
        } catch {
            print("Error loading PDF: \(error)")
            showAlert(title: "Error", message: "Failed to load the selected PDF.")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate
extension HomeViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Dismiss the scanner
        controller.dismiss(animated: true)
        
        // Convert scanned pages to UIImages
        var scannedImages: [UIImage] = []
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            scannedImages.append(image)
        }
        
        // Proceed only if images were scanned
        if !scannedImages.isEmpty {
            presentAddDocumentViewController(with: scannedImages)
        } else {
            print("No pages were scanned")
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) {
            self.showAlert(title: "Scanning Error", message: error.localizedDescription)
        }
    }
}
