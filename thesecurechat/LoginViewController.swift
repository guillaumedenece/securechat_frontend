//
//  LoginViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 05/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit
var idToken: String? = nil
var thePrivateKey: SecKey? = nil
var thePublicKey: SecKey? = nil

class LoginViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func clickLogin(_ sender: UIButton) {
        let parameters = ["username": username.text];
        print("idToken: ", idToken);
        
        guard let url = URL(string: "https://thesecurechat.me:3000/authentication/login/first") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            session.finishTasksAndInvalidate();
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
                                    session2.finishTasksAndInvalidate();
                                    if let data2 = data2 {
                                        do {
                                            let json2 = try JSONSerialization.jsonObject(with: data2, options: [])
                                            print("token: ", json2);
                                            if let ans2 = json2 as? [String: Any] {
                                                if let newIdToken = ans2["idToken"] as? String {
                                                    idToken = newIdToken;
                                                    DispatchQueue.main.async {
                                                        // Get the private key of the user
                                                        thePrivateKey = getPrivateKey(username: self.username.text!)
                                                        
                                                        // Get the public key
                                                        thePublicKey = SecKeyCopyPublicKey(thePrivateKey!);
                                                        self.performSegue(withIdentifier: "loginCheck", sender: self);
                                                    }
                                                }
                                            }
                                        } catch {
                                            print(error);
                                        }
                                        
                                    }
                                }.resume()
                            } else {
                                print("missing challenge");
                            }
                        } else {
                            print("missing salt");
                        }} else {
                             print(json);
                        }
                    } catch {
                        print(error);
                    }
                }
            }.resume()
        
        }
        
    }


    extension String {
        
        func sha256() -> String{
            if let stringData = self.data(using: String.Encoding.utf8) {
                return hexStringFromData(input: digest(input: stringData as NSData))
            }
            return ""
        }
        
        private func digest(input : NSData) -> NSData {
            let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
            var hash = [UInt8](repeating: 0, count: digestLength)
            CC_SHA256(input.bytes, UInt32(input.length), &hash)
            return NSData(bytes: hash, length: digestLength)
        }
        
        private  func hexStringFromData(input: NSData) -> String {
            var bytes = [UInt8](repeating: 0, count: input.length)
            input.getBytes(&bytes, length: input.length)
            
            var hexString = ""
            for byte in bytes {
                hexString += String(format:"%02x", UInt8(byte))
            }
            
            return hexString
        }
        
}
