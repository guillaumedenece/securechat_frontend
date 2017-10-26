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
            [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,  //kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String:      2048,                //256,
            //[kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
             //kSecAttrKeySizeInBits as String:      256,
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
        
            let privateKey = generate_privateKey();

            if(privateKey != nil) {
                
                let publicKey = SecKeyCopyPublicKey(privateKey!);
                
                print("block size priv: ", SecKeyGetBlockSize(privateKey!))
                print("block size priv: ", SecKeyGetBlockSize(publicKey!))
       
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
                
                
                var cipher_text: Data? = nil;
                
                do {
                     try cipher_text = encrypter(plain_text: textField.text!, public_key: publicKey!)!
                }
                catch {
                    print("Error \(error)")
                }
                
                encryptedLabel.text = cipher_text?.base64EncodedString()
                
                do {
                    try decryptedLabel.text = decrypter(cypher_text: cipher_text!, private_key: privateKey!)
                }
                catch {
                    print("Error \(error)")
                }
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
        //let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) //
        
        print("error: ", error)
        if error != errSecSuccess {
            print("Problem generating random bytes")
            return nil
        }
        

       
        str_key_aes = key_aes.base64EncodedString(options: [])
        //str_key_aes = init?(data: key_aes, encoding: String.Encoding.utf8)
        //str_key_aes = key_aes.string(as: String.Encoding.utf8)!
        print("STRING AES: ", str_key_aes)
        //print("String lenght: ", str_key_aes.count)
        //print("key size: ", key_aes.count)
        
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
        //nsdataStr = NSData.init(data: initialization_vector)
        //let str_initialization_vector = nsdataStr.description.trimmingCharacters(in: CharacterSet.alphanumerics).replacingOccurrences(of: " ", with: "")
        print("STR_IV: ", str_initialization_vector)
        
        // Cypher Text with AES
        let cypher_text = plain_text.aesEncrypt(key: str_key_aes, iv: str_initialization_vector, options: kCCOptionPKCS7Padding + kCCModeCBC)
        
        /*
    
            let cypher_text    = NSMutableData(length: Int((plain_text.count)) + kCCBlockSizeAES128)

        
            var numBytesEncrypted :size_t = 0
        
            let cryptStatus = key_aes.withUnsafeBytes { keyDataBytes in
                initialization_vector.withUnsafeBytes { ivDataBytes in
                    CCCrypt(  UInt32(kCCEncrypt),
                              UInt32(kCCAlgorithmAES128),
                              UInt32(kCCOptionPKCS7Padding + kCCModeCBC),
                              keyDataBytes,
                              kCCKeySizeAES256,
                              ivDataBytes,
                              plain_text,
                              plain_text.count,
                              cypher_text!.mutableBytes,
                              cypher_text!.length,
                              &numBytesEncrypted)
                }}
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cypher_text?.length = Int(numBytesEncrypted)
                //let base64cryptString = cypher_text?.base64EncodedString(options: [])
                //return base64cryptString
            }
            else {
                return nil
            }*/
        print("CYPHERTEXT:", cypher_text)
        
        
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
        //nsdataStr = NSData.init(data: key_hmac)
        //str_key_hmac = nsdataStr.description.trimmingCharacters(in: CharacterSet.alphanumerics).replacingOccurrences(of: " ", with: "")
        
        // Tag with HMAC
        let tag = cypher_text?.hmac(key: str_key_hmac)
        //let tag = cypher_text?.hmac(key: str_key_hmac)
        print("TAG:", tag)
        
        // Concatenate keys
        print("key_hmac: ", str_key_hmac)
        print("key_aes: ", str_key_aes)
        let key_conca = str_key_hmac + str_key_aes
        //let key_conca = "VOICI_LA_CLEF_CONCA"
            //"012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
            //str_key_hmac + str_key_aes
        
        print("key conca: ", key_conca)
        
        print("the lengths")
        print("hmac: ", key_hmac)
        print("aes: ", key_aes)
        print("conca: ", key_conca.count)
        
        // RSA
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(public_key, .encrypt, algorithm) else {
            print("Problem with the public_key")
            return nil
        }
        
        /*
        guard (plain_text.count < (SecKeyGetBlockSize(public_key)-130)) else {
            print("Problem with the length of the plain text (too loong)")
            return nil
        }
        */
        
        var errorEncrypt: Unmanaged<CFError>?
        guard let cypher_key = SecKeyCreateEncryptedData(public_key,
                                                          algorithm,
                                                          key_conca.data(using: String.Encoding.utf8)! as CFData,
                                                          &errorEncrypt) as Data? else {
                                                            throw errorEncrypt!.takeRetainedValue() as Error
        }
        //nsdataStr = NSData.init(data: cypher_key)
        //let str_cypher_key = nsdataStr.description.trimmingCharacters(in: CharacterSet.alphanumerics).replacingOccurrences(of: " ", with: "")
        let str_cypher_key = cypher_key.base64EncodedString(options: [])
        
        // Create a JSON
        print(cypher_text)
        print(tag)
        
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
        
        // Get the two keys encrypted by RSA
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(private_key, .decrypt, algorithm) else {
            print("Problem with the private_key")
            return nil
        }
        
        /*
        guard ((inputJson.cypher_key.data(using: String.Encoding.utf8)! as Data).count == SecKeyGetBlockSize(private_key)) else {
            print("Problem with the length of the cypher key (different from private key)")
            return nil
        }*/
        
        //Data cypher_keyData = inputJson.cypher_key.
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
        print("Key conca: ", key_conca)
        
        var i = 0
        let key_not_conca = key_conca?.split(separator: "=")
        let key_hmac = key_not_conca![0] + "="
        let key_aes = key_not_conca![1] + "="
        //let key_aes = key_conca?.spli
        print("hmac: ", key_hmac)
        print("aes: ", key_aes)
        
        
        // Check the tag
        //let key_hmac = key_hmac.base64EncodedString(options: [])
        //nsdataStr = NSData.init(data: key_hmac)
        //str_key_hmac = nsdataStr.description.trimmingCharacters(in: CharacterSet.alphanumerics).replacingOccurrences(of: " ", with: "")
        
        print("Cypher_text received: ", inputJson.cypher_text)

        let tag = inputJson.cypher_text.hmac(key: String(key_hmac))
        
        print("tag2: ", tag)
        if (tag != inputJson.tag) {
            print("Error, tags are not equals, data corrupted")
            return nil
        }
        
        let plain_text = inputJson.cypher_text.aesDecrypt(key: String(key_aes), iv: inputJson.iv, options: kCCOptionPKCS7Padding + kCCModeCBC)
        
        
        
        // Recover plain text with AES
        //(String(data: cipher_text, encoding: String.Encoding.utf8) as String!).aesDecrypt(key: private_key, iv: <#T##String#>, options: <#T##Int#>)
        
        print("plain text: ", plain_text)
        
        return plain_text
    }
    
    struct OutputPacket: Codable {
        let cypher_text: String
        let cypher_key: String
        let iv: String
        let tag: String
    }
    
}

extension Data {
    
    var utf8String: String? {
        return string(as: .utf8)
    }
    
    func string(as encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
    
}
