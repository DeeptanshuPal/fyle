//
//  CategoriesViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit

class CategoriesViewController: GradientBGViewController {
    @IBOutlet weak var HomeCategoryView: UIView!
    @IBOutlet weak var HomeCategoryImageView: UIView!
    @IBOutlet weak var AddButtonView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        HomeCategoryView.layer.cornerRadius = 11
        HomeCategoryImageView.layer.cornerRadius = 47 / 2
        
        AddButtonView.layer.cornerRadius = 75/2
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 10
    }

}
