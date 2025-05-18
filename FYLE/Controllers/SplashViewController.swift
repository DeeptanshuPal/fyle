//
//  SplashViewController.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 02/03/25.
//

import UIKit

class SplashViewController: UIViewController {
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
    }
            
}
