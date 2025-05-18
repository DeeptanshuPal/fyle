//
//  AddDocumentViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import UIKit
import CoreData
import PhotosUI

class AddDocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, KeyValueCellDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var AddDocumentScrollView: UIScrollView!
    @IBOutlet weak var AddDocumentScrollContentView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var SummaryView: UITableView!
    @IBOutlet weak var CategoryView: UIView!
    @IBOutlet weak var ReminderView: UIView!
    
    
    // MARK: - Properties
    var selectedImages: [UIImage] = []
    var summaryData: [String: String] = [:]
    var selectedCategories: [Category] = []
    private var isFirstImageSet = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        // Removed navigationItem.rightBarButtonItem for Save button
        navigationItem.title = "Add Document" // Optional: Set a title for context
        
        // Set thumbnail from the first selected image if available
        if !selectedImages.isEmpty {
            thumbnailImageView.image = selectedImages[0]
            isFirstImageSet = true
        }
        
        // setup UI
        nameTextField.layer.cornerRadius = 50
        SummaryView.layer.cornerRadius = 8
        SummaryView.layer.borderWidth = 1
        SummaryView.layer.borderColor = #colorLiteral(red: 0.9129191041, green: 0.9114382863, blue: 0.9338697791, alpha: 0.9029387417)
        CategoryView.layer.cornerRadius = 8
        CategoryView.layer.borderWidth = 1
        CategoryView.layer.borderColor = #colorLiteral(red: 0.9129191041, green: 0.9114382863, blue: 0.9338697791, alpha: 0.9029387417)
        ReminderView.layer.cornerRadius = 8
        ReminderView.layer.borderWidth = 1
        ReminderView.layer.borderColor = #colorLiteral(red: 0.9129191041, green: 0.9114382863, blue: 0.9338697791, alpha: 0.9029387417)
    }
    
    private func setupUI() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        expiryDatePicker.minimumDate = Date()
        expiryDatePicker.isHidden = !reminderSwitch.isOn
    }
    
    private func setupTableView() {
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.rowHeight = UITableView.automaticDimension
        summaryTableView.estimatedRowHeight = 80
        // No register call needed due to storyboard prototype cell
    }
    
    // MARK: - Category Selection
    @IBAction func selectCategoryTapped(_ sender: UIButton) {
        let categories = CoreDataManager.shared.fetchCategories()
        let categoryVC = CategorySelectionViewController(categories: categories, selectedCategories: selectedCategories)
        categoryVC.delegate = self
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
    }
    
    // MARK: - Reminder Toggle
    @IBAction func reminderSwitchToggled(_ sender: UISwitch) {
        expiryDatePicker.isHidden = !sender.isOn
    }
    
    // MARK: - Save Document (Connected to your storyboard Save button)
    @IBAction func saveTapped(_ sender: UIButton) {
        guard validateInputs() else { return }
        
        let pdfData = createPDFFromImages()
        let thumbnailData = thumbnailImageView.image?.jpegData(compressionQuality: 0.7)
        let summaryJSON = try? JSONSerialization.data(withJSONObject: summaryData)
        
        let document = CoreDataManager.shared.createDocument(
            name: nameTextField.text!,
            summaryData: summaryJSON,
            expiryDate: reminderSwitch.isOn ? expiryDatePicker.date : nil,
            thumbnailData: thumbnailData,
            pdfData: pdfData,
            reminderDate: reminderSwitch.isOn ? expiryDatePicker.date : nil,
            categories: NSSet(array: selectedCategories)
        )
        
        CoreDataManager.shared.saveContext()
        dismiss(animated: true) { [weak self] in
            self?.showSuccessMessage()
        }
    }
    
    private func validateInputs() -> Bool {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Missing Name", message: "Please enter a document name")
            return false
        }
        
        guard !selectedImages.isEmpty else {
            showAlert(title: "No Images", message: "Please select at least one image")
            return false
        }
        
        if reminderSwitch.isOn && expiryDatePicker.date < Date() {
            showAlert(title: "Invalid Date", message: "Expiry date must be in the future")
            return false
        }
        
        return true
    }
    
    private func createPDFFromImages() -> Data? {
        let pdfData = NSMutableData()
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        UIGraphicsBeginPDFContextToData(pdfData, bounds, nil)
        for image in selectedImages {
            UIGraphicsBeginPDFPageWithInfo(bounds, nil)
            let aspectRatio = image.size.width / image.size.height
            let scaledBounds = bounds.width / bounds.height > aspectRatio ?
                CGRect(x: 0, y: 0, width: bounds.height * aspectRatio, height: bounds.height) :
                CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width / aspectRatio)
            image.draw(in: scaledBounds)
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessMessage() {
        if let homeVC = presentingViewController as? HomeViewController {
            let alert = UIAlertController(title: "Success", message: "Document saved successfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            homeVC.present(alert, animated: true)
        }
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - TableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryData.count + 1 // +1 for the add row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyValueCell", for: indexPath) as! KeyValueTableViewCell
        
        cell.delegate = self
        cell.index = indexPath.row
        
        if indexPath.row < summaryData.count {
            let key = Array(summaryData.keys)[indexPath.row]
            cell.ColonLabel.text = ":"
            cell.KeyTextField.text = key
            cell.ValueTextField.text = summaryData[key]
        } else {
            cell.KeyTextField.text = ""
            cell.ColonLabel.text = ":"
            //cell.ColonLabel.isHidden = true //hide : label
            cell.ValueTextField.text = ""
        }
        
        return cell
    }
    
    // MARK: - KeyValueCellDelegate
    func didUpdateKeyValue(key: String?, value: String?, at index: Int) {
        guard let key = key, !key.isEmpty, let value = value, !value.isEmpty else { return }
        if index < summaryData.count {
            let oldKey = Array(summaryData.keys)[index]
            summaryData.removeValue(forKey: oldKey)
        }
        summaryData[key] = value
        summaryTableView.reloadData()
    }
}

// MARK: - CategorySelectionDelegate
extension AddDocumentViewController: CategorySelectionDelegate {
    func didSelectCategories(_ categories: [Category]) {
        selectedCategories = categories
        let categoryNames = categories.compactMap { $0.name }.joined(separator: ", ")
        categoryButton.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
    }
}
