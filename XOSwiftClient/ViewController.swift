//
//  ViewController.swift
//  XOSwiftClient
//
//  Created by Anton Betsun on 6/28/18.
//  Copyright © 2018 Anton Betsun. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftCBOR
import BitcoinKit

extension String {
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func hexadecimal() -> Data? {
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
}

struct ByteEncoding: ParameterEncoding {
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        urlRequest.httpBody = data
        return urlRequest
    }
}

class ViewController: UIViewController {
    let sawtooth = SawtoothClient(familyName: "xo", familyVersion: "1.0", keyPair: SawtoothKeypair())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var nodeUrlField: UITextField!
    @IBOutlet weak var gameNameField: UITextField!
    
    @IBAction func createButton(_ sender: Any) {
        let url = nodeUrlField.text!
        let endPoint = "http://" + url + "/"
        let name = gameNameField.text!
        let action = "create"
        let space = ""
        let payload = Data((name + "," + action + "," + space).encode())
        let batches = sawtooth.getBatchList(payload: payload, address: sawtooth.getAddress(seed: name))
        postBatchList(batches, nodeURL: endPoint) { response in
            
        }
        checkBatch(batches, nodeURL: endPoint, wait: 1) { response in
            
        }
    }
    
    @IBAction func connectButton(_ sender: Any) {
        
    }
    
    @IBAction func xo1(_ sender: Any) {
        take(space: 1)
    }
    @IBAction func xo2(_ sender: Any) {
        take(space: 2)
    }
    @IBAction func xo3(_ sender: Any) {
        take(space: 3)
    }
    @IBAction func xo4(_ sender: Any) {
        take(space: 4)
    }
    @IBAction func xo5(_ sender: Any) {
        take(space: 5)
    }
    @IBAction func xo6(_ sender: Any) {
        take(space: 6)
    }
    @IBAction func xo7(_ sender: Any) {
        take(space: 7)
    }
    @IBAction func xo8(_ sender: Any) {
        take(space: 8)
    }
    @IBAction func xo9(_ sender: Any) {
        take(space: 9)
    }
    
    func take(space: Int) {
        
    }
    
    func postBatchList(_ batchList: SawtoothBatchList, nodeURL: String, completion: @escaping (String?) -> Void) {
        let username = ""
        let password = ""
        let authString = username + ":" + password
        let authEncoded = authString.encode()
        let base64Encoded = Data(authEncoded).base64EncodedString()
        let authHeader = "Basic " + (base64Encoded)
        let headers: HTTPHeaders = ["content-type": "application/octet-stream", "authorization":authHeader]
        let url = nodeURL + "batches"
        Alamofire.request(url, method: .post, parameters: nil, encoding: ByteEncoding(data: batchList.batchListData), headers: headers).responseJSON { response in
            if response.data != nil {
                do {
                    let json = try JSON(data: response.data!)
                    /*let link = json["link"].string
                    if (link != nil) {
                        self.checkBatch(batchList, nodeURL: nodeURL, wait: 0, completion: completion)
                    }
                    else {
                        completion ("Error. Can't pin message...")
                        print("Error. Can't pin message...")
                    }*/
                    print(json)
                }
                catch {
                    print(error)
                }
                return
            }
        }
    }
    
    func checkBatch(_ batchList: SawtoothBatchList, nodeURL: String, wait: Int, completion: @escaping (String?) -> Void) {
        let username = ""
        let password = ""
        let authString = username + ":" + password
        let authEncoded = authString.encode()
        let base64Encoded = Data(authEncoded).base64EncodedString()
        let authHeader = "Basic " + (base64Encoded)
        let headers: HTTPHeaders = ["content-type": "application/octet-stream", "authorization":authHeader]
        let url = nodeURL + "batch_statuses?id=" + batchList.batchId + "&wait=" + String(wait)
        Alamofire.request(url, headers: headers).responseJSON { response in
            if response.data != nil {
                do {
                    let json =  try JSON(data: response.data!)
//                    let status = json["data"][0]["status"].string
//                    if status != nil {
//                        if status == "COMMITTED" {
//                            completion("Message is pinned!")
//                        }
//                        if status == "INVALID" {
//                            let errorMessage = json["data"][0]["invalid_transactions"][0]["message"].string
//                            print(errorMessage!)
//                            completion(errorMessage!)
//                        }
//                        if status == "UNKNOWN" {
//                            if wait == 3 {
//                                print("Something went wrogn, can't pin message.")
//                                completion("Something went wrogn, can't pin message.")
//                            }
//                            else {
//                                let waitInc = wait + 1
//                                self.checkBatch(batchList, nodeURL: nodeURL, wait: waitInc, completion: completion)
//                            }
//                        }
//                    }
                    print(json)
                }
                catch {
                    print(error)
                }
                return
            }
        }
    }
}

