//
//  AddDocumentViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import UIKit
import CoreData
import PhotosUI
import Vision

// Custom UIImageView subclass for top-aligned, center-horizontal aspect fill with equal left/right cropping
class TopAlignedAspectFillImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let image = image else { return }
        
        // Set content mode to aspect fill
        contentMode = .scaleAspectFill
        
        // Calculate aspect ratios
        let imageAspectRatio = image.size.width / image.size.height
        let viewAspectRatio = bounds.width / bounds.height
        
        if imageAspectRatio > viewAspectRatio {
            // Image is wider than the view (height determines scaling to preserve top)
            let scale = bounds.height / image.size.height // Scale to fit height
            let scaledWidth = image.size.width * scale
            let excessWidth = scaledWidth - bounds.width // Total width to crop
            let xOffset = excessWidth / 2 / scaledWidth // Offset to center, cropping equally from left and right
            layer.contentsRect = CGRect(x: xOffset, y: 0, width: bounds.width / scaledWidth, height: 1)
        } else {
            // Image is taller than the view (width determines scaling, top is preserved)
            let scale = bounds.width / image.size.width // Scale to fit width
            let scaledHeight = image.size.height * scale
            let excessHeight = scaledHeight - bounds.height // Height to crop from bottom
            // No xOffset needed since width fits, y=0 keeps top aligned
            layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: bounds.height / scaledHeight)
        }
        
        // Ensure clipping to bounds
        clipsToBounds = true
    }
}

class AddDocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, KeyValueCellDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var AddDocumentScrollView: UIScrollView!
    @IBOutlet weak var AddDocumentScrollContentView: UIView!
    @IBOutlet weak var thumbnailImageView: TopAlignedAspectFillImageView! // Updated to custom class
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var expiryDateLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var favoriteSwitch: UISwitch!
    
    @IBOutlet weak var SummaryView: UITableView! // Consider removing this redundant outlet
    @IBOutlet weak var CategoryView: UIView!
    @IBOutlet weak var ReminderView: UIView!
    @IBOutlet weak var FavouriteView: UIView!
    
    // MARK: - Constraints
    @IBOutlet weak var reminderViewHeightConstraint: NSLayoutConstraint! // Outlet for dynamic height
    
    // MARK: - Properties
    var selectedImages: [UIImage] = []
    var summaryData: [String: String] = [:]
    var selectedCategories: [Category] = []
    private var isFirstImageSet = false
    private var tableViewHeightConstraint: NSLayoutConstraint? // For dynamic summaryTableView height
    
    // Keywords for auto-categorization
    private let categoryKeywords: [String: [String]] = [
        "Home": ["lease", "rent", "mortgage", "property", "house", "apartment", "landlord", "tenant", "utility", "maintenance"],
        "Vehicle": ["auto", "car", "insurance", "registration", "loan", "vehicle", "VIN", "license", "plate", "maintenance", "repair"],
        "School": ["school", "tuition", "fee", "admission", "exam", "result", "report", "certificate", "diploma", "transcript"],
        "Bank": ["bank", "account", "statement", "loan", "credit", "debit", "transaction", "interest", "balance", "overdraft"],
        "Medical": ["health", "medical", "hospital", "prescription", "doctor", "patient", "diagnosis", "treatment", "insurance", "bill"],
        "College": ["college", "university", "admission", "fee", "scholarship", "exam", "result", "certificate", "transcript", "graduation"],
        "Land": ["land", "property", "deed", "survey", "plot", "ownership", "lease", "rent", "mortgage", "registry"],
        "Warranty": ["warranty", "guarantee", "product", "repair", "replacement", "validity", "expiry", "terms", "conditions", "service"],
        "Family": ["family", "marriage", "birth", "certificate", "divorce", "adoption", "guardianship", "inheritance", "will", "estate"],
        "Travel": ["travel", "ticket", "flight", "hotel", "booking", "itinerary", "visa", "passport", "reservation", "tour"],
        "Business": ["business", "contract", "agreement", "invoice", "tax", "partnership", "incorporation", "license", "permit", "compliance"],
        "Insurance": ["insurance", "policy", "premium", "claim", "coverage", "health", "life", "vehicle", "property", "renewal"],
        "Education": ["education", "school", "college", "tuition", "fee", "certificate", "diploma", "transcript", "result", "admission"],
        "Emergency": ["emergency", "contact", "medical", "accident", "police", "fire", "ambulance", "hospital", "insurance", "report"],
        "Miscellaneous": ["miscellaneous", "other", "general", "uncategorized", "unknown", "document", "file", "note", "record", "archive"]
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.title = "Add Document"
        
        // Set thumbnail from the first selected image
        if !selectedImages.isEmpty {
            thumbnailImageView.image = selectedImages[0]
            isFirstImageSet = true
            processSelectedImages() // Automatically extract details
        }
        
        // UI Setup
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 0.7967197848)
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
        FavouriteView.layer.cornerRadius = 8
        FavouriteView.layer.borderWidth = 1
        FavouriteView.layer.borderColor = #colorLiteral(red: 0.9129191041, green: 0.9114382863, blue: 0.9338697791, alpha: 0.9029387417)
        
        // Disable summary table view scroll
        summaryTableView.isScrollEnabled = false
        
        // Initialize reminder section
        reminderSwitch.isOn = false
        expiryDateLabel.isHidden = true
        expiryDatePicker.isHidden = true
        updateReminderViewHeight()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update the scroll view's content size to fit all content
        let contentHeight = saveButton.frame.maxY + 20 // Add padding at the bottom
        AddDocumentScrollView.contentSize = CGSize(width: AddDocumentScrollView.frame.width, height: contentHeight)
        print("Scroll view content size: \(AddDocumentScrollView.contentSize)")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        thumbnailImageView.clipsToBounds = true
        expiryDatePicker.minimumDate = Date()
        expiryDatePicker.isHidden = !reminderSwitch.isOn
    }
    
    private func setupTableView() {
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.rowHeight = UITableView.automaticDimension
        summaryTableView.estimatedRowHeight = 80
        
        // Set up dynamic height for summaryTableView
        summaryTableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewHeightConstraint = summaryTableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        updateTableViewHeight()
    }
    
    private func updateTableViewHeight() {
        let rowHeight: CGFloat = 51.5
        let totalHeight = (CGFloat(summaryData.count) * rowHeight) + 40
        tableViewHeightConstraint?.constant = totalHeight
        summaryTableView.layoutIfNeeded()
        print("Updated summaryTableView height to: \(totalHeight)")
    }
    
    // MARK: - Actions
    @IBAction func reminderSwitchToggled(_ sender: UISwitch) {
        let isOn = sender.isOn
        
        // Animate the height change and visibility
        UIView.animate(withDuration: 0.3, animations: {
            // Update visibility and alpha for fade effect
            self.expiryDatePicker.isHidden = !isOn
            self.expiryDateLabel.isHidden = !isOn
            self.expiryDatePicker.alpha = isOn ? 1.0 : 0.0
            self.expiryDateLabel.alpha = isOn ? 1.0 : 0.0
            
            // Update height
            self.updateReminderViewHeight()
            
            // Apply the layout changes
            self.view.layoutIfNeeded()
        })
    }
    
    private func updateReminderViewHeight() {
        let newHeight: CGFloat = reminderSwitch.isOn ? 107.0 : 50.0 // Fixed heights as specified
        reminderViewHeightConstraint?.constant = newHeight
        print("Updated ReminderView height to: \(newHeight)")
    }
    
    // MARK: - Automatic Document Processing
    private func processSelectedImages() {
        extractDocumentDetails { [weak self] in
            self?.updateUIWithExtractedData()
        }
    }
    
    private func extractDocumentDetails(completion: @escaping () -> Void) {
        guard !selectedImages.isEmpty else { return }
        
        var extractedText = ""
        let dispatchGroup = DispatchGroup()
        
        // OCR Processing
        for image in selectedImages {
            dispatchGroup.enter()
            recognizeTextFrom(image: image) { text in
                extractedText += "\(text)\n"
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            
            // 1. Extract Document Name
            self.nameTextField.text = self.extractDocumentName(from: extractedText)
            
            // 2. Extract Summary
            self.summaryData = self.extractKeyValuePairs(from: extractedText)
            
            // 3. Determine Category
            self.selectedCategories = [self.detectCategory(from: extractedText)]
            self.categoryButton.setTitle(self.selectedCategories.first?.name ?? "Select Category", for: .normal)
            
            // 4. Set Expiry & Reminder
            self.setExpiryAndReminder(from: extractedText)
            
            self.summaryTableView.reloadData()
            self.updateTableViewHeight() // Update table view height after reloading data
            self.updateReminderViewHeight() // Ensure reminder view height is updated
            completion()
        }
    }
    
    private func updateUIWithExtractedData() {
        summaryTableView.reloadData()
        categoryButton.setTitle(selectedCategories.first?.name ?? "Select Category", for: .normal)
        updateTableViewHeight() // Ensure height updates after UI changes
        updateReminderViewHeight() // Ensure reminder view height is updated
    }
    
    // MARK: - Helper Methods
    private func extractDocumentName(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        if let titleLine = lines.first(where: { $0.lowercased().contains("title:") }) {
            return titleLine.replacingOccurrences(of: "title:", with: "").trimmingCharacters(in: .whitespaces)
        }
        return lines.first(where: { !$0.isEmpty }) ?? "Document \(Date().formatted(.dateTime.day().month().year()))"
    }
    
    private func extractKeyValuePairs(from text: String) -> [String: String] {
        let pattern = "([A-Za-z ]+):\\s*(.*)"
        let regex = try? NSRegularExpression(pattern: pattern)
        var pairs = [String: String]()
        
        text.enumerateLines { line, _ in
            guard let match = regex?.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
                  let keyRange = Range(match.range(at: 1), in: line),
                  let valueRange = Range(match.range(at: 2), in: line) else { return }
            
            let key = String(line[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = String(line[valueRange]).trimmingCharacters(in: .whitespaces)
            
            if !key.isEmpty && !value.isEmpty {
                pairs[key] = value
            }
        }
        return pairs
    }
    
    private func detectCategory(from text: String) -> Category {
        let lowerText = text.lowercased()
        
        for (categoryName, keywords) in categoryKeywords {
            if keywords.contains(where: { lowerText.contains($0) }) {
                return CoreDataManager.shared.fetchCategories().first { $0.name == categoryName }!
            }
        }
        
        // Fallback to Miscellaneous
        return CoreDataManager.shared.fetchCategories().first { $0.name == "Miscellaneous" }!
    }
    
    private func setExpiryAndReminder(from text: String) {
        let dates = detectDates(in: text)
        let expiryDate = dates.last ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        // Set reminder 1 month before expiry
        let reminderDate = Calendar.current.date(byAdding: .month, value: -1, to: expiryDate)!
        
        expiryDatePicker.date = expiryDate
        reminderSwitch.isOn = true
        expiryDatePicker.isHidden = false
        expiryDateLabel.isHidden = false
        // Animate the transition since this changes the state
        UIView.animate(withDuration: 0.3, animations: {
            self.expiryDatePicker.alpha = 1.0
            self.expiryDateLabel.alpha = 1.0
            self.updateReminderViewHeight()
            self.view.layoutIfNeeded()
        })
    }
    
    private func detectDates(in text: String) -> [Date] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        var dates = [Date]()
        
        detector?.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) { match, _, _ in
            guard let date = match?.date else { return }
            dates.append(date)
        }
        
        return dates.sorted()
    }
    
    private func recognizeTextFrom(image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(text)
        }
        
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
    
    // MARK: - Save Document
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
            isFavorite: favoriteSwitch.isOn,
            categories: NSSet(array: selectedCategories),
            sharedWith: nil
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
        return summaryData.count
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
        updateTableViewHeight() // Update height after modifying summaryData
    }
    
    // MARK: - Category Selection
    @IBAction func selectCategoryTapped(_ sender: UIButton) {
        let categories = CoreDataManager.shared.fetchCategories()
        let categoryVC = CategorySelectionViewController(categories: categories, selectedCategories: selectedCategories)
        categoryVC.delegate = self
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
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
