//
//  AccountViewController.swift
//  fyle
//
//  Created by User@77 on 20/11/24.
//

import UIKit

class AccountViewController: GradientBGViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        // Show a confirmation alert before logout
        let alert = UIAlertController(title: "Logout",
                                      message: "Are you sure you want to logout?",
                                      preferredStyle: .alert)
        
        let continueAction = UIAlertAction(title: "Continue", style: .destructive) { _ in
            self.goToLoginScreen() // Navigate to the login screen
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(continueAction)
        
        present(alert, animated: true, completion: nil)
    }

    private func goToLoginScreen() {
        // Clear any logged-in user details from UserDefaults
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        
        // Navigate to the login screen
        guard let loginVC = storyboard?.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController else {
            print("LogInViewController not found in storyboard!")
            return
        }

        // Set the login screen as the root view controller
        let navController = UINavigationController(rootViewController: loginVC)
        navController.modalPresentationStyle = .fullScreen
        self.view.window?.rootViewController = navController
        self.view.window?.makeKeyAndVisible()
    }

}

