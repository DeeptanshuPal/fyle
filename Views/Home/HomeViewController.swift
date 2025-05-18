//
//  HomeViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

class HomeViewController: GradientBGViewController, UIDocumentPickerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, AddFileFormDelegate, PHPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIDocumentInteractionControllerDelegate {
    
    let favourites = ["Aadhar Card", "Health Insurance", "Warranty Card", "Mark Sheet", "Car Insurance", "Passport", "Driving License", "Pollution Control", "Certification", "Birth Certificate"]
    
    var documentInteractionController: UIDocumentInteractionController?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favourites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favouriteCell", for: indexPath)
        cell.textLabel?.text = favourites[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Return nil to remove the header for each section
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Return nil to remove the footer for each section
        return nil
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Return nil to remove the header text (for default header with title)
        return nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // Return nil to remove the footer text (for default footer with title)
        return nil
    }

    
    // MARK: - Open Document on Cell Tap
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = favourites[indexPath.row]
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
    
    // MARK: - PHPickerViewControllerDelegate Method
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    self.presentAddFileForm(withImage: image)
                } else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    // MARK: - AddFileFormDelegate Method
    func didSaveFileDetails(name: String, reminder: Date?, summary: String, isConfidential: Bool) {
        let newFile = File(
            id: UUID(),
            name: name,
            category: "Uncategorized",
            createdDate: Date(),
            expirationDate: reminder,
            summary: summary,
            isConfidential: isConfidential,
            isFavorite: false,
            sharedWith: [],
            filePath: URL(fileURLWithPath: ""),
            fileType: "Unknown",
            lastModified: Date(),
            fileSize: nil,
            titleImage: nil,
            reminderDate: reminder
        )
        
        DataManager.shared.addFile(newFile)
        print("File saved: \(newFile.name)")
    }
    
    // MARK: - Outlets
    @IBOutlet weak var FilesTileView: UIView!
    @IBOutlet weak var FilesTileImageView: UIView!
    @IBOutlet weak var filesCountLabel: UILabel!
    @IBOutlet weak var RemindersTileView: UIView!
    @IBOutlet weak var RemindersTileImageView: UIView!
    @IBOutlet weak var RemindersCountLabel: UILabel!
    @IBOutlet weak var CategoriesTileView: UIView!
    @IBOutlet weak var CategoriesTileImageView: UIView!
    @IBOutlet weak var CategoriesCountLabel: UILabel!
    @IBOutlet weak var SharedTileView: UIView!
    @IBOutlet weak var SharedTileImageView: UIView!
    @IBOutlet weak var SharedCountLabel: UILabel!
    @IBOutlet weak var FavouritesImageView: UIView!
    @IBOutlet weak var AddButtonView: UIView!
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setupUI()
        
        loadFiles()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        [FilesTileView, RemindersTileView, CategoriesTileView, SharedTileView].forEach {
            $0?.layer.cornerRadius = 11
        }
        
        [FilesTileImageView, RemindersTileImageView, CategoriesTileImageView, SharedTileImageView, FavouritesImageView].forEach {
            $0?.layer.cornerRadius = 20
        }
        
        AddButtonView.layer.cornerRadius = 37.5
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        
        tableView.layer.cornerRadius = 11
    }
    
    // MARK: - Actions
    @IBAction func addBoxTapped(_ sender: UITapGestureRecognizer) {
        showAddOptions()
    }
    
    private func showAddOptions() {
        let actionSheet = UIAlertController(title: "Add New File", message: "Choose an option", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Scan and Upload", style: .default, handler: { _ in
            self.openCameraForScan()
        }))
        actionSheet.addAction(UIAlertAction(title: "Upload from Gallery", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Upload from Files", style: .default, handler: { _ in
            self.openFiles()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func openCameraForScan() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func openFiles() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func presentAddFileForm(withImage image: UIImage? = nil, fileURL: URL? = nil) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let addFileFormVC = storyboard.instantiateViewController(withIdentifier: "AddFileFormViewController") as? AddFileFormViewController else { return }
        addFileFormVC.fileThumbnail = image
        addFileFormVC.fileURL = fileURL
        addFileFormVC.delegate = self
        present(addFileFormVC, animated: true, completion: nil)
    }
    
    private func loadFiles() {
        let files = DataManager.shared.fetchFiles()
        filesCountLabel.text = "\(10)"
        RemindersCountLabel.text = "\(5)"
        CategoriesCountLabel.text = "\(16)"
        SharedCountLabel.text = "\(4)"
    }
}
