//
//  LogInViewController.swift
//  fyle
//
//  Created by User@77 on 29/10/24.
//

import UIKit

// LoginViewController that combines both login and welcome functionality
class LogInViewController: GradientBGViewController {

    // Outlets for email and password text fields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUsers() // Load users from UserDefaults
    }
    
    // Action when the login button is tapped
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        handleLogin() // Call the login handler function
    }

    // Function to handle login logic
    func handleLogin() {
        guard let enteredEmail = emailTextField.text, let enteredPassword = passwordTextField.text else {
            return
        }
        
        // Check if there is a matching user in the users array
        if users.contains(where: { $0.email == enteredEmail && $0.password == enteredPassword }) {
            print("Login successful!")
            saveCurrentUser(email: enteredEmail) // Save the logged-in user's email
            navigateToHomeScreen()
        } else {
            print("Invalid email or password.")
            showErrorAlert()
        }
    }

    // Function to navigate to the Home screen
    func navigateToHomeScreen() {
        performSegue(withIdentifier: "showHomeScreen", sender: self)
    }

    // Function to show an error alert
    func showErrorAlert() {
        let alert = UIAlertController(title: "Login Failed", message: "Invalid email or password. Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // Save the currently logged-in user's email to UserDefaults
    func saveCurrentUser(email: String) {
        UserDefaults.standard.set(email, forKey: "currentUserEmail")
    }

    // Load the currently logged-in user's email from UserDefaults
    func loadCurrentUser() -> String? {
        return UserDefaults.standard.string(forKey: "currentUserEmail")
    }
}

