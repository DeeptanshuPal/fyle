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
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var summaryTextView: UITextView!
    @IBOutlet var confidentialDocView: UIView!
    @IBOutlet var confidentialSwitch: UISwitch!
    @IBOutlet var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
