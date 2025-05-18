import UIKit

class SharedViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentInteractionControllerDelegate {

    var files = ["Aadhar Card", "Mark Sheet", "Birth Certificate", "Health Insurance"]
    var filteredFiles: [String] = []
    var documentInteractionController: UIDocumentInteractionController?

    // Outlets for TableView and Buttons
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet var AddButtonView: UIView!

    // Search controller
    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize filtered files array with all files
        filteredFiles = files

        // Set up search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false

        // Change search bar appearance
        searchController.searchBar.isTranslucent = true
        searchController.searchBar.barTintColor = .clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        // Set up table view delegates
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")

        // Style buttons
        button1.setTitle("Deeptanshu", for: .normal)
        button2.setTitle("Sreeraj", for: .normal)
        button3.setTitle("Rose", for: .normal)
        button1.layer.cornerRadius = 10
        button2.layer.cornerRadius = 10
        button3.layer.cornerRadius = 10

        // Style AddButtonView
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false

        // Style table view
        tableView.layer.cornerRadius = 13
        tableView.backgroundColor = .clear
    }

    // MARK: - TableView DataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = filteredFiles[indexPath.row]
        return cell
    }

    // MARK: - Open Document on Cell Tap

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = filteredFiles[indexPath.row]
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

    // MARK: - Search Results Updating Delegate Method

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredFiles = files
        } else {
            filteredFiles = files.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
}

