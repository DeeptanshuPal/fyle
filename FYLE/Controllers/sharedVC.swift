//
//  sharedVC.swift
//  FYLE
//
//  Created by admin41 on 12/03/25.
//

import UIKit
import MultipeerConnectivity
import CoreData
import UniformTypeIdentifiers
import CoreLocation
import QuickLook
import PDFKit

class sharedVC: UIViewController, ShareDocumentPickerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, AddDocumentViewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet var SendButton: UITapGestureRecognizer!
    @IBOutlet var receiveButton: UITapGestureRecognizer!
    @IBOutlet weak var sendImageView: UIImageView!
    @IBOutlet weak var receiveImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var BGView: UIView!
    @IBOutlet weak var BGView2: UIView!
    @IBOutlet weak var BGView3: UIView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyTrayImageView: UIImageView!
    @IBOutlet weak var emptyTrayLabel: UILabel!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var sendOverlay: UIView!
    private var receiveOverlay: UIView!
    
    // MARK: - Multipeer Properties
    var peerID: MCPeerID!
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browserVC: MCBrowserViewController?
    var isAdvertising: Bool = false
    
    // MARK: - Data to Send
    var dataToSend: Data?
    
    // MARK: - Core Data / Received Files
    var receivedFiles: [Document] = []
    
    // MARK: - Location Manager
    var locationManager: CLLocationManager!
    
    // MARK: - Selected Document for Preview
    private var selectedDocument: Document?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Shared"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupMultipeer()
        setupUI()
        fetchReceivedFiles()
        setupLocationPermissions()
        applyBlurGradient()
        updateEmptyStateVisibility()
        
        BGView.layer.cornerRadius = 361/2
        BGView.layer.shadowColor = UIColor.white.cgColor
        BGView.layer.shadowOpacity = 0.5
        BGView.layer.shadowOffset = .zero
        BGView.layer.shadowRadius = 5.0
        BGView.layer.masksToBounds = false
        
        BGView2.layer.cornerRadius = 310/2
        BGView2.layer.shadowColor = UIColor.white.cgColor
        BGView2.layer.shadowOpacity = 0.5
        BGView2.layer.shadowOffset = .zero
        BGView2.layer.shadowRadius = 5.0
        BGView2.layer.masksToBounds = false
        
        BGView3.layer.cornerRadius = 250/2
        BGView3.layer.shadowColor = UIColor.white.cgColor
        BGView3.layer.shadowOpacity = 0.5
        BGView3.layer.shadowOffset = .zero
        BGView3.layer.shadowRadius = 5.0
        BGView3.layer.masksToBounds = false
        
        emptyStateView.layer.cornerRadius = 20
        emptyStateView.layer.shadowColor = UIColor.black.cgColor
        emptyStateView.layer.shadowOpacity = 0.5
        emptyStateView.layer.shadowOffset = .zero
        emptyStateView.layer.shadowRadius = 2.0
        emptyStateView.layer.masksToBounds = false
        
        tableView.layer.cornerRadius = 11
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        
        // Setup send image view
        if let sendImageView = sendImageView {
            sendImageView.isUserInteractionEnabled = true
            if SendButton.view != sendImageView {
                sendImageView.addGestureRecognizer(SendButton)
            }
            SendButton.isEnabled = true
            SendButton.addTarget(self, action: #selector(sendTapped(_:)))
            sendImageView.layer.shadowColor = UIColor.white.cgColor
            sendImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
            sendImageView.layer.shadowOpacity = 0.8
            sendImageView.layer.shadowRadius = 4
            sendImageView.layer.masksToBounds = false
            print("✅ SendButton attached to sendImageView: \(sendImageView)")
            
            // Add overlay with mask
            sendOverlay = UIView(frame: sendImageView.bounds)
            sendOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            sendOverlay.isUserInteractionEnabled = false
            sendOverlay.alpha = 0
            sendOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            sendImageView.addSubview(sendOverlay)
            
            if let image = sendImageView.image {
                let maskLayer = CALayer()
                maskLayer.contents = image.cgImage
                maskLayer.frame = imageRect(in: sendImageView)
                sendOverlay.layer.mask = maskLayer
            }
        }
        
        // Setup receive image view
        if let receiveImageView = receiveImageView {
            receiveImageView.isUserInteractionEnabled = true
            if receiveButton.view != receiveImageView {
                receiveImageView.addGestureRecognizer(receiveButton)
            }
            receiveButton.isEnabled = true
            receiveButton.addTarget(self, action: #selector(receiveTapped(_:)))
            receiveImageView.layer.shadowColor = UIColor.white.cgColor
            receiveImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
            receiveImageView.layer.shadowOpacity = 0.8
            receiveImageView.layer.shadowRadius = 4
            receiveImageView.layer.masksToBounds = false
            print("✅ receiveButton attached to receiveImageView: \(receiveImageView)")
            
            // Add overlay with mask
            receiveOverlay = UIView(frame: receiveImageView.bounds)
            receiveOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            receiveOverlay.isUserInteractionEnabled = false
            receiveOverlay.alpha = 0
            receiveOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            receiveImageView.addSubview(receiveOverlay)
            
            if let image = receiveImageView.image {
                let maskLayer = CALayer()
                maskLayer.contents = image.cgImage
                maskLayer.frame = imageRect(in: receiveImageView)
                receiveOverlay.layer.mask = maskLayer
            }
        }
    }
    
    // MARK: Helper Function
    private func imageRect(in imageView: UIImageView) -> CGRect {
        guard let image = imageView.image else { return .zero }
        let viewSize = imageView.bounds.size
        let imageSize = image.size

        switch imageView.contentMode {
        case .scaleAspectFit:
            let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            let x = (viewSize.width - width) / 2
            let y = (viewSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        case .scaleAspectFill:
            let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            let x = (viewSize.width - width) / 2
            let y = (viewSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        case .scaleToFill, .redraw:
            return imageView.bounds
        default:
            return imageView.bounds // Fallback for center, top, etc.
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableViewHeight()
    }
}

// MARK: - CLLocationManagerDelegate
extension sharedVC: CLLocationManagerDelegate {
    func setupLocationPermissions() {
        locationManager = CLLocationManager()
        locationManager.delegate = self

        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied: print("❌ Location access denied/restricted.")
        case .authorizedWhenInUse, .authorizedAlways: print("✅ Location access granted.")
        @unknown default: print("❓ Unknown location authorization status.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: print("✅ Location permission granted.")
        case .denied, .restricted: print("❌ Location permission denied.")
        case .notDetermined: print("⚠️ Location permission not determined.")
        @unknown default: print("❓ Unknown location permission status.")
        }
    }
}

// MARK: - Multipeer Setup & UI
extension sharedVC {
    func setupMultipeer() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false // Disable scrolling for dynamic height
    }

    func applyBlurGradient() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)

        blurView.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.9).cgColor,
            UIColor(white: 1.0, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)

        let maskLayer = CALayer()
        maskLayer.frame = blurView.bounds
        maskLayer.addSublayer(gradientLayer)
        blurView.layer.mask = maskLayer

        view.addSubview(blurView)
    }

    func presentBrowserToSend() {
        guard let dataToSend = self.dataToSend else {
            print("⚠️ No data to send. dataToSend is nil.")
            return
        }
        browserVC = MCBrowserViewController(serviceType: "fyleshare123", session: session)
        browserVC?.delegate = self
        present(browserVC!, animated: true)
    }
}

// MARK: - MCSessionDelegate
extension sharedVC: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected: print("✅ Connected to \(peerID.displayName)")
            case .connecting: print("🔄 Connecting to \(peerID.displayName)")
            case .notConnected: print("❌ Disconnected from \(peerID.displayName)")
            @unknown default: print("❓ Unknown session state.")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print("📥 Data received from \(peerID.displayName)")

            do {
                let sharedDoc = try JSONDecoder().decode(SharedDocument.self, from: data)
                let context = CoreDataManager.shared.context
                let newDocument = Document(context: context)
                newDocument.name = sharedDoc.name
                newDocument.pdfData = sharedDoc.pdfData
                newDocument.summaryData = sharedDoc.summaryData
                newDocument.expiryDate = sharedDoc.expiryDate
                newDocument.reminderDate = sharedDoc.reminderDate
                newDocument.isFavorite = sharedDoc.isFavorite
                newDocument.dateAdded = sharedDoc.dateAdded
                newDocument.thumbnail = sharedDoc.thumbnail
                newDocument.isReceived = true

                if !sharedDoc.categoryNames.isEmpty {
                    let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name IN %@", sharedDoc.categoryNames)
                    var existingCategories = try context.fetch(fetchRequest)
                    let existingNames = Set(existingCategories.map { $0.name ?? "" })
                    let newCategories = sharedDoc.categoryNames.filter { !existingNames.contains($0) }
                    for categoryName in newCategories {
                        let newCategory = CoreDataManager.shared.createCategory(name: categoryName, image: "tray.full.fill", color: .gray)
                        existingCategories.append(newCategory)
                    }
                    newDocument.addToCategories(NSSet(array: existingCategories))
                }

                try CoreDataManager.shared.saveContext()
                self.fetchReceivedFiles()
                self.updateEmptyStateVisibility()
            } catch {
                print("❌ Error decoding received data: \(error)")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension sharedVC: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Invitation received from \(peerID.displayName)")
        invitationHandler(true, session)
    }
}

// MARK: - MCBrowserViewControllerDelegate
extension sharedVC: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        dismiss(animated: false) {
            if let data = self.dataToSend, !self.session.connectedPeers.isEmpty {
                do {
                    try self.session.send(data, toPeers: self.session.connectedPeers, with: .reliable)
                    print("✅ File sent successfully.")
                    let alert = UIAlertController(title: "Success", message: "File sent successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    self.dataToSend = nil
                } catch {
                    print("❌ Error sending file: \(error.localizedDescription)")
                    let alert = UIAlertController(title: "Error", message: "Failed to send file.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } else {
                print("⚠️ No data or peers to send to.")
                let alert = UIAlertController(title: "Error", message: "No peers connected.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        dismiss(animated: false)
        dataToSend = nil
    }
}

// MARK: - UIDocumentPickerDelegate
extension sharedVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("⚠️ No document selected.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let sharedDoc = SharedDocument(
                name: url.lastPathComponent,
                pdfData: data,
                summaryData: nil,
                expiryDate: nil,
                reminderDate: nil,
                isFavorite: false,
                dateAdded: Date(),
                thumbnail: nil,
                categoryNames: []
            )
            self.dataToSend = try JSONEncoder().encode(sharedDoc)
            presentBrowserToSend()
        } catch {
            print("❌ Error loading document: \(error.localizedDescription)")
        }
    }
}

// MARK: - IBActions
extension sharedVC {
    @objc func sendTapped(_ sender: UITapGestureRecognizer) {
        sendOverlay.alpha = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.3) {
                self.sendOverlay.alpha = 0
            }
        }
        print("📤 Send tapped")
        
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        
        let alert = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Pick from My Documents", style: .default, handler: { [weak self] _ in
            self?.presentDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Pick from Device Files", style: .default, handler: { [weak self] _ in
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.modalPresentationStyle = .formSheet
            self?.present(documentPicker, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func receiveTapped(_ sender: UITapGestureRecognizer) {
        receiveOverlay.alpha = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.3) {
                self.receiveOverlay.alpha = 0
            }
        }
        
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        
        guard !isAdvertising else {
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            isAdvertising = false
            print("🛑 Advertiser stopped.")
            return
        }
        
        print("📥 Receive tapped")
        
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "fyleshare123")
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        print("🚀 Advertiser started.")
        
        let alert = UIAlertController(title: "Receiving Mode", message: "Waiting for sender...", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stop", style: .cancel, handler: { [weak self] _ in
            self?.advertiser?.stopAdvertisingPeer()
            self?.advertiser = nil
            self?.isAdvertising = false
            print("🛑 Advertiser stopped.")
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Document Picker Presentation
extension sharedVC {
    private func presentDocumentPicker() {
        guard let pickerVC = storyboard?.instantiateViewController(withIdentifier: "ShareDocumentPickerViewController") as? ShareDocumentPickerViewController else {
            print("❌ Failed to instantiate ShareDocumentPickerViewController from storyboard.")
            return
        }
        
        pickerVC.delegate = self
        let navController = UINavigationController(rootViewController: pickerVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }
    
    func didSelectDocument(_ document: Document) {
        print("✅ Document selected: \(document.name ?? "Unnamed")")
        let sharedDoc = document.toSharedDocument()
        do {
            self.dataToSend = try JSONEncoder().encode(sharedDoc)
            print("✅ Data encoded successfully, presenting browser")
            DispatchQueue.main.async {
                self.presentBrowserToSend()
            }
        } catch {
            print("❌ Error encoding document: \(error.localizedDescription)")
        }
    }
}

// MARK: - Fetch Core Data & Table View
extension sharedVC: UITableViewDelegate, UITableViewDataSource {
    func fetchReceivedFiles() {
        receivedFiles = CoreDataManager.shared.fetchReceivedDocuments()
        tableView.reloadData()
        updateEmptyStateVisibility()
        updateTableViewHeight()
    }
    
    private func updateEmptyStateVisibility() {
        emptyStateView.isHidden = !receivedFiles.isEmpty
        emptyTrayLabel.isHidden = !receivedFiles.isEmpty
        emptyTrayImageView.isHidden = !receivedFiles.isEmpty
        tableView.isHidden = receivedFiles.isEmpty
    }

    private func updateTableViewHeight() {
        let rowHeight: CGFloat = 50
        let totalHeight = min(CGFloat(receivedFiles.count) * rowHeight, 400)
        tableViewHeightConstraint.constant = totalHeight
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return receivedFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CustomCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.backgroundColor = UIColor.white
            cell?.layer.masksToBounds = true
        }

        let document = receivedFiles[indexPath.row]
        cell?.textLabel?.text = document.name ?? "No Name"
        
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        button.tintColor = .systemGray4
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.addTarget(self, action: #selector(disclosureTapped(_:)), for: .touchUpInside)
        cell?.accessoryView = button
        
        cell?.selectionStyle = .default
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDocument = receivedFiles[indexPath.row]
        presentPDFViewer()
    }

    @objc func disclosureTapped(_ sender: UIButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else {
            print("Error: Could not determine cell or indexPath from disclosure tap.")
            return
        }
        let document = receivedFiles[indexPath.row]
        showDetails(for: document)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let document = receivedFiles[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let openFileAction = UIAction(title: "Open File", image: UIImage(systemName: "doc.text.viewfinder")) { [weak self] _ in
                guard let self = self else { return }
                self.selectedDocument = document
                self.presentPDFViewer()
            }
            
            let showDetailsAction = UIAction(title: "Show Details", image: UIImage(systemName: "info.circle")) { [weak self] _ in
                self?.showDetails(for: document)
            }
            
            let favoriteAction = UIAction(
                title: document.isFavorite ? "Unmark as Favourite" : "Mark as Favourite",
                image: UIImage(systemName: document.isFavorite ? "heart.fill" : "heart")
            ) { [weak self] _ in
                guard let self = self else { return }
                document.isFavorite.toggle()
                CoreDataManager.shared.saveContext()
                self.tableView.reloadData()
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.confirmDelete(document: document, at: indexPath)
            }
            
            let sendCopyAction = UIAction(title: "Send a Copy", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                guard let self = self else { return }
                self.shareDocument(document)
            }
            
            return UIMenu(title: "", children: [openFileAction, showDetailsAction, favoriteAction, deleteAction, sendCopyAction])
        }
    }
}

// MARK: - PDF Viewer
extension sharedVC {
    private func presentPDFViewer() {
        guard let document = selectedDocument, let pdfData = document.pdfData else {
            showAlert(title: "Error", message: "No PDF data available for this document.")
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        previewController.navigationItem.title = document.name ?? "Document"
        
        previewController.modalPresentationStyle = .fullScreen
        present(previewController, animated: true, completion: nil)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let document = selectedDocument, let pdfData = document.pdfData else {
            fatalError("PDF data is unexpectedly nil.")
        }
        let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
        let fileName = "\(documentName).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        try? pdfData.write(to: url)
        return url as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if let document = selectedDocument {
            let documentName = (document.name ?? "Unnamed Document").replacingOccurrences(of: "/", with: "_")
            let fileName = "\(documentName).pdf"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Context Menu Actions
extension sharedVC {
    private func showDetails(for document: Document) {
        guard let addDocumentVC = storyboard?.instantiateViewController(withIdentifier: "AddDocumentViewController") as? AddDocumentViewController else {
            print("Error: Could not instantiate AddDocumentViewController from storyboard.")
            return
        }
        
        addDocumentVC.delegate = self
        addDocumentVC.isEditingExistingDocument = true
        addDocumentVC.isReadOnly = true
        addDocumentVC.existingDocument = document
        
        addDocumentVC.loadViewIfNeeded()
        
        print("favoriteSwitch after load: \(String(describing: addDocumentVC.favoriteSwitch))")
        print("nameTextField after load: \(String(describing: addDocumentVC.nameTextField))")
        print("summaryTableView after load: \(String(describing: addDocumentVC.summaryTableView))")
        print("thumbnailImageView after load: \(String(describing: addDocumentVC.thumbnailImageView))")
        print("categoryButton after load: \(String(describing: addDocumentVC.categoryButton))")
        print("reminderSwitch after load: \(String(describing: addDocumentVC.reminderSwitch))")
        print("expiryDatePicker after load: \(String(describing: addDocumentVC.expiryDatePicker))")
        print("expiryDateLabel after load: \(String(describing: addDocumentVC.expiryDateLabel))")
        
        addDocumentVC.selectedImages = loadImagesFromDocument(document)
        addDocumentVC.summaryData = loadSummaryData(from: document)
        addDocumentVC.selectedCategories = document.categories?.allObjects as? [Category] ?? []
        
        if let favoriteSwitch = addDocumentVC.favoriteSwitch {
            favoriteSwitch.isOn = document.isFavorite
        } else {
            print("Warning: favoriteSwitch is nil, cannot set favorite status.")
        }
        
        addDocumentVC.nameTextField?.text = document.name
        
        if let expiryDate = document.expiryDate {
            addDocumentVC.reminderSwitch?.isOn = true
            addDocumentVC.expiryDatePicker?.date = expiryDate
            addDocumentVC.expiryDatePicker?.isHidden = false
            addDocumentVC.expiryDateLabel?.isHidden = false
        } else {
            addDocumentVC.reminderSwitch?.isOn = false
            addDocumentVC.expiryDatePicker?.isHidden = true
            addDocumentVC.expiryDateLabel?.isHidden = true
        }
        
        addDocumentVC.updateUIWithExistingDocument()
        
        let navController = UINavigationController(rootViewController: addDocumentVC)
        present(navController, animated: true, completion: nil)
    }
    
    private func loadImagesFromDocument(_ document: Document) -> [UIImage] {
        guard let pdfData = document.pdfData, let pdfDocument = PDFDocument(data: pdfData) else {
            return []
        }
        
        var images: [UIImage] = []
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                let pageBounds = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
                let image = renderer.image { context in
                    UIColor.white.setFill()
                    context.fill(pageBounds)
                    context.cgContext.translateBy(x: 0, y: pageBounds.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                images.append(image)
            }
        }
        return images
    }
    
    private func loadSummaryData(from document: Document) -> [String: String] {
        guard let summaryData = document.summaryData,
              let json = try? JSONSerialization.jsonObject(with: summaryData, options: []) as? [String: String] else {
            return [:]
        }
        return json
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
            self.receivedFiles.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateTableViewHeight()
            self.updateEmptyStateVisibility()
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

// MARK: - AddDocumentViewControllerDelegate
extension sharedVC {
    func didUpdateDocument() {
        fetchReceivedFiles()
        tableView.reloadData()
        updateTableViewHeight()
        updateEmptyStateVisibility()
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.removeFirst()
        }

        if cString.count != 6 {
            self.init(white: 0.5, alpha: 1.0)
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
