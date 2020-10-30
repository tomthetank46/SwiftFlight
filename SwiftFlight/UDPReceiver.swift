//
//  UDPReceiver.swift
//  InfiniteControl
//
//  Created by Thomas Hogrefe on 1/15/19.
//  Copyright © 2019 Tom Hogrefe. All rights reserved.
//

import Network
import Foundation

let newConnectAPI = NewConnectAPI()

class UDPReceiver: NSObject {
    
    var connected = false
    
    var broadcastPort: UInt16 = 15000
    var broadcastAddress: String = ""
    var connectAddress = ""
    var connectPort = 0
    
    var timer: Timer?
    
    func networkTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(attemptNetworkSetup), userInfo: nil, repeats: true)
    }
    
    @objc func attemptNetworkSetup() {
        if connectAddress.count > 0 {
            if newConnectAPI.status == ConnectionStates.Looking {
                newConnectAPI.setupNetworkCommunication(ip: connectAddress)
//                if !(tabBarMotionController.newTimer?.isValid ?? false) {
//                    tabBarMotionController.scheduledTimerWithTimeInterval()
//                }
                if newConnectAPI.status.rawValue == ConnectionStates.Connected.rawValue {
                    timer?.invalidate()
                }
                self.udpConnection?.cancel()
            }
        }
    }
    
    func reset() {
        connectAddress = ""
        self.udpListener?.cancel()
    }
    
    var udpListener: NWListener?
    var udpConnection: NWConnection?
    var backgroundQueueUdpListener   = DispatchQueue.main
    
    func findUDP() {
        let params = NWParameters.udp
        udpListener = try? NWListener(using: params, on: 15000)
        
        udpListener?.service = NWListener.Service.init(type: "_flybywire._udp")
        
        self.udpListener?.stateUpdateHandler = { update in
            print("update")
            print(update)
            switch update {
            case .failed:
                self.endConnection()
            default:
                print("default update")
            }
        }
        self.udpListener?.newConnectionHandler = { connection in
            print("connection")
            print(connection)
            self.createConnection(connection: connection)
            self.udpListener?.cancel()
        }
        udpListener?.start(queue: self.backgroundQueueUdpListener)
        newConnectAPI.status = ConnectionStates.Looking
    }
    
    func createConnection(connection: NWConnection) {
        self.udpConnection = connection

            self.udpConnection?.stateUpdateHandler = { (newState) in
                switch (newState) {
                case .ready:
                    print("ready")
//                    self.send()
                    self.receive()
                case .setup:
                    print("setup")
                case .cancelled:
                    print("cancelled")
                    print(newState)
                case .preparing:
                    print("Preparing")
                default:
                    print("waiting or failed")

                }
            }
            self.udpConnection?.start(queue: .global())
    }
    
    func endConnection() {
        self.udpConnection?.cancel()
    }
    
//    func send() {
//        self.udpConnection?.send(content: "Test message".data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
//            print(NWError)
//        })))
//    }

    func receive() {
        self.udpConnection?.receiveMessage { (data, context, isComplete, error) in
            print("Got it")
            print(data as Any)
            do {
                let jsonDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any]
                
                if (jsonDictionary["Addresses"] != nil) {
                    if (jsonDictionary["Addresses"] is NSArray) {
                        let addresses = jsonDictionary["Addresses"] as! NSArray
                        
                        for i in addresses {
                            let ipAddress:String = i as! String
                            if (ipAddress.range(of: "^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", options: .regularExpression) != nil) {
                                self.connectAddress = ipAddress
                            }
                        }
                        
                        print(addresses)
                        self.udpConnection?.cancel()
    //                        print(ipAddress)
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
}
