//
//  SawtoothClient.swift
//  MsgHash
//
//  Created by Anton Betsun on 6/15/18.
//  Copyright © 2018 Anton Betsun. All rights reserved.
//

import Foundation
import SwiftCBOR
import SwiftProtobuf
import CommonCrypto
import secp256k1
import BitcoinKit

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

 struct SawtoothBatchList {
    let publicKey: String
    var time: String
    let txId: String
    let batchId: String
    let batchListData: Data
    
init(publicKey: String, txId: String, batchId: String, batchListData: Data) {
        self.publicKey = publicKey
        self.txId = txId
        self.batchId = batchId
        self.batchListData = batchListData
        let date = Date()
        let calendar = Calendar.current
        var day, month, year, hour, minute: String
        day = ""
        month = ""
        year = ""
        hour = ""
        minute = ""
        if calendar.component(.day, from: date) < 10 {
            day += "0"
        }
        day += String(calendar.component(.day, from: date))
        if calendar.component(.month, from: date) < 10 {
            month += "0"
        }
        month += String(calendar.component(.month, from: date))
        year = String(calendar.component(.year, from: date))
        
        if calendar.component(.hour, from: date) < 10 {
            hour += "0"
        }
        hour += String(calendar.component(.hour, from: date))
        if calendar.component(.minute, from: date) < 10 {
            minute += "0"
        }
        minute += String(calendar.component(.minute, from: date))
        let currentdate = day + "/" + month + "/" + year + " " + hour + ":" + minute
        self.time = currentdate
    }
}

struct SawtoothKeypair {
    let privateKey: PrivateKey
    let publicKey: String
    
    init() {
        self.privateKey = PrivateKey(network: .mainnet)
        let uncompressed = self.privateKey.publicKey().description
        var result = uncompressed.prefix(66).suffix(64)
        let odd = ((Int(uncompressed.suffix(1), radix: 16)!)%2 == 1)
        if odd {
            result = "03" + result
        }
        else {
            result = "02" + result
        }
        self.publicKey = String(result)
    }
    
    init(wif: String) {
        do { try self.privateKey = PrivateKey(wif: wif) } catch {
            print("ERROR while restoring keypair from wif")
            self.privateKey = PrivateKey(network: .mainnet)
        }
        let uncompressed = self.privateKey.publicKey().description
        var result = uncompressed.prefix(66).suffix(64)
        let odd = ((Int(uncompressed.suffix(1), radix: 16)!)%2 == 1)
        if odd {
            result = "03" + result
        }
        else {
            result = "02" + result
        }
        self.publicKey = String(result)
    }
    
    public func toWif() -> String {
        return self.privateKey.toWIF()
    }
}

class SawtoothClient {
    private var errorList = ""
    public let familyName: String
    public let familyVersion: String
    public let keyPair: SawtoothKeypair
    
    public init(familyName: String, familyVersion: String, keyPair: SawtoothKeypair) {
        self.familyName = familyName
        self.familyVersion = familyVersion
        self.keyPair = keyPair
    }
    
    public func getAddress(seed: String) -> String {
        let hash = sha512Hex(string: seed)
        let prefix = String(sha512Hex(string: familyName).prefix(6))
        let subhash = String(hash.prefix(64))
        return prefix + subhash
    }
    
    public func getBatchList(payload: Data, address: String) -> SawtoothBatchList {
        var txHeader = Sawtooth_TransactionHeader()
        txHeader.batcherPublicKey = keyPair.publicKey
        txHeader.dependencies = []
        txHeader.familyName = familyName
        txHeader.familyVersion = familyVersion
        txHeader.inputs = [address]
        txHeader.outputs = [address]
        print("Address: " + address)
        txHeader.nonce = String(arc4random())
        txHeader.payloadSha512 = sha512Hex(data: payload)!
        txHeader.signerPublicKey = keyPair.publicKey
        var txHeaderData: Data = Data()
        do { try txHeaderData = txHeader.serializedData() }
        catch { errorList += ("Error: \(error)" + "\n")}
        let txHeaderSignature = sign(data: txHeaderData)
        
        var tx = Sawtooth_Transaction()
        tx.header = txHeaderData
        tx.headerSignature = txHeaderSignature
        tx.payload = payload
        
        var batchHeader = Sawtooth_BatchHeader()
        batchHeader.signerPublicKey = keyPair.publicKey
        batchHeader.transactionIds = [tx.headerSignature]
        var batchHeaderData = Data()
        do { try batchHeaderData = batchHeader.serializedData() }
        catch { errorList += ("Error: \(error)" + "\n")}
        let batchHeaderSignature = sign(data: batchHeaderData)
        
        var batch = Sawtooth_Batch()
        do { try batch.header = batchHeader.serializedData() }
        catch { errorList += ("Error: \(error)" + "\n")}
        batch.headerSignature = batchHeaderSignature
        batch.transactions = [tx]
        
        var batchList = Sawtooth_BatchList()
        batchList.batches = [batch]
        var batchListData: Data = Data()
        do { try batchListData = batchList.serializedData() }
        catch { errorList += ("Error: \(error)" + "\n")}
        
        return SawtoothBatchList(publicKey: keyPair.publicKey, txId: txHeaderSignature, batchId: batchHeaderSignature, batchListData: batchListData)
    }
    
    
    
    private func sign(data: Data) -> String {
        let hash = Crypto.sha256(data)
        var signedHash = Data()
        do { try signedHash = Crypto.signCompact(hash, privateKey: keyPair.privateKey)
        } catch { errorList += ("Error: \(error)" + "\n") }
        
        
        return signedHash.hexEncodedString()
    }
    
    func sha512Hex(string: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        if let data = string.data(using: String.Encoding.utf8) {
            let value =  data as NSData
            CC_SHA512(value.bytes, CC_LONG(data.count), &digest)
        }
        var digestHex = ""
        for index in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        return digestHex
    }
    
    func sha512Hex(data:Data) -> String? {
        var hashData = Data(count: Int(CC_SHA512_DIGEST_LENGTH))
        _ = hashData.withUnsafeMutableBytes {digestBytes in
            data.withUnsafeBytes {messageBytes in
                CC_SHA512(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        return hashData.map { String(format: "%02hhx", $0) }.joined()
    }
}
