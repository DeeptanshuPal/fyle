import UIKit

class RemindersViewController: GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentInteractionControllerDelegate {

    struct File {
        let id: Int
        let name: String
        let expDate: String
    }

    let data: [File] = [
        File(id: 1, name: "Car Insurance", expDate: "21/11/2024"),
        File(id: 2, name: "Pollution Control", expDate: "22/11/2024"),
        File(id: 3, name: "Warranty", expDate: "25/03/2025"),
        File(id: 4, name: "Passport", expDate: "26/11/2024"),
        File(id: 5, name: "Driving License", expDate: "26/11/2025"),
        File(id: 6, name: "Health Insurance", expDate: "27/11/2024"),
        File(id: 7, name: "Home Insurance", expDate: "01/06/2025"),
        File(id: 8, name: "Vehicle Registration", expDate: "15/12/2024"),
        File(id: 9, name: "Credit Card", expDate: "20/12/2024"),
    ]

    var dueData: [File] = []
    var upcomingData: [File] = []
    var futureData: [File] = []

    var filteredDueData: [File] = []
    var filteredUpcomingData: [File] = []
    var filteredFutureData: [File] = []

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var AddButtonView: UIView!

    // Set up Search
    let searchController = UISearchController()
    var filteredCategories: [Categories] = categories // Initially display all categories
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a translucent navigation bar appearance when scrolled
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // Makes the background translucent
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Text color for small titles
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white] // Text color for large titles
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3) // Adjust alpha for translucency
        navigationController?.navigationBar.standardAppearance = appearance
        appearance.backgroundColor = UIColor.clear
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true // Ensure the navigation bar is translucent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        categorizeData()
        filteredDueData = dueData
        filteredUpcomingData = upcomingData
        filteredFutureData = futureData

        // Setup Search Controller
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        // change appearance
        searchController.searchBar.isTranslucent = true // Make it translucent
        searchController.searchBar.barTintColor = .clear // Ensure the bar itself is clear
        searchController.searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Semi-transparent text field

        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 13
        tableView.layer.masksToBounds = true
        
        // Configure AddButtonView appearance
        AddButtonView.layer.cornerRadius = 75 / 2
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        
        updateTableViewHeight() // Adjust table view height after filtering
    }

    // Categorize data into "Due", "Upcoming", and "Future"
    func categorizeData() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        for file in data {
            if let fileDate = dateFormatter.date(from: file.expDate) {
                let fileMonth = calendar.component(.month, from: fileDate)
                let fileYear = calendar.component(.year, from: fileDate)

                if fileDate < now {
                    dueData.append(file)
                } else if fileYear == currentYear && fileMonth == currentMonth {
                    upcomingData.append(file)
                } else {
                    futureData.append(file)
                }
            }
        }
    }

    // MARK: - Helper Function to Update Table View Height
    func updateTableViewHeight() {
        let rowHeight: CGFloat = 47.0
        let sectionHeaderHeight: CGFloat = 50.0
        let dueRowsHeight = rowHeight * CGFloat(filteredDueData.count)
        let upcomingRowsHeight = rowHeight * CGFloat(filteredUpcomingData.count)
        let futureRowsHeight = rowHeight * CGFloat(filteredFutureData.count)

        let totalHeight = dueRowsHeight + upcomingRowsHeight + futureRowsHeight + (sectionHeaderHeight * 3)

        view.layoutIfNeeded() // Apply changes immediately
        
        // Animate the height change
        UIView.animate(withDuration: 0.15, animations: {
            self.tableViewHeightConstraint.constant = totalHeight
            self.view.layoutIfNeeded() // Ensure the layout updates smoothly
        })
    }

    
    // MARK: - TableView DataSource Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return filteredDueData.count
        case 1:
            return filteredUpcomingData.count
        case 2:
            return filteredFutureData.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Due"
        case 1:
            return "Upcoming"
        case 2:
            return "Future"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! RemindersTableViewCell

        let file: File
        switch indexPath.section {
        case 0:
            file = filteredDueData[indexPath.row]
            cell.ExpiryDateLabel.textColor = .systemRed
        case 1:
            file = filteredUpcomingData[indexPath.row]
            cell.ExpiryDateLabel.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0) // Darker yellow
        case 2:
            file = filteredFutureData[indexPath.row]
            cell.ExpiryDateLabel.textColor = .systemGreen
        default:
            fatalError("Unexpected section index")
        }

        cell.FileNameLabel.text = file.name
        cell.ExpiryDateLabel.text = file.expDate

        return cell
    }

    // MARK: - Search Results Updating Delegate Method

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""

        if searchText.isEmpty {
            filteredDueData = dueData
            filteredUpcomingData = upcomingData
            filteredFutureData = futureData
        } else {
            filteredDueData = dueData.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            filteredUpcomingData = upcomingData.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            filteredFutureData = futureData.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }

        tableView.reloadData()
        updateTableViewHeight() // Adjust table view height after filtering
    }

    // MARK: - TableView Delegate Method

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file: File
        switch indexPath.section {
        case 0:
            file = filteredDueData[indexPath.row]
        case 1:
            file = filteredUpcomingData[indexPath.row]
        case 2:
            file = filteredFutureData[indexPath.row]
        default:
            fatalError("Unexpected section index")
        }

        if let fileURL = Bundle.main.url(forResource: file.name, withExtension: "pdf") {
            let documentInteractionController = UIDocumentInteractionController(url: fileURL)
            documentInteractionController.delegate = self
            documentInteractionController.presentPreview(animated: true)
        } else {
            print("Document \(file.name) not found in the bundle.")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
