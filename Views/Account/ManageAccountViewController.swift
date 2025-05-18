//
//  ManageAccountViewController.swift
//  fyle
//
//  Created by User@77 on 20/11/24.
//

import UIKit

class ManageAccountViewController: GradientBGViewController {

    @IBOutlet var editLabel: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editLabel.layer.cornerRadius = editLabel.frame.height/2
        editLabel.layer.shadowColor = UIColor.black.cgColor
        editLabel.layer.shadowOpacity = 0.5
        editLabel.layer.shadowOffset = .zero
        editLabel.layer.shadowRadius = 5.0
        editLabel.layer.masksToBounds = false
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
