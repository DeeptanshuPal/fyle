//
//  AddFileFormViewController.swift
//  fyle
//
//  Created by User@77 on 13/11/24.
//

import UIKit

class AddFileFormViewController: UIViewController {

    @IBOutlet var FileThumbnailImageView: UIImageView!
    @IBOutlet var fileNameTextField: UITextField!
    @IBOutlet weak var reminderDate: UIView!
    @IBOutlet var summaryTextView: UITextView!
    @IBOutlet var confidentialDocView: UIView!
    @IBOutlet var confidentialSwitch: UISwitch!
    @IBOutlet var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
}
