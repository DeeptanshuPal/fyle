//
//  RemindersViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//
import UIKit

class RemindersViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentInteractionControllerDelegate {

    // Arrays for table data
    var reminders = [("21/11/24", "Car Insurance"), ("22/11/24", "Pollution Control"), ("25/11/24", "Warranty"),
                     ("26/11/24", "Passport"), ("26/11/24", "Driving License"), ("27/11/24", "Health Insurance")]
    var filteredReminders: [(String, String)] = []
    var secondReminders = [("01/12/24", "Driving License"), ("15/12/24", "Certification")]

    // Outlets for the TableViews and Labels
    @IBOutlet weak var titleLabel1: UILabel!
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var titleLabel2: UILabel!
    @IBOutlet weak var tableView2: UITableView!
    @IBOutlet var AddButtonView: UIView!

    // Search controller
    var searchController: UISearchController!
    
    // Document Interaction Controller
    var documentInteractionController: UIDocumentInteractionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize filtered reminders
        filteredReminders = reminders

        // Set up search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Reminders"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false

        // Change appearance
        searchController.searchBar.isTranslucent = true
        searchController.searchBar.barTintColor = .clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        // Set up table view delegates
        tableView1.dataSource = self
        tableView1.delegate = self
        tableView2.dataSource = self
        tableView2.delegate = self

        // Register default cells for both table views
        tableView1.register(UITableViewCell.self, forCellReuseIdentifier: "ReminderCell")
        tableView2.register(UITableViewCell.self, forCellReuseIdentifier: "SecondReminderCell")

        // Set titles for each label
        titleLabel1.text = "This Month"
        titleLabel2.text = "Future"
        
        // Configure AddButtonView appearance
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        
        tableView1.layer.cornerRadius = 13
        tableView2.layer.cornerRadius = 13
    }

    // MARK: - TableView DataSource Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableView1 {
            return filteredReminders.count
        } else if tableView == tableView2 {
            return secondReminders.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableView1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath)
            let reminder = filteredReminders[indexPath.row]
            // Set up the left side date label and the reminder text
            cell.textLabel?.text = "\(reminder.0)    -    \(reminder.1)"
            return cell
        } else if tableView == tableView2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SecondReminderCell", for: indexPath)
            let reminder = secondReminders[indexPath.row]
            // Set up the left side date label and the reminder text
            cell.textLabel?.text = "\(reminder.0)    -    \(reminder.1)"
            return cell
        }
        return UITableViewCell()
    }

    // MARK: - TableView Delegate Method

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedFileName: String

        if tableView == tableView1 {
            selectedFileName = filteredReminders[indexPath.row].1
        } else if tableView == tableView2 {
            selectedFileName = secondReminders[indexPath.row].1
        } else {
            return
        }

        // Dynamically construct the file URL
        if let fileURL = Bundle.main.url(forResource: selectedFileName, withExtension: "pdf") {
            // Initialize and set up the document interaction controller
            documentInteractionController = UIDocumentInteractionController(url: fileURL)
            documentInteractionController?.delegate = self

            // Present the document preview
            documentInteractionController?.presentPreview(animated: true)
        } else {
            print("Document \(selectedFileName) not found in the bundle.")
        }

        // Deselect the row after selection
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Search Results Updating Delegate Method

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        if searchText.isEmpty {
            filteredReminders = reminders
        } else {
            filteredReminders = reminders.filter { $0.1.lowercased().contains(searchText.lowercased()) }
        }
        tableView1.reloadData()
    }

    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
