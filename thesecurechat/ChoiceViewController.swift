//
//  ChoiceViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 06/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class ChoiceViewController: UIViewController {

    @IBOutlet weak var publickey: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var error:Unmanaged<CFError>?
        if let cfdata = SecKeyCopyExternalRepresentation(thePublicKey!, &error) {
            let data:Data = cfdata as Data
            publickey.text = data.base64EncodedString()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
