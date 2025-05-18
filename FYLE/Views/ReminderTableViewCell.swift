//
//  ReminderTableViewCell.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit

class RemindersTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the cell’s layer is updated by the view controller
    }
}
