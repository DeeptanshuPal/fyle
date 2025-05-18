//
//  TileCollectionViewCell.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 28/02/25.
//

import UIKit

class TileCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var TileTitleLabel: UILabel!
    @IBOutlet weak var TileCountLabel: UILabel!
    @IBOutlet weak var TileImageBG: UIView!
    @IBOutlet weak var TileImage: UIImageView!
    
    func configure(with tile: HomeViewController.Tile) {
        TileTitleLabel.text = tile.title
        TileTitleLabel.textColor = tile.titleColor

        TileImage.image = UIImage(systemName: tile.imageName)
        TileImage.tintColor = tile.imageColor

        TileCountLabel.text = "\(tile.count)"
        TileCountLabel.textColor = tile.countColor

        TileImageBG.backgroundColor = tile.bgColor

        // Apply corner radius
        layer.cornerRadius = 11
        TileImageBG.layer.cornerRadius = TileImageBG.frame.height / 2
        
        // Apply Shadow
        layer.masksToBounds = false  // Important! Must be false for shadow to work
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        // Optional: Add a shadow path for better performance
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 11).cgPath
    }
}

