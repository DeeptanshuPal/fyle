//
//  HomeViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit

class HomeViewController: GradientBGViewController {
    @IBOutlet weak var FilesTileView: UIView!
    @IBOutlet weak var FilesTileImageView: UIView!
    @IBOutlet weak var RemindersTileView: UIView!
    @IBOutlet weak var RemindersTileImageView: UIView!
    @IBOutlet weak var CategoriesTileView: UIView!
    @IBOutlet weak var CategoriesTileImageView: UIView!
    @IBOutlet weak var SharedTileView: UIView!
    @IBOutlet weak var SharedTileImageView: UIView!
    @IBOutlet weak var FavouritesImageView: UIView!
    @IBOutlet weak var AddButtonView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        FilesTileView.layer.cornerRadius = 11
        FilesTileImageView.layer.cornerRadius = 20
        RemindersTileView.layer.cornerRadius = 11
        RemindersTileImageView.layer.cornerRadius = 20
        CategoriesTileView.layer.cornerRadius = 11
        CategoriesTileImageView.layer.cornerRadius = 20
        SharedTileView.layer.cornerRadius = 11
        SharedTileImageView.layer.cornerRadius = 20
        FavouritesImageView.layer.cornerRadius = 20
        
        
        AddButtonView.layer.cornerRadius = 75/2
        
        AddButtonView.layer.backgroundColor = UIColor.white.cgColor
        AddButtonView.layer.shadowColor = UIColor.black.cgColor
        //AddButtonView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        AddButtonView.layer.shadowOpacity = 0.5
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 5.0
        AddButtonView.layer.masksToBounds = false
        
    }
    

}
