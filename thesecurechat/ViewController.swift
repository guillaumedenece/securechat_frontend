//
//  ViewController.swift
//  thesecurechat
//
//  Created by Nicolas Chevrier on 20/10/2017.
//  Copyright © 2017 Nicolas Chevrier. All rights reserved.
//

import UIKit
//import Security.framework

extension String {
    
    func aesEncrypt(key:String, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key.data(using: String.Encoding.utf8),
            let data = self.data(using: String.Encoding.utf8),
            let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {
            
            
            let keyLength              = size_t(kCCKeySizeAES128)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(options)
            
            
            
            var numBytesEncrypted :size_t = 0
            
            let cryptStatus = keyData.withUnsafeBytes { keyDataBytes in
                                data.withUnsafeBytes { dataBytes in
                            CCCrypt(operation,
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
            
            let keyLength              = size_t(kCCKeySizeAES128)
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
    
    
}

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
        let tag = "mykey".data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,  //kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String:      2048,                //256,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String:    true,
                 kSecAttrApplicationTag as String: tag]
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
        
            let privateKey = generate_privateKey();

            if(privateKey != nil) {
                
                let publicKey = SecKeyCopyPublicKey(privateKey!);
       
                var error:Unmanaged<CFError>?
                if let cfdata = SecKeyCopyExternalRepresentation(privateKey!, &error) {
                    let data:Data = cfdata as Data
                    print("pri_key: ", data.base64EncodedString())
                }
                
                if let cfdata = SecKeyCopyExternalRepresentation(publicKey!, &error) {
                    let data:Data = cfdata as Data
                    print("pub_key: ", data.base64EncodedString())
                }
                
                if (textField.text == nil) {
                    textField.text = "Default Text"
                }
                
                let cipher_text: Data = encrypter(plain_text: textField.text!, public_key: publicKey!)!
                encryptedLabel.text = cipher_text.base64EncodedString()
                decryptedLabel.text = decrypter(cipher_text: cipher_text, private_key: privateKey!)
            }
    }
    
    // MARK: TEST2
    /*
    enum AESError: Error {
        case KeyError((String, Int))
        case IVError((String, Int))
        case CryptorError((String, Int))
    }
    
    // The iv is prefixed to the encrypted data
    func aesCBCEncrypt(data:Data, keyData:Data) throws -> Data {
        let keyLength = keyData.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
        if (validKeyLengths.contains(keyLength) == false) {
            throw AESError.KeyError(("Invalid key length", keyLength))
        }
        
        let ivSize = kCCBlockSizeAES128;
        let cryptLength = size_t(ivSize + data.count + kCCBlockSizeAES128)
        var cryptData = Data(count:cryptLength)
        
        let status = cryptData.withUnsafeMutableBytes {ivBytes in
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes)
        }
        if (status != 0) {
            throw AESError.IVError(("IV generation failed", Int(status)))
        }
        
        var numBytesEncrypted :size_t = 0
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        let cryptStatus = cryptData.withUnsafeMutableBytes {cryptBytes in
            data.withUnsafeBytes {dataBytes in
                keyData.withUnsafeBytes {keyBytes in
                    CCCrypt(CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes, keyLength,
                            cryptBytes,
                            dataBytes, data.count,
                            cryptBytes+kCCBlockSizeAES128, cryptLength,
                            &numBytesEncrypted)
                }
            }
        }
        
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.count = numBytesEncrypted + ivSize
        }
        else {
            throw AESError.CryptorError(("Encryption failed", Int(cryptStatus)))
        }
        
        return cryptData;
    }
    
    // The iv is prefixed to the encrypted data
    func aesCBCDecrypt(data:Data, keyData:Data) throws -> Data? {
        let keyLength = keyData.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
        if (validKeyLengths.contains(keyLength) == false) {
            throw AESError.KeyError(("Invalid key length", keyLength))
        }
        
        let ivSize = kCCBlockSizeAES128;
        let clearLength = size_t(data.count - ivSize)
        var clearData = Data(count:clearLength)
        
        var numBytesDecrypted :size_t = 0
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        let cryptStatus = clearData.withUnsafeMutableBytes {cryptBytes in
            data.withUnsafeBytes {dataBytes in
                keyData.withUnsafeBytes {keyBytes in
                    CCCrypt(CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            options,
                            keyBytes, keyLength,
                            dataBytes,
                            dataBytes+kCCBlockSizeAES128, clearLength,
                            cryptBytes, clearLength,
                            &numBytesDecrypted)
                }
            }
        }
        
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            clearData.count = numBytesDecrypted
        }
        else {
            throw AESError.CryptorError(("Decryption failed", Int(cryptStatus)))
        }
        
        return clearData;
    }*/


    // MARK: Actions
    @IBAction func setDefaultLabelText(_ sender: UIButton) {
        encryptedLabel.text = "Default Text"
    }
    
    // MARK: TEST1
    
    func decrypter(cipher_text: Data, private_key: SecKey) -> String? {
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(private_key, .decrypt, algorithm) else {
            print("Problem with the private_key")
            return nil
        }

        guard (cipher_text.count == SecKeyGetBlockSize(private_key)) else {
            print("Problem with the length of the cipher text (different from private key)")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(private_key,
                                                        algorithm,
                                                        cipher_text as CFData,
                                                        &error) as Data? else {
                                                            print("Problem with the decryption")
                                                            return nil
        }
        
        return String(data: clearText, encoding: String.Encoding.utf8) as String!
    }
    
    /*
    Use OpenSSL command line prompts to generate 2048-bit RSA public/private key pairs (ECC is bonus).
    
    Develop an application with two modules:
    
    Encrypter:
    
    In this module, the input is a message string and an RSA public key file path (.pem file).
    
    Initialize an RSA object (OAEP only). Your RSA object will load the public key. You then initialize an AES object (be careful of modes of encryption and padding) and generate a 256-bit AES key.
    
    You encrypt the message with your AES (do not forget to prepend the IV).
     
     In addition, you'll generate an HMAC 256-bit key. Run HMAC (SHA 256 is good enough) on your ciphertext to compute the integrity tag. Finally concatenate the keys (AES and HMAC keys) and encrypt the keys with the RSA object. Output the RSA ciphertext, AES ciphertext and HMAC tag (JSON is a good choice to represent the final output. Pay attention to size of each key, value pair).
    
    Decrypter:
    
    In this module, the inputs are:
    a JSON object with keys as: RSA Ciphertext, AES ciphertext, HMAC tag, a file path to an RSA private key
    
    First, initialize an RSA object (OAEP only with 2048 bits key size). Load the private key into your RSA object. Decrypt the RSA Ciphertext (from JSON) and recover a pair of 256-bit keys (one is AES and the other is HMAC).
    
    Run an HMAC (SHA 256 with the HMAC key recovered from above) to re-generate a tag. Compare this tag with the input tag (from JSON). If no match, return failure. Otherwise, continue by initializing an AES key (same as the Encrypter mdoule) and decrypt the AES Ciphertext (from JSON input). Pay attention to IV and padding. You return the recovered plaintext (or failure at any step).
    
    Our approach here is very similar to the principles of PGP (Pretty Good Privacy).
    
    For more info, Google OpenPGP implementation of PGP protocol. Also, you can check out the source of the Open Whisper Systems at github.
    
    We will check your encryption/decryption method calls as well as your integrity check.
    */
    
    // MARK: MyCode
    

    func encrypter(plain_text: String, public_key: SecKey) -> Data? {
        let key_size: Int = 128;
        let block_size = 256;
        
        var error: Int32 = 0;
        var key_aes:Data;
        var key_hmac:Data;
        var initialization_vector:Data;
        
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(public_key, .encrypt, algorithm) else {
            print("Problem with the public_key")
            return nil
        }
        
        guard (plain_text.count < (SecKeyGetBlockSize(public_key)-130)) else {
            print("Problem with the length of the plain text (too loong)")
            return nil
        }
        
        var errorEncrypt: Unmanaged<CFError>?
        guard let cipher_text = SecKeyCreateEncryptedData(public_key,
                                                         algorithm,
                                                         plain_text.data(using: String.Encoding.utf8)! as CFData,
                                                         &errorEncrypt) as Data? else {
                                                            print("Problem with the encryption")
                                                            return nil
        }
        
        // Generation of a random key
        key_aes = Data(count: key_size)
        error = key_aes.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, key_aes.count, mutableBytes)
        }
        
        if error != errSecSuccess {
            print("Problem generating random bytes")
            return nil
        }
        
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
        
        // Cypher Text
        
        
        
        print("key_aes: ", key_aes.base64EncodedString())
        print("IV     : ", initialization_vector.base64EncodedString())
        
        return cipher_text
    }
}

