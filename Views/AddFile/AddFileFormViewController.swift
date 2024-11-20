//
//  AddFileFormViewController.swift
//  fyle
//
//  Created by User@77 on 13/11/24.
//

import UIKit

protocol AddFileFormDelegate: AnyObject {
    func didSaveFileDetails(name: String, reminder: Date?, summary: String, isConfidential: Bool)
}

class AddFileFormViewController: UIViewController {
    @IBOutlet weak var fileThumbnailImageView: UIImageView!
    @IBOutlet weak var fileNameTextField: UITextField!
    @IBOutlet weak var reminderDate: UIDatePicker!
    @IBOutlet weak var CategoriesSelect: UIButton!
    @IBOutlet weak var summaryTextView: UITextView!
    @IBOutlet weak var confidentialSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: AddFileFormDelegate?
    
    // Properties to hold the selected file data
    var fileThumbnail: UIImage?
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        reminderDate.datePickerMode = .date // If you just need a date picker without time
        
        // Set the thumbnail image if available
        if let image = fileThumbnail {
            fileThumbnailImageView.image = image
        } else if let url = fileURL {
            fileThumbnailImageView.image = generateThumbnail(for: url)
        }
    }
    
    // Function to generate a thumbnail for a file URL (PDFs or other supported file types)
    private func generateThumbnail(for url: URL) -> UIImage? {
        if url.pathExtension.lowercased() == "pdf" {
            return generatePDFThumbnail(for: url)
        } else if url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" {
            return generateImageThumbnail(for: url)
        }
        return nil
    }

    private func generatePDFThumbnail(for url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL), let page = document.page(at: 1) else { return nil }
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            ctx.cgContext.drawPDFPage(page)
        }
        return img
    }

    private func generateImageThumbnail(for url: URL) -> UIImage? {
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return nil
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let fileName = fileNameTextField.text, !fileName.isEmpty else {
            let alert = UIAlertController(title: "Missing Information", message: "Please enter a file name.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            fileNameTextField.becomeFirstResponder()  // Focus on file name field
            return
        }
        
        // Collect user input data
        let reminderDate = reminderDate.date
        let summary = summaryTextView.text ?? ""
        let isConfidential = confidentialSwitch.isOn
        
        // Pass data back via delegate
        guard let delegate = delegate else { return }
        delegate.didSaveFileDetails(name: fileName, reminder: reminderDate, summary: summary, isConfidential: isConfidential)
        
        // Dismiss the modal
        dismiss(animated: true, completion: nil)
    }
}
