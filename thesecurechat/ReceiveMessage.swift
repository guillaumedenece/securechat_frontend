//
//  ReceiveMessage.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 06/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit


class ReceiveMessage {
    
    //MARK: Properties
    
    var from: String
    var message: String
    
    //MARK: Archiving Paths
    //static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    //static let ArchiveURL = DocumentsDirectory.appendingPathComponent("meals")

    
    //MARK: Initialization
    init?(from: String, message: String) {
        
        // Initialization should fail if there is no from.
        if from.isEmpty  {
            return nil
        }
        
        // Initialize stored properties.
        self.from = from
        self.message = message
        
    }
}
