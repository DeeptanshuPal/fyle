//
//  CategorySelectionViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 04/03/25.
//

import UIKit
import CoreData

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategories(_ categories: [Category])
}

class CategorySelectionViewController: UITableViewController {
    private let categories: [Category]
    private var selectedCategories: [Category]
    weak var delegate: CategorySelectionDelegate?
    
    init(categories: [Category], selectedCategories: [Category]) {
        self.categories = categories
        self.selectedCategories = selectedCategories
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func setupNavigationBar() {
        title = "Select Categories"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    @objc private func doneTapped() {
        delegate?.didSelectCategories(selectedCategories)
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.accessoryType = selectedCategories.contains(category) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        if let index = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
