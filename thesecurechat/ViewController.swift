//
//  ViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 20/10/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit
//import Security.framework

class ViewController: UIViewController, UITextFieldDelegate  {

    
    // MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var encryptedLabel: UILabel!
    @IBOutlet weak var decryptedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle the text field’s user input through delegate callbacks.
        nameTextField.delegate = self
    }

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
    
    // Generate a private key
    func generate_privateKey() -> SecKey?{
        
        let attributes: [String: Any] =
            //[kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,  //kSecAttrKeyTypeECSECPrimeRandom,
            // kSecAttrKeySizeInBits as String:      2048,                //256,
            [kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String:      256,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String:    true,
                 kSecAttrApplicationTag as String: "mykey".data(using: .utf8)!]
        ]
        
        var error: Unmanaged<CFError>?
        //guard
            let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) //else {
            //throw error!.takeRetainedValue() as Error
        //}

        return privateKey;
    }
    
    
    // Function called when the user is done typing his message
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // Generate a private key
        let privateKey = generate_privateKey();

        if(privateKey != nil) {
            
            // Generate a public key based on the private key
            let publicKey = SecKeyCopyPublicKey(privateKey!);

            /*
            var error:Unmanaged<CFError>?
            if let cfdata = SecKeyCopyExternalRepresentation(privateKey!, &error) {
                let data:Data = cfdata as Data
                print("pri_key: ", data.base64EncodedString())
            }
            
            if let cfdata = SecKeyCopyExternalRepresentation(publicKey!, &error) {
                let data:Data = cfdata as Data
                print("pub_key: ", data.base64EncodedString())
            }
             */
            
            var cipher_text: Data? = nil;
            
            // Encrypt the input string
            do {
                 try cipher_text = encrypter(plain_text: textField.text!, public_key: publicKey!)!
            }
            catch {
                print("Error \(error)")
            }
            
            // Display the encrypted result
            encryptedLabel.text = cipher_text?.base64EncodedString()
            
            // Decrypt the cypher text and display it
            do {
                try decryptedLabel.text = decrypter(cypher_text: cipher_text!, private_key: privateKey!)
            }
            catch {
                print("Error \(error)")
            }
       }
    }


    // MARK: Actions
    @IBAction func setDefaultLabelText(_ sender: UIButton) {
        encryptedLabel.text = "Default Text"
    }
    
    
    // MARK: Functions
    func encrypter(plain_text: String, public_key: SecKey) throws -> Data? {
        let key_size: Int = 256/8;
        let block_size = 2048;
        
        var error: Int32 = 0;
        var key_aes = Data(count: key_size);
        var str_key_aes:String;
        var key_hmac = Data(count: key_size);
        var str_key_hmac:String;
        var initialization_vector:Data;
        
        
        // Generation of a random key for AES
        error = key_aes.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, key_aes.count, mutableBytes)
        }
        
        if error != errSecSuccess {
            print("Problem generating random bytes")
            return nil
        }
        
        str_key_aes = key_aes.base64EncodedString(options: [])
        //print("STRING AES: ", str_key_aes)
        
        
        // Generation of IV
        initialization_vector = Data(count: block_size)
        error = initialization_vector.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            // NB: not sure we can use the same function here
            SecRandomCopyBytes(kSecRandomDefault, initialization_vector.count, mutableBytes)
        }
        
        if error != errSecSuccess {
            print("Problem generating random bytes")
            return nil
        }
        
        let str_initialization_vector = initialization_vector.base64EncodedString(options: [])
        //print("STR_IV: ", str_initialization_vector)
        
        
        // Cypher Text with AES
        let cypher_text = plain_text.aesEncrypt(key: str_key_aes, iv: str_initialization_vector, options: kCCOptionPKCS7Padding + kCCModeCBC)
        //print("CYPHERTEXT:", cypher_text)
        
        
        // Generation of a random key for HMAC
        error = key_hmac.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, key_hmac.count, mutableBytes)
        }
        
        if error != errSecSuccess {
            print("Problem generating random bytes")
            return nil
        }
        
        str_key_hmac = key_hmac.base64EncodedString(options: [])
        //print("key_hmac: ", str_key_hmac)
        
        
        // Tag with HMAC
        let tag = cypher_text?.hmac(key: str_key_hmac)
        print("TAG:", tag)
        
        
        // Concatenate keys
        let key_conca = str_key_hmac + str_key_aes
        //print("key conca: ", key_conca)
        
        
        // RSA
        let algorithm: SecKeyAlgorithm = .eciesEncryptionStandardX963SHA512AESGCM //.rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(public_key, .encrypt, algorithm) else {
            print("Problem with the public_key")
            return nil
        }

        var errorEncrypt: Unmanaged<CFError>?
        guard let cypher_key = SecKeyCreateEncryptedData(public_key,
                                                          algorithm,
                                                          key_conca.data(using: String.Encoding.utf8)! as CFData,
                                                          &errorEncrypt) as Data? else {
                                                            throw errorEncrypt!.takeRetainedValue() as Error
        }

        let str_cypher_key = cypher_key.base64EncodedString(options: [])
        //print("Cypher text: " str_cypher_text)
        
        
        // Create a JSON
        let output_packet = OutputPacket(cypher_text: cypher_text!,
                                         cypher_key: str_cypher_key,
                                         iv: str_initialization_vector,
                                         tag: tag!)
        
        let encoder = JSONEncoder()
        let outputJson = try! encoder.encode(output_packet)
        //print(String(data: outputJson, encoding: .utf8)!)

        return outputJson
    }
    
    
    func decrypter(cypher_text: Data, private_key: SecKey) throws -> String? {
        
        // Retrieve the Json object
        let decoder = JSONDecoder()
        let inputJson = try! decoder.decode(OutputPacket.self, from: cypher_text)
        //print("JSON:", String(data: cypher_text, encoding: .utf8)!)
        
        
        // Get back the two keys encrypted by RSA
        let algorithm: SecKeyAlgorithm = .eciesEncryptionStandardX963SHA512AESGCM //.rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(private_key, .decrypt, algorithm) else {
            print("Problem with the private_key")
            return nil
        }
        
        let data = NSData(base64Encoded: inputJson.cypher_key, options: .ignoreUnknownCharacters)
        
        var error: Unmanaged<CFError>?
        guard let key_conca_data = SecKeyCreateDecryptedData(private_key,
                                                        algorithm,
                                                        data!,
                                                        //inputJson.cypher_key.data(using: String.Encoding.utf8)! as CFData,
                                                        &error) as Data? else {
                                                                throw error!.takeRetainedValue() as Error
        }
        
        let key_conca = String(data: key_conca_data, encoding: String.Encoding.utf8) as String!
        //print("Key conca: ", key_conca)
        
        
        // Split the keys
        let key_not_conca = key_conca?.split(separator: "=")
        let key_hmac = key_not_conca![0] + "="
        let key_aes = key_not_conca![1] + "="
        //print("hmac: ", key_hmac)
        //print("aes: ", key_aes)
        
        
        // Check the tag
        let tag = inputJson.cypher_text.hmac(key: String(key_hmac))
        //print("tag: ", tag)
        
        if (tag != inputJson.tag) {
            print("Error, tags are not equals, data corrupted")
            return nil
        }
        
        
        // Get back the plain text by decrypting aes
        let plain_text = inputJson.cypher_text.aesDecrypt(key: String(key_aes), iv: inputJson.iv, options: kCCOptionPKCS7Padding + kCCModeCBC)
        //print("plain text: ", plain_text)
        
        
        return plain_text
    }
    
    
    // Packet to transfer
    struct OutputPacket: Codable {
        let cypher_text: String
        let cypher_key: String
        let iv: String
        let tag: String
    }
    
}



extension String {
    
    func aesEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
            let data = self.data(using: String.Encoding.utf8),
            let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {
            
            let keyLength              = size_t(kCCKeySizeAES256)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(options)
            
            var numBytesEncrypted :size_t = 0
            
            let cryptStatus = keyData.withUnsafeBytes { keyDataBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(  operation,
                              algoritm,
                              options,
                              keyDataBytes,
                              keyLength,
                              iv,
                              dataBytes,
                              data.count,
                              cryptData.mutableBytes,
                              cryptData.length,
                              &numBytesEncrypted)
                }}
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: [])
                return base64cryptString
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    func aesDecrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
            let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
            let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {
            
            let keyLength              = size_t(kCCKeySizeAES256)
            let operation: CCOperation = UInt32(kCCDecrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(options)
            
            var numBytesEncrypted :size_t = 0
            
            let cryptStatus = keyData.withUnsafeBytes { keyDataBytes in
                CCCrypt(operation,
                        algoritm,
                        options,
                        keyDataBytes,
                        keyLength,
                        iv,
                        data.bytes,
                        data.length,
                        cryptData.mutableBytes,
                        cryptData.length,
                        &numBytesEncrypted)
            }
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
                return unencryptedMessage
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    func hmac(key: String) -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = Int(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = CC_SHA256_DIGEST_LENGTH
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(digestLen))
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyStr!, keyLen, str!, strLen, result)
        
        let digest = stringFromResult(result: result, length: Int(digestLen))
        
        result.deallocate(capacity: Int(digestLen))
        
        return digest
    }
    
    private func stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash)
    }
}


