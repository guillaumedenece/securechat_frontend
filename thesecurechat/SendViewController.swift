//
//  SendViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 05/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class SendViewController: UIViewController {
 
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var message: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickSend(_ sender: UIButton) {
        
        print("click send")

        print("before cipher")
        // Encrypt the message
        var cipher_text: Data? = nil;
        
        do {
            try cipher_text = encrypter(plain_text: message.text!, public_key: thePublicKey!)!
            print("after cipher")
        }
        catch {
            print("Error \(error)")
        }
        
        print("before send")
        /*
        // Create a JSON
        let parameters = ["to_user_id": username.text!, "message": cipher_text!] as [String : Any]
        
        guard let url = URL(string: "https://thesecurechat.me:3000/messages/send") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(idToken!, forHTTPHeaderField: "idToken")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let ans = json as? [String: Any] {
                        if let success = ans["success"] as? String {
                            print("message sent")
                        } else {
                            print("message not sent")
                        }
                    } else {
                        print(json);
                    }
                } catch {
                    print(error);
                }
            }
            }.resume()
 */
    }


}
