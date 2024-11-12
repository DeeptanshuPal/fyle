//
//  HomeViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit
import UniformTypeIdentifiers

class HomeViewController: GradientBGViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    @IBOutlet weak var FilesTileView: UIView!
    @IBOutlet weak var FilesTileImageView: UIView!
    @IBOutlet weak var RemindersTileView: UIView!
    @IBOutlet weak var RemindersTileImageView: UIView!
    @IBOutlet weak var CategoriesTileView: UIView!
    @IBOutlet weak var CategoriesTileImageView: UIView!
    @IBOutlet weak var SharedTileView: UIView!
    @IBOutlet weak var SharedTileImageView: UIView!
    @IBOutlet weak var FavouritesImageView: UIView!
    @IBOutlet weak var AddButtonView: UIView!
    
    var selectedImages: [UIImage] = []

    @IBAction func addBoxTapped(_ sender: UITapGestureRecognizer) {
        showAddOptions()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set corner radii for UI elements
        FilesTileView.layer.cornerRadius = 11
        FilesTileImageView.layer.cornerRadius = 20
        RemindersTileView.layer.cornerRadius = 11
        RemindersTileImageView.layer.cornerRadius = 20
        CategoriesTileView.layer.cornerRadius = 11
        CategoriesTileImageView.layer.cornerRadius = 20
        SharedTileView.layer.cornerRadius = 11
        SharedTileImageView.layer.cornerRadius = 20
        FavouritesImageView.layer.cornerRadius = 20
        
        AddButtonView.layer.cornerRadius = 75/2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
    }
    
    // Show options for adding a new file
    func showAddOptions() {
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
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Camera Access and Image Capture
    func openCameraForScan() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Photo Library Access
    func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("Photo Library not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - File Picker Access
    func openFiles() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            // Add the selected or captured image to the selectedImages array
            selectedImages.append(image)
            print("Image captured or selected: \(image)")
            
            // Once an image is selected, convert all selected images to a PDF
            saveSelectedImagesAsPDF()
        }
        picker.dismiss(animated: true, completion: nil)
    }

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - UIDocumentPickerDelegate Methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        // Handle the selected file URL (save, upload, etc.)
        print("Selected file URL: \(selectedFileURL)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // Save the selected images as a PDF
    func saveSelectedImagesAsPDF() {
        // Ensure there are images to save as a PDF
        if selectedImages.isEmpty {
            print("No images selected to convert to PDF.")
            return
        }
        
        // Call the PDFHelper to save the images as a PDF
        if let pdfURL = PDFHelper.saveImagesAsPDF(images: selectedImages, pdfName: "ScannedDocument") {
            print("PDF saved at: \(pdfURL)")
            
            // Optionally, share or display the PDF to the user
            // You can use the `pdfURL` for further processing, such as opening or sharing the PDF.
            sharePDF(pdfURL: pdfURL)
        } else {
            print("Failed to create PDF.")
        }
    }

    // Share the generated PDF
    func sharePDF(pdfURL: URL) {
        let activityController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }
}
