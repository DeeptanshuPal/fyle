//
//  LogInViewController.swift
//  fyle
//
//  Created by User@77 on 29/10/24.
//

import UIKit
import FirebaseAuth

class LogInViewController: GradientBGViewController {
    
    // Outlets for email and password text fields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var LogInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogInButton.layer.cornerRadius = 10
    }
    
    //empty the text fields
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Clear text fields
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    // Action when the login button is tapped
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Validate user input
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(message: "Email is required!")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Password is required!")
            return
        }
        
        // Authenticate with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                // Debug: Print error code
                print("Firebase error code: \(error._code)")
                
                // Handling Firebase error codes more accurately
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .invalidEmail:
                        self.showAlert(message: "Please enter a valid email.")
                    default:
                        self.showAlert(message: "Incorrect Username or Password.")
                    }
                } else {
                    // Fallback for unknown error codes
                    self.showAlert(message: "An unknown error occurred. Please try again.")
                }
                return
            }
            
            // Successful login
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "LogInToHomeScreen", sender: self)
            }
        }
    }
    
    // Helper to show alerts
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    

}



        
//      handleLogin() // Call the login handler function

    // Function to handle login logic
//    func handleLogin() {
//        guard let enteredEmail = emailTextField.text, let enteredPassword = passwordTextField.text else {
//            return
//        }
//        
//        // Check if there is a matching user in the users array
//        if users.contains(where: { $0.email == enteredEmail && $0.password == enteredPassword }) {
//            print("Login successful!")
//            saveCurrentUser(email: enteredEmail) // Save the logged-in user's email
//            navigateToHomeScreen()
//        } else {
//            print("Invalid email or password.")
//            showErrorAlert()
//        }
//    }

    // Function to navigate to the Home screen
//    func navigateToHomeScreen() {
//        performSegue(withIdentifier: "showHomeScreen", sender: self)
//    }

    // Function to show an error alert
//    func showErrorAlert() {
//        let alert = UIAlertController(title: "Login Failed", message: "Invalid email or password. Please try again.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }

    // Save the currently logged-in user's email to UserDefaults
//    func saveCurrentUser(email: String) {
//        UserDefaults.standard.set(email, forKey: "currentUserEmail")
//    }

    // Load the currently logged-in user's email from UserDefaults
//    func loadCurrentUser() -> String? {
//        return UserDefaults.standard.string(forKey: "currentUserEmail")
//    }
//}

