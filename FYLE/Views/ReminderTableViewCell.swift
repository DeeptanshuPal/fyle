//
//  ReminderTableViewCell.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 09/03/25.
//

import UIKit

class RemindersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    let chevronButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        button.tintColor = .systemGray4
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.tag = 1001
        return button
    }()
    
    private var fileNameTrailingConstraint: NSLayoutConstraint?
    private var fileNameTrailingToContentViewConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
        setupConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setupViews() {
        fileNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fileNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chevronButton.isUserInteractionEnabled = true
    }
    
    private func setupConstraints() {
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            fileNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            fileNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileNameLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 16),
            fileNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 16),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
        ])
        
        fileNameTrailingConstraint = fileNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -8)
        fileNameTrailingToContentViewConstraint = fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
    }
    
    func configureForEmptyState(placeholderText: String) {
        fileNameLabel.text = placeholderText
        fileNameLabel.textAlignment = .center
        fileNameLabel.numberOfLines = 0
        fileNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        fileNameLabel.textColor = #colorLiteral(red: 0.3672261238, green: 0.3787894845, blue: 0.3846254349, alpha: 0.8043253311)
        dateLabel.isHidden = true
        self.accessoryView = nil
        isUserInteractionEnabled = false
        contentView.backgroundColor = .clear // Clear, as backgroundView handles the color
        backgroundColor = .clear
        fileNameTrailingConstraint?.isActive = false
        fileNameTrailingToContentViewConstraint?.isActive = true
    }

    func configureForNonEmptyState(fileName: String, dateText: String, dateColor: UIColor, chevronTarget: Any?, action: Selector) {
        fileNameLabel.text = fileName
        fileNameLabel.textAlignment = .left
        fileNameLabel.numberOfLines = 1
        dateLabel.text = dateText
        dateLabel.textColor = dateColor
        dateLabel.isHidden = false
        self.accessoryView = chevronButton
        chevronButton.removeTarget(nil, action: nil, for: .allEvents)
        chevronButton.addTarget(chevronTarget, action: action, for: .touchUpInside)
        isUserInteractionEnabled = true
        contentView.backgroundColor = .clear // Clear, as backgroundView handles the color
        backgroundColor = .clear
        fileNameTrailingToContentViewConstraint?.isActive = false
        fileNameTrailingConstraint?.isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessoryView = nil
        fileNameLabel.text = nil
        dateLabel.text = nil
        dateLabel.textColor = .black
        dateLabel.isHidden = false
        chevronButton.removeTarget(nil, action: nil, for: .allEvents)
        fileNameTrailingConstraint?.isActive = false
        fileNameTrailingToContentViewConstraint?.isActive = false
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}
