//
//  LoginViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 02/03/25.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginWithGoogleButton: UIButton!
    @IBOutlet weak var loginWithAppleButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable return key to dismiss keyboard
        usernameTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .done
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: Any) {
    }
    @IBAction func loginButtonTapped(_ sender: Any) {
//        // Successful login
//        DispatchQueue.main.async {
//            self.performSegue(withIdentifier: "LogInToHomeScreen", sender: self)
//        }
    }
    @IBAction func signupButtonTapped(_ sender: Any) {
    }
 
}
