//
//  ReceiveTableViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 06/12/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit

class ReceiveTableViewController: UITableViewController {
    
    var messages = [ReceiveMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(ReceiveMessage.init(from: "BOB", message: "HELO")!)
        messages.append(ReceiveMessage.init(from: "Alice", message: "jdshkf")!)
        
        guard let url = URL(string: "https://thesecurechat.me:3000/messages/receive") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(idToken!, forHTTPHeaderField: "idToken")

        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let ans = json as? [[String: Any]] {
                        for message in ans {
                            if let content = message["content"] as? String {
                                if let from_user_id = message["from_user_id"] as? String {
                                    var decryptedMessage: String
                                    do {
                                        let data = NSData(base64Encoded: content, options: .ignoreUnknownCharacters)
                                        try decryptedMessage = decrypter(cypher_text: data! as Data, private_key: thePrivateKey!)!
                                        
                                        self.messages.append(ReceiveMessage.init(from: "Carotte", message: "fhf")!)
                                        self.messages.append(ReceiveMessage.init(from: from_user_id, message: decryptedMessage)!)
                                        
                                        print("decripted message: ", decryptedMessage);
                                        print("from: ", from_user_id);
                                    }
                                    catch {
                                        print("Error \(error)")
                                    }
                                    
                                } else {
                                    print("from_user_id missing");
                                }
                            } else {
                                print("content missing");
                            }
                        }
                        print(self.messages);
                    }
                } catch {
                    print(error);
                }
            }
            }.resume()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "ReceiveTableViewCell"
        
            let cell = (tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ReceiveTableViewCell)!

        // Fetches the appropriate meal for the data source layout.
        let receiveMessage = self.messages[indexPath.row]

            cell.from.text = receiveMessage.from
            cell.message.text = receiveMessage.message
        
        
        
        return cell
    }
 

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
