//
//  UDPReceiver.swift
//  InfiniteControl
//
//  Created by Thomas Hogrefe on 1/15/19.
//  Copyright © 2019 Tom Hogrefe. All rights reserved.
//

import Network
import Foundation

public class UDPReceiver {
    
    public let connectAPI: ConnectAPI?
    public var connected: Bool
    var connectAddress: String
    
    public init(API: ConnectAPI) {
        self.connectAPI = API
        self.connected = false
        self.connectAddress = ""
    }
    
    var timer: Timer?
    
    public func networkTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.attemptNetworkSetup), userInfo: nil, repeats: true)
    }
    
    @objc internal func attemptNetworkSetup() {
        if connectAddress.count > 0 {
            if connectAPI?.status == ConnectionStates.Looking {
                connectAPI?.setupNetworkCommunication(ip: connectAddress)
                self.udpConnection?.cancel()
            }
            if connectAPI?.status == ConnectionStates.Connected {
                timer?.invalidate()
            }
        }
    }
    
    public func reset() {
        connectAddress = ""
        self.udpListener?.cancel()
    }
    
    var udpListener: NWListener?
    var udpConnection: NWConnection?
    var backgroundQueueUdpListener   = DispatchQueue.main
    
    public func findUDP() {
        let params = NWParameters.udp
        udpListener = try? NWListener(using: params, on: 15000)
        
        udpListener?.service = NWListener.Service.init(type: "_flybywire._udp")
        
        self.udpListener?.stateUpdateHandler = { update in
            switch update {
            case .failed:
                self.endConnection()
            default:
                print("default update")
            }
        }
        self.udpListener?.newConnectionHandler = { connection in
            self.createConnection(connection: connection)
            self.udpListener?.cancel()
        }
        udpListener?.start(queue: self.backgroundQueueUdpListener)
        connectAPI?.status = ConnectionStates.Looking
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
        self.networkTimer()
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
                        
                        self.udpConnection?.cancel()
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
}
