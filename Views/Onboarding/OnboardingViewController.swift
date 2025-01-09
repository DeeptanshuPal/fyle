//
//  OnboardingViewController.swift
//  fyle
//
//  Created by User@77 on 20/11/24.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    @IBOutlet var bellUIView: UIView!
    @IBOutlet var docUIView: UIView!
    @IBOutlet var personUIView: UIView!
    @IBOutlet var gridUIView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bellUIView.layer.cornerRadius = 25
        docUIView.layer.cornerRadius = 25
        personUIView.layer.cornerRadius = 25
        gridUIView.layer.cornerRadius = 25
        
    }
    
    @IBAction func ContinueButtonPressed(_ sender: Any) {
        // Load the LogInViewController
        guard let logInVC = storyboard?.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController else {
            print("LogInViewController not found!")
            return
        }
        
        // Access the window and set the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = logInVC
            window.makeKeyAndVisible()
        } else {
            print("Failed to access the window.")
        }
    }
}
