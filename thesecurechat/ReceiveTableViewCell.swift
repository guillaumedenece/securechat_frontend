//
//  RecceiveUITableViewCell.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 06/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class ReceiveTableViewCell: UITableViewCell {

    @IBOutlet weak var from: UITextView!
    @IBOutlet weak var message: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
