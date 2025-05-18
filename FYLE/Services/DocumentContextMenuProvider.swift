//
//  DocumentContextMenuProvider.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 12/03/25.
//

import UIKit
import CoreData
import PDFKit

protocol DocumentContextMenuProvider: UITableViewDelegate {
    var documents: [Document] { get set }
    var filteredDocuments: [Document] { get set }
    var filesTableView: UITableView? { get }
    
    func fetchDocuments()
    func updateTableViewHeight()
    func showDetails(for document: Document)
}

extension DocumentContextMenuProvider where Self: UIViewController {
    // MARK: - Context Menu Configuration
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < filteredDocuments.count else { return nil }
        let document = filteredDocuments[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let showDetailsAction = UIAction(title: "Show Details", image: UIImage(systemName: "info.circle")) { [weak self] _ in
                self?.showDetails(for: document)
            }
            
            let favoriteAction = UIAction(
                title: document.isFavorite ? "Unmark as Favourite" : "Mark as Favourite",
                image: UIImage(systemName: document.isFavorite ? "star.fill" : "star")
            ) { [weak self] _ in
                self?.toggleFavoriteStatus(for: document)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmDelete(document: document, at: indexPath)
            }
            
            let sendCopyAction = UIAction(title: "Send a Copy", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareDocument(document)
            }
            
            return UIMenu(title: "", children: [showDetailsAction, favoriteAction, deleteAction, sendCopyAction])
        }
    }
    
    // MARK: - Helper Methods
    private func toggleFavoriteStatus(for document: Document) {
        document.isFavorite.toggle()
        CoreDataManager.shared.saveContext()
        filesTableView?.reloadData()
    }
    
    private func confirmDelete(document: Document, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Document",
            message: "Are you sure you want to delete \"\(document.name ?? "Unnamed Document")\"? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            CoreDataManager.shared.deleteDocument(document)
            self.documents.removeAll { $0 == document }
            self.filteredDocuments.removeAll { $0 == document }
            self.filesTableView?.deleteRows(at: [indexPath], with: .automatic)
            self.updateTableViewHeight()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func shareDocument(_ document: Document) {
        guard let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available to share.")
            return
        }
        
        let fileName = (document.name ?? "Unnamed Document") + ".pdf"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            present(activityViewController, animated: true) {
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            showAlert(title: "Error", message: "Failed to prepare document for sharing: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
