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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bellUIView.layer.cornerRadius = 25
        docUIView.layer.cornerRadius = 25
        personUIView.layer.cornerRadius = 25
        gridUIView.layer.cornerRadius = 25
        
    }
}
