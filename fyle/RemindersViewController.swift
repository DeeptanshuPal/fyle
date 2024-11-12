//
//  RemindersViewController.swift
//  fyle
//
//  Created by Sana Sreeraj on 13/11/24.
//

import UIKit

class RemindersViewController:GradientBGViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate{
    
    


    // Arrays for table data
    var reminders = ["Car Insuarance", "Pollution Control", "Gym Membership", "Certification", "Warrenty"]
    var filteredReminders: [String] = []
    var secondReminders = ["Bike Insuarance", "Warrenty", ]
  

    // Outlets for the TableViews, Labels, and Search Bar
    @IBOutlet weak var titleLabel1: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView1: UITableView!
    
    @IBOutlet weak var titleLabel2: UILabel!
    @IBOutlet weak var tableView2: UITableView!
    @IBOutlet var AddButtonView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
      
        // Initialize filtered reminders
        filteredReminders = reminders

        // Set up the search bar and table view delegates
        searchBar.delegate = self
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
            cell.textLabel?.text = filteredReminders[indexPath.row]
            return cell
        } else if tableView == tableView2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SecondReminderCell", for: indexPath)
            cell.textLabel?.text = secondReminders[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }

    // MARK: - Search Bar Delegate Method for Filtering Table 1

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredReminders = reminders
        } else {
            filteredReminders = reminders.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        tableView1.reloadData()
    }
}
