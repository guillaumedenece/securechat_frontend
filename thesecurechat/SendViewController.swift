//
//  SendViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 05/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class SendViewController: UIViewController {
 
    @IBOutlet weak var publickey: UITextField!
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
        
        let alertSent = UIAlertController(title: "message", message: "sent", preferredStyle: .alert);
        let alertNotSent = UIAlertController(title: "message", message: "not sent", preferredStyle: .alert);
        let actionOk = UIAlertAction(title: "ok", style: .default, handler: nil)
        alertSent.addAction(actionOk);
        alertNotSent.addAction(actionOk);
        
        print("click send")

        print("before cipher")
        // Encrypt the message
        var cipher_text: Data? = nil;
        
        guard let data2 = Data.init(base64Encoded: publickey.text!) else {
            return
        }
        
        let keyDict:[NSObject:NSObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 256 as NSObject,
            kSecReturnPersistentRef: true as NSObject
        ]
        
        guard let publicKey = SecKeyCreateWithData(data2 as CFData, keyDict as CFDictionary, nil) else {
            return
        }
        
        do {
            try cipher_text = encrypter(plain_text: message.text!, public_key: publicKey)!
            print("after cipher")
        }
        catch {
            print("Error \(error)")
        }
        
        print("before send")
        
        // Create a JSON
        let parameters = ["to_user_id": username.text!, "message": cipher_text?.base64EncodedString()]
        
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
                        print("ans: ", json);
                        if (ans["success"] as? String) != nil {
                            DispatchQueue.main.async {
                                self.present(alertSent, animated: true, completion: nil);
                            }
                        } else {
                            DispatchQueue.main.async {
                            self.present(alertNotSent, animated: true, completion: nil);
                            }
                        }
                    } else {
                        print(json);
                    }
                } catch {
                    print(error);
                }
            }
            }.resume()
 
    }


}
