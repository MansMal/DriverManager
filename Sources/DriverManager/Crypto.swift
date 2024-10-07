//
//  Crypto.swift
//  Mryde
//
//  Created by Malek Mansour on 16/02/2024.
//

import Foundation
import CryptoSwift
import CryptoKit

public struct Crypto {
    
    static func ecbEncrypt(inputData: Data) -> Data? {
        let key = KeychainService.loadStringWithKey(Constants.encryptionKey) ?? Constants.staticCryptoKey
        guard let aes = try? AES(key: key.bytes, blockMode: ECB()) else { return nil }
        let encryptedBytes = try? aes.encrypt(inputData.bytes)
        let encryptedData = Data(encryptedBytes!).base64EncodedData()
//        dump("encrypted: " +  (String(data: encryptedData, encoding: .utf8) ?? "error ecbEnc") + "  key: "+key)
        return encryptedData
    }
    
    static func ecbDecrypt(input: Data) -> Data? {
        let key = KeychainService.loadStringWithKey(Constants.encryptionKey) ?? Constants.staticCryptoKey
        let receivedString = String(data: input, encoding: .utf8)
        var decryptedData: Data? = nil
        
        if let replaced = receivedString?.replacingOccurrences(of: "\n", with: ""),
           let inputData = Data(base64Encoded: replaced),
           let aesDec = try? AES(key: key.bytes, blockMode: ECB()),
           let decryptedBytes = try? aesDec.decrypt(inputData.bytes) {
            decryptedData = Data(decryptedBytes)
//            dump("decrypted: " + (String(data: decryptedData!, encoding: .utf8) ?? "ecb error") + " key:" + key)
            return decryptedData
        }
        return nil
    }
    
    static func ecbStaticEncrypt(inputData: Data) -> Data? {
        let key = Constants.staticCryptoKey
        guard let aes = try? AES(key: key.bytes, blockMode: ECB()) else { return nil }
        let encryptedBytes = try? aes.encrypt(inputData.bytes)
        let encryptedData = Data(encryptedBytes!).base64EncodedData()
//        dump("encrypted: " +  (String(data: encryptedData, encoding: .utf8) ?? "error ecbEnc") + "  key: "+key)
        return encryptedData
    }
    
    static func ecbStaticDecrypt(input: Data) -> Data? {
        let key = Constants.staticCryptoKey
        let receivedString = String(data: input, encoding: .utf8)
        var decryptedData: Data? = nil
        
        if let replaced = receivedString?.replacingOccurrences(of: "\n", with: ""),
           let inputData = Data(base64Encoded: replaced),
           let aesDec = try? AES(key: key.bytes, blockMode: ECB()),
           let decryptedBytes = try? aesDec.decrypt(inputData.bytes) {
            decryptedData = Data(decryptedBytes)
//            dump("decrypted: " + (String(data: decryptedData!, encoding: .utf8) ?? "ecb error") + " key:" + key)
            return decryptedData
        }
        return nil
    }
}

extension SymmetricKey {
  init(string keyString: String, size: SymmetricKeySize = .bits256) throws {
    guard var keyData = keyString.data(using: .utf8) else {
      print("Could not create base64 encoded Data from String.")
      throw CryptoKitError.incorrectParameterSize
    }
    
    let keySizeBytes = size.bitCount / 8
    keyData = keyData.subdata(in: 0..<keySizeBytes)
    
    guard keyData.count >= keySizeBytes else { throw CryptoKitError.incorrectKeySize }
    self.init(data: keyData)
  }
}
