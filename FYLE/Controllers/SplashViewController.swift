//
//  SplashViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 02/03/25.
//

import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var bellUIView: UIView!
    @IBOutlet var docUIView: UIView!
    @IBOutlet var personUIView: UIView!
    @IBOutlet var gridUIView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var dataManaged: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI elements
        setupUI()
    }
    
    private func setupUI() {
        // Apply corner radius to UIViews
        bellUIView.layer.cornerRadius = 25
        docUIView.layer.cornerRadius = 25
        personUIView.layer.cornerRadius = 25
        gridUIView.layer.cornerRadius = 25
        
        // Style the continue button
        continueButton.layer.cornerRadius = 10
        continueButton.clipsToBounds = true
    }
    
    // MARK: - IBActions
    @IBAction func ContinueButtonPressed(_ sender: Any) {
        // Mark that the user has seen the splash screen
        UserDefaults.standard.set(true, forKey: "hasSeenSplash")
        
        // Transition to HomeViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        let navigationController = UINavigationController(rootViewController: homeVC)
        
        // Set the new root view controller with a smooth transition
        if let window = UIApplication.shared.windows.first {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navigationController
            }, completion: nil)
        }
    }
    
    @IBAction func clickdataManaged(_ sender: Any) {
        // Present the WebViewController embedded in a navigation controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let webVC = storyboard.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController {
            let navController = UINavigationController(rootViewController: webVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true, completion: nil)
        }
    }
}
