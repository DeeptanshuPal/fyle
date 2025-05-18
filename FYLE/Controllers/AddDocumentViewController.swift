//
// AddDocumentViewController.swift
// FYLE
//
// Created by Deeptanshu Pal on 04/03/25.
//

import UIKit
import CoreData
import PhotosUI
import Vision
import PDFKit
import QuickLook

// Delegate protocol for notifying FilesViewController
protocol AddDocumentViewControllerDelegate: AnyObject {
    func didUpdateDocument()
}

// Custom UIImageView subclass for top-aligned, center-horizontal aspect fill with equal left/right cropping
class TopAlignedAspectFillImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let image = image else {
            print("No image set in TopAlignedAspectFillImageView")
            return
        }
        
        contentMode = .scaleAspectFill
        
        let imageAspectRatio = image.size.width / image.size.height
        let viewAspectRatio = bounds.width / bounds.height
        
        if imageAspectRatio > viewAspectRatio {
            let scale = bounds.height / image.size.height
            let scaledWidth = image.size.width * scale
            let excessWidth = scaledWidth - bounds.width
            let xOffset = excessWidth / 2 / scaledWidth
            layer.contentsRect = CGRect(x: xOffset, y: 0, width: bounds.width / scaledWidth, height: 1)
        } else {
            let scale = bounds.width / image.size.width
            let scaledHeight = image.size.height * scale
            let excessHeight = scaledHeight - bounds.height
            layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: bounds.height / scaledHeight)
        }
        
        clipsToBounds = true
    }
}

class AddDocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, KeyValueCellDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var AddDocumentScrollView: UIScrollView!
    @IBOutlet weak var AddDocumentScrollContentView: UIView!
    @IBOutlet weak var thumbnailImageView: TopAlignedAspectFillImageView!
    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var summaryTableView: UITableView?
    @IBOutlet weak var categoryButton: UIButton?
    @IBOutlet weak var reminderSwitch: UISwitch?
    @IBOutlet weak var expiryDatePicker: UIDatePicker?
    @IBOutlet weak var expiryDateLabel: UILabel?
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var favoriteSwitch: UISwitch?
    
    @IBOutlet weak var SummaryView: UITableView!
    @IBOutlet weak var CategoryView: UIView!
    @IBOutlet weak var ReminderView: UIView!
    @IBOutlet weak var FavouriteView: UIView!
    
    // MARK: - Constraints
    @IBOutlet weak var reminderViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var selectedImages: [UIImage]? // Changed to optional from implicitly unwrapped optional
    var pdfData: Data?
    var summaryData: [String: String] = [:]
    var selectedCategories: [Category] = []
    private var isFirstImageSet = false
    private var tableViewHeightConstraint: NSLayoutConstraint?
    var isEditingExistingDocument = false
    var isReadOnly = false
    var existingDocument: Document?
    weak var delegate: AddDocumentViewControllerDelegate?
    
    // Updated keywords for auto-categorization
    private let categoryKeywords: [String: [String]] = [
        "Home": ["lease", "rent", "mortgage", "property", "house", "apartment", "landlord", "tenant", "utility", "maintenance", "real estate", "residence", "homeowner", "rental"],
        "Vehicle": ["auto", "car", "insurance", "registration", "loan", "vehicle", "vin", "license", "plate", "maintenance", "repair", "truck", "suv", "motor"],
        "School": ["school", "tuition", "fee", "admission", "exam", "result", "report", "certificate", "diploma", "transcript", "student", "teacher", "class"],
        "Bank": ["bank", "account", "statement", "loan", "credit", "debit", "transaction", "interest", "balance", "deposit", "withdrawal", "savings", "mortgage"],
        "Medical": ["health", "medical", "hospital", "prescription", "doctor", "patient", "diagnosis", "treatment", "insurance", "bill", "pharmacy", "medicine"],
        "College": ["college", "university", "admission", "fee", "scholarship", "exam", "result", "certificate", "transcript", "graduation", "degree", "semester"],
        "Land": ["land", "property", "deed", "survey", "plot", "ownership", "lease", "rent", "mortgage", "registry", "acre", "title"],
        "Warranty": ["warranty", "guarantee", "product", "repair", "replacement", "validity", "expiry", "terms", "service", "coverage"],
        "Family": ["family", "marriage", "birth", "certificate", "divorce", "adoption", "inheritance", "will", "estate", "parent", "child"],
        "Travel": ["travel", "ticket", "flight", "hotel", "booking", "itinerary", "visa", "passport", "reservation", "tour", "vacation", "trip"],
        "Business": ["business", "contract", "agreement", "invoice", "tax", "partnership", "license", "permit", "company", "client", "vendor"],
        "Insurance": ["insurance", "policy", "premium", "claim", "coverage", "health", "life", "vehicle", "property", "renewal", "deductible"],
        "Education": ["education", "school", "college", "tuition", "fee", "certificate", "diploma", "transcript", "course", "training"],
        "Emergency": ["emergency", "contact", "medical", "accident", "police", "fire", "ambulance", "hospital", "report", "safety"],
        "Miscellaneous": ["miscellaneous", "other", "general", "uncategorized", "unknown", "document", "file", "note", "record"]
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.title = isReadOnly ? "Document Details" : "Add Document"
        
        // Add "Open" button to the right side
        let openButton = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped))
        if isReadOnly {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped)), openButton]
        } else {
            navigationItem.rightBarButtonItem = openButton
        }
        
        print("viewDidLoad called, isEditingExistingDocument: \(isEditingExistingDocument), isReadOnly: \(isReadOnly), pdfData: \(pdfData != nil)")
        
        if let pdfData = pdfData {
            if let thumbnail = generateThumbnailFromPDF(data: pdfData) {
                print("Setting thumbnail to imageView")
                thumbnailImageView.image = thumbnail
                isFirstImageSet = true
                thumbnailImageView.setNeedsDisplay()
            } else {
                print("Failed to generate thumbnail")
            }
            if !isEditingExistingDocument {
                processPDFData(pdfData)
            }
        } else if let images = selectedImages, !images.isEmpty {
            thumbnailImageView.image = images[0]
            isFirstImageSet = true
            if !isEditingExistingDocument {
                processSelectedImages()
            }
        }
        
        // UI Setup
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 0.7967197848)
        nameTextField?.layer.cornerRadius = 50
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
        
        summaryTableView?.isScrollEnabled = false
        
        reminderSwitch?.isOn = false
        expiryDatePicker?.isHidden = true
        expiryDateLabel?.isHidden = true
        expiryDatePicker?.alpha = 0.0
        expiryDateLabel?.alpha = 0.0
        updateReminderViewHeight()
        
        if isEditingExistingDocument || isReadOnly {
            updateUIWithExistingDocument()
        }
        // Keyboard Dismiss Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let openButton = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped))
        
        if isReadOnly {
            navigationItem.rightBarButtonItems = [
                openButton, // Rightmost
                UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped)) // Left of Open
            ]
            configureReadOnlyMode()
        } else {
            navigationItem.rightBarButtonItems = [openButton]
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight = saveButton.isHidden ? (saveButton.frame.minY - 20) : (saveButton.frame.maxY + 20)
        AddDocumentScrollView.contentSize = CGSize(width: AddDocumentScrollView.frame.width, height: contentHeight)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        thumbnailImageView.clipsToBounds = true
        expiryDatePicker?.minimumDate = Date()
        expiryDatePicker?.isHidden = true
    }
    
    private func setupTableView() {
        summaryTableView?.dataSource = self
        summaryTableView?.delegate = self
        summaryTableView?.rowHeight = UITableView.automaticDimension
        summaryTableView?.estimatedRowHeight = 80
        
        summaryTableView?.translatesAutoresizingMaskIntoConstraints = false
        tableViewHeightConstraint = summaryTableView?.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        updateTableViewHeight()
    }
    
    private func updateTableViewHeight() {
        let rowHeight: CGFloat = 51.5
        let totalHeight = (CGFloat(summaryData.count) * rowHeight) + 40
        tableViewHeightConstraint?.constant = totalHeight
        summaryTableView?.reloadData()
        summaryTableView?.layoutIfNeeded()
    }
    
    // MARK: - Actions
    @IBAction func reminderSwitchToggled(_ sender: UISwitch?) {
        let isOn = sender?.isOn ?? false
        UIView.animate(withDuration: 0.3) {
            self.expiryDatePicker?.isHidden = !isOn
            self.expiryDateLabel?.isHidden = !isOn
            self.expiryDatePicker?.alpha = isOn ? 1.0 : 0.0
            self.expiryDateLabel?.alpha = isOn ? 1.0 : 0.0
            self.updateReminderViewHeight()
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateReminderViewHeight() {
        let newHeight: CGFloat = (reminderSwitch?.isOn ?? false) ? 107.0 : 50.0
        reminderViewHeightConstraint?.constant = newHeight
    }
    
    @objc func editTapped() {
        isReadOnly = false
        navigationItem.title = "Edit Document"
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped))]
        configureEditableMode()
    }
    
    @objc func openTapped() {
        guard let pdfDataToView = pdfData ?? createPDFFromImages() else {
            showAlert(title: "Error", message: "No PDF data available to open.")
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        previewController.navigationItem.title = nameTextField?.text ?? existingDocument?.name ?? "Document"
        
        previewController.modalPresentationStyle = .fullScreen
        present(previewController, animated: true, completion: nil)
    }
    
    private func configureEditableMode() {
        nameTextField?.isEnabled = true
        nameTextField?.isUserInteractionEnabled = true
        reminderSwitch?.isEnabled = true
        reminderSwitch?.isUserInteractionEnabled = true
        favoriteSwitch?.isEnabled = true
        favoriteSwitch?.isUserInteractionEnabled = true
        categoryButton?.isEnabled = true
        categoryButton?.isUserInteractionEnabled = true
        expiryDatePicker?.isUserInteractionEnabled = true
        saveButton?.isHidden = false
        if let heightConstraint = saveButton?.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = 44
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        summaryTableView?.reloadData()
    }
    
    // MARK: - Automatic Document Processing
    private func processSelectedImages() {
        extractDocumentDetails { [weak self] in
            self?.updateUIWithExtractedData()
        }
    }
    
    private func extractDocumentDetails(completion: @escaping () -> Void) {
        guard let images = selectedImages, !images.isEmpty else { return }
        
        var extractedText = ""
        let dispatchGroup = DispatchGroup()
        
        for image in images {
            dispatchGroup.enter()
            recognizeTextFrom(image: image) { text in
                extractedText += "\(text)\n"
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.nameTextField?.text = self.extractDocumentName(from: extractedText)
            self.summaryData = self.extractKeyValuePairs(from: extractedText)
            self.selectedCategories = self.detectCategories(from: extractedText)
            let categoryNames = self.selectedCategories.compactMap { $0.name }.joined(separator: ", ")
            self.categoryButton?.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
            self.setExpiryAndReminder(from: extractedText)
            self.summaryTableView?.reloadData()
            self.updateTableViewHeight()
            self.updateReminderViewHeight()
            completion()
        }
    }
    
    // MARK: - PDF Processing
    private func processPDFData(_ pdfData: Data) {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("Failed to create PDFDocument from data")
            showAlert(title: "Error", message: "Unable to process the PDF file.")
            return
        }
        
        var extractedText = ""
        let dispatchGroup = DispatchGroup()
        
        // Step 1: Try extracting text using PDFKit
        for pageNum in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageNum) {
                if let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), !pageText.isEmpty {
                    extractedText += pageText + "\n"
                }
            }
        }
        
        // Step 2: If no text or insufficient text, use OCR
        if extractedText.isEmpty || extractedText.count < 20 {
            print("Insufficient text from PDFKit (\(extractedText.count) characters), using OCR")
            for pageNum in 0..<min(pdfDocument.pageCount, 2) { // Limit to first 2 pages
                dispatchGroup.enter()
                if let page = pdfDocument.page(at: pageNum) {
                    if let pageImage = generateImageFromPDFPage(page) {
                        recognizeTextFrom(image: pageImage) { text in
                            extractedText += text + "\n"
                            dispatchGroup.leave()
                        }
                    } else {
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        } else {
            print("Text extracted via PDFKit: \(extractedText)")
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            if extractedText.isEmpty {
                print("No text extracted from PDF")
                self.showAlert(title: "Warning", message: "Unable to extract text from the PDF. Please fill in the details manually.")
                self.nameTextField?.text = "Untitled Document"
                self.summaryData = [:]
                self.selectedCategories = []
                self.categoryButton?.setTitle("Select Categories", for: .normal)
                self.reminderSwitch?.isOn = false
                self.expiryDatePicker?.isHidden = true
                self.expiryDateLabel?.isHidden = true
            } else {
                self.nameTextField?.text = self.extractDocumentName(from: extractedText)
                self.summaryData = self.extractKeyValuePairs(from: extractedText)
                self.selectedCategories = self.detectCategories(from: extractedText)
                let categoryNames = self.selectedCategories.compactMap { $0.name }.joined(separator: ", ")
                self.categoryButton?.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
                self.setExpiryAndReminder(from: extractedText)
            }
            self.summaryTableView?.reloadData()
            self.updateTableViewHeight()
            self.updateReminderViewHeight()
        }
    }
    
    // Generate image from a PDF page with correct orientation
    private func generateImageFromPDFPage(_ page: PDFPage) -> UIImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // Increase resolution for better OCR
        let rendererSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: rendererSize)
        
        let image = renderer.image { ctx in
            ctx.cgContext.saveGState()
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: rendererSize))
            
            // Adjust for PDF coordinate system (origin at bottom-left)
            ctx.cgContext.translateBy(x: 0, y: rendererSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale) // Flip vertically and scale
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
        
        return image
    }
    
    // Generate thumbnail from PDF with correct orientation
    private func generateThumbnailFromPDF(data: Data) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: data),
              let page = pdfDocument.page(at: 0) else {
            print("Failed to create PDFDocument or get first page for thumbnail")
            return nil
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 1.0 // Thumbnail doesn't need high resolution
        let rendererSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: rendererSize)
        
        let thumbnail = renderer.image { ctx in
            ctx.cgContext.saveGState()
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: rendererSize))
            
            // Adjust for PDF coordinate system
            ctx.cgContext.translateBy(x: 0, y: rendererSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale) // Flip vertically
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
        
        print("Thumbnail generated with size: \(thumbnail.size)")
        return thumbnail
    }
    
    func updateUIWithExistingDocument() {
        // Safely handle selectedImages being nil or empty
        if let images = selectedImages, !images.isEmpty {
            thumbnailImageView.image = images[0]
        } else {
            // Fallback: Use existing thumbnail or leave blank if none
            if let thumbnailData = existingDocument?.thumbnail,
               let thumbnailImage = UIImage(data: thumbnailData) {
                thumbnailImageView.image = thumbnailImage
            } else {
                thumbnailImageView.image = nil // Or set a placeholder image
            }
        }
        
        summaryTableView?.reloadData()
        updateTableViewHeight()
        
        let categoryNames = selectedCategories.compactMap { $0.name }.joined(separator: ", ")
        categoryButton?.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
        
        if let expiryDate = existingDocument?.expiryDate {
            reminderSwitch?.isOn = true
            expiryDatePicker?.date = expiryDate
            expiryDatePicker?.isHidden = false
            expiryDateLabel?.isHidden = false
        } else {
            reminderSwitch?.isOn = false
            expiryDatePicker?.isHidden = true
            expiryDateLabel?.isHidden = true
        }
        
        UIView.animate(withDuration: 0.3) {
            self.expiryDatePicker?.alpha = self.reminderSwitch?.isOn ?? false ? 1.0 : 0.0
            self.expiryDateLabel?.alpha = self.reminderSwitch?.isOn ?? false ? 1.0 : 0.0
            self.updateReminderViewHeight()
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateUIWithExtractedData() {
        summaryTableView?.reloadData()
        let categoryNames = selectedCategories.compactMap { $0.name }.joined(separator: ", ")
        categoryButton?.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
        updateTableViewHeight()
        updateReminderViewHeight()
    }
    
    // MARK: - Helper Methods
    private func extractDocumentName(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        if let titleLine = lines.first(where: { $0.lowercased().contains("title:") || $0.lowercased().contains("document:") }) {
            return titleLine
                .replacingOccurrences(of: "title:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "document:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let documentTypes = ["invoice", "contract", "warranty", "receipt", "agreement", "policy", "certificate"]
        if let firstLine = lines.first {
            for docType in documentTypes {
                if firstLine.lowercased().contains(docType) {
                    return docType.capitalized
                }
            }
        }
        
        let fallback = lines.first ?? "Document \(Date().formatted(.dateTime.day().month().year()))"
        return String(fallback.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractKeyValuePairs(from text: String) -> [String: String] {
        let pattern = "([A-Za-z ]+):\\s*([^\\n]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        var pairs = [String: String]()
        
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            guard let match = regex?.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
                  let keyRange = Range(match.range(at: 1), in: line),
                  let valueRange = Range(match.range(at: 2), in: line) else { continue }
            
            let key = String(line[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = String(line[valueRange]).trimmingCharacters(in: .whitespaces)
            
            if !key.isEmpty && !value.isEmpty && key.count <= 30 && value.count <= 100 {
                pairs[key] = value
            }
        }
        
        return pairs
    }
    
    private func detectCategories(from text: String) -> [Category] {
        let lowerText = text.lowercased()
        var categoryScores: [String: Int] = [:]
        
        for (categoryName, keywords) in categoryKeywords {
            let matches = keywords.filter { lowerText.contains($0) }.count
            if matches > 0 {
                categoryScores[categoryName] = matches
            }
        }
        
        let threshold = 1
        let qualifyingCategories = categoryScores.filter { $0.value >= threshold }
        
        let allCategories = CoreDataManager.shared.fetchCategories()
        var selectedCategories = allCategories.filter { qualifyingCategories.keys.contains($0.name ?? "") }
        
        if selectedCategories.isEmpty {
            if let miscCategory = allCategories.first(where: { $0.name == "Miscellaneous" }) {
                return [miscCategory]
            }
        }
        
        selectedCategories.sort { (categoryScores[$0.name ?? ""] ?? 0) > (categoryScores[$1.name ?? ""] ?? 0) }
        return Array(selectedCategories.prefix(2))
    }
    
    private func setExpiryAndReminder(from text: String) {
        let dates = detectDates(in: text)
        print("Extracted Text for Date Detection: \(text)")
        print("Detected Dates: \(dates)")
        
        if let expiryDate = dates.last { // Use the last detected date as expiry
            print("Setting expiry date to: \(expiryDate)")
            reminderSwitch?.isOn = true
            expiryDatePicker?.date = expiryDate
            expiryDatePicker?.isHidden = false
            expiryDateLabel?.isHidden = false
        } else {
            print("No expiry date detected, turning switch off")
            reminderSwitch?.isOn = false
            expiryDatePicker?.isHidden = true
            expiryDateLabel?.isHidden = true
        }
        
        UIView.animate(withDuration: 0.3) {
            self.expiryDatePicker?.alpha = self.reminderSwitch?.isOn ?? false ? 1.0 : 0.0
            self.expiryDateLabel?.alpha = self.reminderSwitch?.isOn ?? false ? 1.0 : 0.0
            self.updateReminderViewHeight()
            self.view.layoutIfNeeded()
        }
    }
    
    private func detectDates(in text: String) -> [Date] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        var expiryDates: [Date] = [] // Dates associated with expiry keywords
        var allDates: [Date] = []   // All detected dates (for fallback)
        let now = Date()
        
        // Expanded list of expiry-related keywords
        let expiryKeywords = [
            "expiry", "expiration", "valid until", "due date", "expires on", "end date",
            "valid thru", "valid through", "expires", "due", "validity", "term ends",
            "renew by", "expiration date", "good until", "use by", "valid till", "valid until", "exp", "renewal"
        ]
        
        print("Searching for dates in text with \(expiryKeywords.count) keywords")
        
        detector?.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) { match, _, _ in
            guard let date = match?.date else {
                print("No date found in match")
                return
            }
            
            // Log all detected dates for debugging
            print("Found date: \(date) at range: \(match?.range ?? NSRange())")
            
            // Allow dates up to 30 days in the past
            let daysPastThreshold = -30
            guard let thresholdDate = Calendar.current.date(byAdding: .day, value: daysPastThreshold, to: now) else {
                print("Failed to calculate threshold date")
                return
            }
            if date < thresholdDate {
                print("Filtered out date \(date) as it's too far in the past")
                return
            }
            
            // Add to allDates regardless of keyword association
            allDates.append(date)
            
            // Check for expiry-related keywords in a wider context
            let range = match?.range ?? NSRange()
            let start = max(0, range.location - 100)
            let length = min(text.utf16.count - start, range.length + 200)
            let contextRange = NSRange(location: start, length: length)
            
            if let contextRangeInString = Range(contextRange, in: text) {
                let context = String(text[contextRangeInString]).lowercased()
                let hasExpiryKeyword = expiryKeywords.contains { context.contains($0) }
                
                print("Context for date \(date): \(context)")
                if hasExpiryKeyword {
                    print("Date \(date) is associated with an expiry keyword")
                    expiryDates.append(date)
                } else {
                    print("Date \(date) ignored for expiry, no expiry keyword found in context")
                }
            } else {
                print("Failed to extract context for date \(date)")
            }
        }
        
        // Decide which list to use
        let finalDates: [Date]
        if !expiryDates.isEmpty {
            // If we found dates with expiry keywords, use them and pick the last one
            finalDates = expiryDates.sorted()
            print("Using expiry keyword-associated dates: \(finalDates)")
        } else {
            // Fallback: Use all detected dates and pick the last future date
            let futureDates = allDates.filter { $0 > now }
            finalDates = futureDates.isEmpty ? allDates.sorted() : futureDates.sorted()
            print("No expiry keyword-associated dates found, falling back to: \(finalDates)")
        }
        
        print("Final detected dates: \(finalDates)")
        return finalDates
    }
    
    private func recognizeTextFrom(image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error)")
                completion("")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                completion("")
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            print("OCR Extracted Text: \(text)")
            completion(text)
        }
        
        // Enhanced OCR settings for date detection
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]
        request.customWords = [
            "expiry", "expiration", "valid until", "due date", "expires on", "end date",
            "valid thru", "valid through", "expires", "due", "validity", "term ends",
            "renew by", "expiration date", "good until", "use by",
            "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december",
            "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "oct", "nov", "dec"
        ]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error)")
            completion("")
        }
    }
    
    // MARK: - Save Document
    @IBAction func saveTapped(_ sender: UIButton) {
        guard !isReadOnly, validateInputs() else { return }
        
        let pdfDataToSave = pdfData ?? createPDFFromImages()
        let thumbnailData = thumbnailImageView.image?.jpegData(compressionQuality: 0.7)
        let summaryJSON = try? JSONSerialization.data(withJSONObject: summaryData)
        
        if isEditingExistingDocument, let document = existingDocument {
            document.name = nameTextField?.text ?? ""
            document.summaryData = summaryJSON
            document.expiryDate = reminderSwitch?.isOn == true ? expiryDatePicker?.date : nil
            document.thumbnail = thumbnailData
            document.pdfData = pdfDataToSave
            document.reminderDate = reminderSwitch?.isOn == true ? expiryDatePicker?.date : nil
            document.isFavorite = favoriteSwitch?.isOn ?? false
            document.categories = NSSet(array: selectedCategories)
            
            CoreDataManager.shared.saveContext()
            delegate?.didUpdateDocument()
        } else {
            let document = CoreDataManager.shared.createDocument(
                name: nameTextField?.text ?? "",
                summaryData: summaryJSON,
                expiryDate: reminderSwitch?.isOn == true ? expiryDatePicker?.date : nil,
                thumbnailData: thumbnailData,
                pdfData: pdfDataToSave,
                reminderDate: reminderSwitch?.isOn == true ? expiryDatePicker?.date : nil,
                isFavorite: favoriteSwitch?.isOn ?? false,
                categories: NSSet(array: selectedCategories),
                sharedWith: nil
            )
            
            CoreDataManager.shared.saveContext()
            delegate?.didUpdateDocument()
        }
        
        if let navController = self.navigationController {
            navController.dismiss(animated: true) {
                self.showSuccessNotification()
            }
        } else {
            dismiss(animated: true) {
                self.showSuccessNotification()
            }
        }
    }
    
    private func validateInputs() -> Bool {
        guard let name = nameTextField?.text, !name.isEmpty else {
            showAlert(title: "Missing Name", message: "Please enter a document name")
            return false
        }
        
        guard selectedImages != nil || pdfData != nil else {
            showAlert(title: "No Content", message: "Please select at least one image or a PDF")
            return false
        }
        
        if (reminderSwitch?.isOn ?? false) && (expiryDatePicker?.date ?? Date()) < Date() {
            showAlert(title: "Invalid Date", message: "Expiry date must be in the future")
            return false
        }
        
        return true
    }
    
    private func createPDFFromImages() -> Data? {
        guard let images = selectedImages, !images.isEmpty else { return nil }
        
        let pdfData = NSMutableData()
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        UIGraphicsBeginPDFContextToData(pdfData, bounds, nil)
        for image in images {
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
    
    private func showSuccessNotification() {
        var targetViewController: UIViewController? = presentingViewController
        while let navController = targetViewController as? UINavigationController {
            targetViewController = navController.viewControllers.first
        }
        
        if targetViewController == nil, let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            targetViewController = rootVC
        }
        
        guard let targetVC = targetViewController else { return }
        
        let safeAreaTopInset = targetVC.view.safeAreaInsets.top
        let notificationHeight: CGFloat = 60
        let startYPosition = -notificationHeight
        let finalYPosition = safeAreaTopInset
        
        let notificationView = UIView(frame: CGRect(x: 0, y: startYPosition, width: targetVC.view.bounds.width, height: notificationHeight))
        notificationView.backgroundColor = #colorLiteral(red: 0.09803921569, green: 0.7764705882, blue: 0.3450980392, alpha: 0.804816846)
        
        let checkmarkImage = UIImage(systemName: "checkmark.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let checkmarkView = UIImageView(image: checkmarkImage)
        checkmarkView.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        notificationView.addSubview(checkmarkView)
        
        let messageLabel = UILabel(frame: CGRect(x: 60, y: 10, width: notificationView.bounds.width - 70, height: 40))
        messageLabel.text = isEditingExistingDocument ? "File updated successfully!" : "File added successfully!"
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        notificationView.addSubview(messageLabel)
        
        targetVC.view.addSubview(notificationView)
        
        UIView.animate(withDuration: 0.3, animations: {
            notificationView.frame.origin.y = finalYPosition
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                UIView.animate(withDuration: 0.3, animations: {
                    notificationView.alpha = 0
                    notificationView.frame.origin.y = startYPosition
                }) { _ in
                    notificationView.removeFromSuperview()
                }
            }
        }
    }
    
    @objc func cancelTapped() {
        if let navController = self.navigationController {
            navController.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
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
            cell.KeyTextField.isEnabled = !isReadOnly
            cell.ValueTextField.isEnabled = !isReadOnly
        }
        
        return cell
    }
    
    // MARK: - KeyValueCellDelegate
    func didUpdateKeyValue(key: String?, value: String?, at index: Int) {
        guard !isReadOnly, let key = key, !key.isEmpty, let value = value, !value.isEmpty else { return }
        if index < summaryData.count {
            let oldKey = Array(summaryData.keys)[index]
            summaryData.removeValue(forKey: oldKey)
        }
        summaryData[key] = value
        summaryTableView?.reloadData()
        updateTableViewHeight()
    }
    
    // MARK: - Category Selection
    @IBAction func selectCategoryTapped(_ sender: UIButton?) {
        guard !isReadOnly else { return }
        let categories = CoreDataManager.shared.fetchCategories()
        let categoryVC = CategorySelectionViewController(categories: categories, selectedCategories: selectedCategories)
        categoryVC.delegate = self
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
    }
    
    // MARK: - Read-Only Mode Configuration
    private func configureReadOnlyMode() {
        nameTextField?.isEnabled = false
        nameTextField?.isUserInteractionEnabled = false
        reminderSwitch?.isEnabled = false
        reminderSwitch?.isUserInteractionEnabled = false
        favoriteSwitch?.isEnabled = false
        favoriteSwitch?.isUserInteractionEnabled = false
        categoryButton?.isEnabled = false
        categoryButton?.isUserInteractionEnabled = false
        expiryDatePicker?.isUserInteractionEnabled = false
        saveButton?.isHidden = true
        if let heightConstraint = saveButton?.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = 0
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        summaryTableView?.reloadData()
    }
}

// MARK: - CategorySelectionDelegate
extension AddDocumentViewController: CategorySelectionDelegate {
    func didSelectCategories(_ categories: [Category]) {
        guard !isReadOnly else { return }
        selectedCategories = categories
        let categoryNames = categories.compactMap { $0.name }.joined(separator: ", ")
        categoryButton?.setTitle(categoryNames.isEmpty ? "Select Categories" : categoryNames, for: .normal)
    }
}

// MARK: - QLPreviewControllerDataSource & Delegate
extension AddDocumentViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let pdfData = pdfData ?? createPDFFromImages() else {
            fatalError("PDF data is unexpectedly nil after validation.")
        }
        
        // Use the document name for the file, falling back to "Document" if nil
        let documentName = (nameTextField?.text ?? existingDocument?.name ?? "Document").replacingOccurrences(of: "/", with: "_") // Avoid invalid characters
        let fileName = "\(documentName).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        let documentName = (nameTextField?.text ?? existingDocument?.name ?? "Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        if let url = try? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
