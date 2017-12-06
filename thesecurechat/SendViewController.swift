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
        
        // Convert the public key into a SecKey
        guard let data2 = Data.init(base64Encoded: publickey.text!) else {
            return
        }
        
        let keyDict:[NSObject:NSObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: NSNumber(value: 512),
            kSecReturnPersistentRef: true as NSObject
        ]
        
        guard let thePublicKey = SecKeyCreateWithData(data2 as CFData, keyDict as CFDictionary, nil) else {
            return
        }
        
        // Encrypt the message
        var cipher_text: Data? = nil;
        
        do {
            try cipher_text = encrypter(plain_text: message.text!, public_key: thePublicKey)!
        }
        catch {
            print("Error \(error)")
        }
        
        // Create a JSON
        /*let parameters = ["username": username.text!, "message": cipher_text!] as [String : Any]
        
        guard let url = URL(string: "https://thesecurechat.me:3000/messages/send") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(idtoken, forHTTPHeaderField: "idToken")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let ans = json as? [String: Any] {
                        if let salt = ans["salt"] as? String {
                            if let challenge = ans["challenge"] as? String {
                                print("salt: ", salt);
                                print("challenge: ", challenge);
                                
                                // if let self.password.text
                                let passwordANDsalt = self.password.text! + salt;
                                let passwordANDsaltHASH = passwordANDsalt.sha256();
                                print("passwordANDsaltHASH: ", passwordANDsaltHASH)
                                let challengeANDpasswordANDsaltHASH = passwordANDsaltHASH + challenge;
                                let solution = challengeANDpasswordANDsaltHASH.sha256();
                                print("hash_password: ", solution);
                                
                                guard let url2 = URL(string: "https://thesecurechat.me:3000/authentication/login/second") else { return }
                                var request2 = URLRequest(url: url2)
                                request2.httpMethod = "POST"
                                request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                let parameters2 = ["username": self.username.text!, "hash_password_challenge": solution] as [String : Any];
                                guard let httpBody2 = try? JSONSerialization.data(withJSONObject: parameters2, options: []) else { return }
                                request2.httpBody = httpBody2;
                                
                                let session2 = URLSession.shared;
                                session2.dataTask(with: request2) { (data2, response2, error2) in
                                    if let data2 = data2 {
                                        do {
                                            let json2 = try JSONSerialization.jsonObject(with: data2, options: [])
                                            print("token: ", json2);
                                        } catch {
                                            print(error)
                                        }
                                        
                                    }
                                    }.resume()
                            } else {
                                print("missing parameters");
                            }
                        } else {
                            print("missing parameters");
                        }} else {
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
