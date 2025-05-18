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

class sharedVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var receiveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var BGView: UIView!
    
    // MARK: - Multipeer Properties
    var peerID: MCPeerID!
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browserVC: MCBrowserViewController?
    var isAdvertising: Bool = false


    // MARK: - PDF Data to Send
    var pdfDataToSend: Data?

    // MARK: - Core Data / Received Files
    var receivedFiles: [Share] = []

    // MARK: - Location Manager
    var locationManager: CLLocationManager!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up navigation bar with large title
        navigationItem.title = "Shared"
        navigationController?.navigationBar.prefersLargeTitles = true

        setupMultipeer()
        setupUI()
        fetchReceivedFiles()
        setupLocationPermissions()
        applyBlurGradient() // Added blur gradient
        
        // UI Misc.
        BGView.layer.cornerRadius = 25
        BGView.layer.shadowColor = UIColor.black.cgColor
        BGView.layer.shadowOpacity = 0.5
        BGView.layer.shadowOffset = .zero
        BGView.layer.shadowRadius = 5.0
        BGView.layer.masksToBounds = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure default large title appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Adjust color as needed
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white] // Adjust color as needed
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white // Adjust tint as needed
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

        styleButtons()
    }

    private func styleButtons() {
        let buttons = [sendButton, receiveButton]

        buttons.forEach { button in
            button?.layer.shadowColor = UIColor.black.cgColor
            button?.layer.shadowOffset = CGSize(width: 0, height: 2)
            button?.layer.shadowOpacity = 0.3
            button?.layer.shadowRadius = 4
        }
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
        guard pdfDataToSend != nil else {
            print("⚠️ No file selected to send.")
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

            let context = CoreDataManager.shared.context
            let newShare = Share(context: context)
            newShare.userId = peerID.displayName
            newShare.fileName = "Received_\(Date().description).pdf"
            newShare.fileData = data

            CoreDataManager.shared.saveContext()
            self.fetchReceivedFiles()
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
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
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
            pdfDataToSend = data
            presentBrowserToSend()
        } catch {
            print("❌ Error loading document: \(error.localizedDescription)")
        }
    }
}

// MARK: - IBActions
extension sharedVC {
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        print("📤 Send tapped.")

        let alert = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Pick from Files", style: .default, handler: { _ in
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.modalPresentationStyle = .formSheet
            self.present(documentPicker, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Pick from Saved Files", style: .default, handler: { _ in
            self.pickFromSavedFiles()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    @IBAction func receiveButtonTapped(_ sender: UIButton) {
        guard !isAdvertising else {
            print("⚠️ Already advertising.")
            return
        }

        print("📥 Receive tapped.")

        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "fyleshare123")
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        isAdvertising = true
        print("🚀 Advertiser started.")

        let alert = UIAlertController(title: "Receiving Mode", message: "Waiting for sender...", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stop", style: .cancel, handler: { _ in
            self.advertiser?.stopAdvertisingPeer()
            self.advertiser = nil
            self.isAdvertising = false
            print("🛑 Advertiser stopped.")
        }))

        present(alert, animated: true)
    }

}

// MARK: - Pick from Saved Files
extension sharedVC {
    func pickFromSavedFiles() {
        let alert = UIAlertController(title: "Select a file", message: nil, preferredStyle: .actionSheet)

        for file in receivedFiles {
            alert.addAction(UIAlertAction(title: file.fileName ?? "Unknown", style: .default, handler: { _ in
                if let fileData = file.fileData {
                    self.pdfDataToSend = fileData
                    self.presentBrowserToSend()
                } else {
                    print("⚠️ No data in selected file.")
                }
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Fetch Core Data & Table View
extension sharedVC: UITableViewDelegate, UITableViewDataSource {
    func fetchReceivedFiles() {
        let fetchRequest: NSFetchRequest<Share> = Share.fetchRequest()

        do {
            receivedFiles = try CoreDataManager.shared.context.fetch(fetchRequest)
            tableView.reloadData()
        } catch {
            print("❌ Failed to fetch received files: \(error.localizedDescription)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        receivedFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "CustomCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            cell?.layer.cornerRadius = 8
            cell?.layer.masksToBounds = true
        }

        let file = receivedFiles[indexPath.row]
        cell?.textLabel?.text = file.fileName ?? "No Name"
        cell?.detailTextLabel?.text = "From: \(file.userId ?? "Unknown")"

        // Add spacing between cells
        cell?.contentView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}

