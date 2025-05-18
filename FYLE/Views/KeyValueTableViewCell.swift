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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        KeyTextField.delegate = self
        ValueTextField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didUpdateKeyValue(key: KeyTextField.text, value: ValueTextField.text, at: index ?? -1)
    }
}
