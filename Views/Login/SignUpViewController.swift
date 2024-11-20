//
//  SignUpViewController.swift
//  fyle
//
//  Created by User@77 on 29/10/24.
//

import UIKit

class SignUpViewController: GradientBGViewController {

    // Outlets for text fields
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Load existing users when the view loads
        loadUsers()
    }

    // Action for the sign-up button
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        // Get user input
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "All fields are required!")
            return
        }

        // Validate password and confirm password match
        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match!")
            return
        }

        // Check if the email already exists
        if users.contains(where: { $0.email == email }) {
            showAlert(message: "Email is already registered!")
            return
        }

        // Add new user to the users array
        let newUser = AppUser(fullName: fullName, email: email, phoneNumber: phoneNumber, password: password)
        users.append(newUser)

        // Save users to UserDefaults
        saveUsers()

        // Log the updated users array to console (for debugging)
        print("Updated Users Array: \(users)")

        // Show success message and navigate to the login screen
        showAlert(message: "Registration successful! Please log in.") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    // Helper function to show alerts
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true, completion: nil)
    }
}
