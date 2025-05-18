//
//  KeyValueTableViewCell.swift
//  FYLE
//
//  Created by Deeptanshu Pal on 05/03/25.
//

import UIKit

protocol KeyValueCellDelegate: AnyObject {
    func didUpdateKeyValue(key: String?, value: String?, at index: Int)
}

class KeyValueTableViewCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var KeyTextField: UITextField!
    @IBOutlet weak var ValueTextField: UITextField!
    @IBOutlet weak var ColonLabel: UILabel!
    
    weak var delegate: KeyValueCellDelegate?
    var index: Int?
    
    // Add centered label for "no summary" message
    lazy var noSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray
        label.numberOfLines = 0
        label.isHidden = true // Hidden by default
        self.contentView.addSubview(label)
        
        // Center the label in the cell with padding
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
        ])
        
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        KeyTextField.delegate = self
        ValueTextField.delegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        KeyTextField.text = nil
        ValueTextField.text = nil
        ColonLabel.text = ":"
        KeyTextField.isHidden = false
        ValueTextField.isHidden = false
        ColonLabel.isHidden = false
        noSummaryLabel.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didUpdateKeyValue(key: KeyTextField.text, value: ValueTextField.text, at: index ?? -1)
    }
}
