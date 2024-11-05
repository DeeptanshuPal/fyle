//
//  ViewController.swift
//  fyle
//
//  Created by User@77 on 28/10/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var bellUIView: UIView!
    @IBOutlet weak var docUIView: UIView!
    @IBOutlet weak var personUIView: UIView!
    @IBOutlet weak var gridUIView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bellUIView.layer.cornerRadius = 25
        docUIView.layer.cornerRadius = 25
        personUIView.layer.cornerRadius = 25
        gridUIView.layer.cornerRadius = 25
        
    }
}
