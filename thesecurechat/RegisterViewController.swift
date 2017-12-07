//
//  RegisterViewController.swift
//  thesecurechat
//
//  Created by Guillaume Dénecé on 06/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

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
    
    @IBAction func register(_ sender: Any) {
        let parameters = ["username": username.text];
        
        guard let url = URL(string: "https://thesecurechat.me:3000/authentication/register/first") else { return }
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
                                print("salt: ", salt);
                                
                                // if let self.password.text
                                let passwordANDsalt = self.password.text! + salt;
                                let passwordANDsaltHASH = passwordANDsalt.sha256();
                                print("passwordANDsaltHASH: ", passwordANDsaltHASH)
                                
                                guard let url2 = URL(string: "https://thesecurechat.me:3000/authentication/register/second") else { return }
                                var request2 = URLRequest(url: url2)
                                request2.httpMethod = "POST"
                                request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                let parameters2 = ["username": self.username.text!, "hash_password": passwordANDsaltHASH] as [String : Any];
                                guard let httpBody2 = try? JSONSerialization.data(withJSONObject: parameters2, options: []) else { return }
                                request2.httpBody = httpBody2;
                                
                                let session2 = URLSession.shared;
                                session2.dataTask(with: request2) { (data2, response2, error2) in
                                    session2.finishTasksAndInvalidate();
                                    if let data2 = data2 {
                                        do {
                                            let json2 = try JSONSerialization.jsonObject(with: data2, options: [])
                                            print("ans: ", json2);
                                            if let ans2 = json2 as? [String: Any] {
                                                if let register = ans2["register"] as? String {
//                                                    DispatchQueue.main.async {
//                                                        self.performSegue(withIdentifier: "loginCheck", sender: self);
//                                                    }
                                                }
                                            }
                                        } catch {
                                            print(error);
                                        }
                                    }
                                }.resume()
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
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
