//
//  ConnectAPI.swift
//  InfiniteControl
//
//  Created by Thomas Hogrefe on 1/13/20.
//  Copyright © 2020 Tom Hogrefe. All rights reserved.
//

import UIKit
import SwiftSocket
import OSLog

public struct StateInfo {
    public let path: String?
    public let type: Int?
    public let ID: Int32?
}

public class State {
    public var path: String?
    public var value: Any?
    public var ID: Int32?
    
    init(path: String, value: AnyObject, ID: Int32) {
        self.path = path
        self.value = value
        self.ID = ID
    }
}

public class CommandInfo {
    public var path: String?
    public var ID: Int32?
    
    init(path: String, ID: Int32) {
        self.path = path
        self.ID = ID
    }
}

public enum ConnectionStates: String {
    case Looking = "Connecting to Infinite Flight..."
    case Connected = "Connected to Infinite Flight!"
    case Lost = "Connection Lost."
}

@available(iOS 14.0, *)
public class ConnectAPI: NSObject {

    let debug = false
    
    let logger = Logger()
    
    public var status = ConnectionStates.Lost
    
    public let CommandBase: Int32 = 0x100000
    
    public var CommandsDict: Dictionary<String, CommandInfo> = [:]
    private var StateInfoByID: Dictionary<Int32, StateInfo> = [:]
    public var stateInfo: [StateInfo] = []
    public var StateInfoDict: Dictionary<String, StateInfo> = [:]
    public var States: [State] = []
    public var StateByID: Dictionary<Int32, State> = [:]
    
    private var requestedStates: [TimedState] = []  // queue, keeps track of when states are requested
    private var updatedStates: Dictionary<Int32, Int> = [:]    // track when states are updated
    // These let us discard outdated info later. We'll want to ignore any state info we've edited since requesting the info.
    
    let queue: DispatchQueue = DispatchQueue(label: "api-queue", qos: .userInteractive)
    
    public func refreshAllValues() {
        if !stateInfo.isEmpty {
            for item in stateInfo {
                //don't get states from other aircraft
                let pathArray = item.path?.split(separator: "/")
                if !((pathArray?[0] == "aircraft") && ((pathArray?[1].count)! > 1)) {
                    // don't get sounds
                    if !(item.type == -1) {
                        getState(ID: item.ID!)
                    }
                }
            }
        }
    }
    
    var client:TCPClient?
    var connectPort = 10112

    var inputStream: InputStream!
    var outputStream: OutputStream!

    internal func setupNetworkCommunication(ip:String) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, ip as CFString, 10112, &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        inputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        inputStream.open()
        outputStream.open()
        status = ConnectionStates.Looking
    }
    
    public func updateState(commandID: Int32, value: Any) {
        StateByID[commandID]?.value = value
        self.updatedStates[commandID] = Int(1000 * Date().timeIntervalSince1970)
    }
    
    public func setState(commandID: Int32, value: Bool) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendBool(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func setState(commandID: Int32, value: Int32) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendInt(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func setState(commandID: Int32, value: Float) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendFloat(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func setState(commandID: Int32, value: String) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendString(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func setState(commandID: Int32, value: Double) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendDouble(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func setState(commandID: Int32, value: Int64) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendLong(val: value)
        }
        updateState(commandID: commandID, value: value)
    }
    
    public func getState(ID: Int32) {
        queue.async {
            self.sendInt(val: ID)
            self.sendBool(val: false)
        }
        self.requestedStates.append(TimedState(id: ID))
    }
    
    public func sendCommand(commandID: Int32) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: false)
        }
    }
    
    public func sendCommand(commandID: Int32, value: Int32) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendInt(val: value)
        }
    }
    
    public func sendCommand(commandID: Int32, value: Bool) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendBool(val: value)
        }
    }
    
    public func sendCommand(commandID: Int32, value: String) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            //self.sendString(val: value)
            self.sendJSON(val: value)
        }
    }
    
    public func sendCommand(commandID: Int32, value: Float) {
        queue.async {
            self.sendInt(val: commandID)
            self.sendBool(val: true)
            self.sendFloat(val: value)
        }
    }
    
    private func sendJSON(val: String) {
        var jsonData = val
        
        let data = Data(bytes: &jsonData, count: MemoryLayout.size(ofValue: jsonData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendBool(val: Bool) {
        var boolData = val
        
        let data = Data(bytes: &boolData, count: MemoryLayout.size(ofValue: boolData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendInt(val: Int32) {
        var intData = val
        
        let data = Data(bytes: &intData, count: MemoryLayout.size(ofValue: intData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendFloat(val: Float) {
        var floatData = val
        
        let data = Data(bytes: &floatData, count: MemoryLayout.size(ofValue: floatData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendString(val: String) {
        var strData = val
        
        let data = Data(bytes: &strData, count: MemoryLayout.size(ofValue: strData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendDouble(val: Double) {
        var doubleData = val
        
        let data = Data(bytes: &doubleData, count: MemoryLayout.size(ofValue: doubleData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func sendLong(val: Int64) {
        var longData = val
        
        let data = Data(bytes: &longData, count: MemoryLayout.size(ofValue: longData))
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: Byte.self) else {
                logger.error("Error sending command: \(val)")
                return
            }
            self.outputStream.write(pointer, maxLength: data.count)
        }
    }
    
    private func readInt(inputStream: InputStream) -> Int32 {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        inputStream.read(data, maxLength: 4)
        
        let value = data.withMemoryRebound(to: Int32.self, capacity: 1) { $0
        }.pointee
        
        data.deinitialize(count: 4)
        data.deallocate()

        return value
    }
    
    private func readDouble(inputStream: InputStream) -> Double {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
        inputStream.read(data, maxLength: 8)
        
        let value = data.withMemoryRebound(to: Double.self, capacity: 1) { $0
        }.pointee
        
        data.deinitialize(count: 8)
        data.deallocate()

        return value
    }
    
    private func readFloat(inputStream: InputStream) -> Float {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        inputStream.read(data, maxLength: 4)
        
        let value = data.withMemoryRebound(to: Float.self, capacity: 1) { $0
        }.pointee
        
        data.deinitialize(count: 4)
        data.deallocate()

        return value
    }
    
    private func readLong(inputStream: InputStream) -> Int64 {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
        inputStream.read(data, maxLength: 8)
        
        let value = data.withMemoryRebound(to: Int64.self, capacity: 1) { $0
        }.pointee
        
        data.deinitialize(count: 8)
        data.deallocate()

        return value
    }
    
    private func readBoolean(inputStream: InputStream) -> Bool {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        inputStream.read(data, maxLength: 1)
        
        let value = data.withMemoryRebound(to: Bool.self, capacity: 1) { $0
        }.pointee
        
        data.deinitialize(count: 1)
        data.deallocate()

        return value
    }
    
    private func readString(inputStream: InputStream) -> AnyObject {
        let size = readInt(inputStream: inputStream)
        
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
        var totalRead = 0
        var sizeToRead = Int(size)
        logger.debug("size to read \(sizeToRead)")
        
        while totalRead != Int(size) {
            let read = inputStream.read(&data[totalRead], maxLength: sizeToRead)
            logger.debug("Read \(read) (out of \(sizeToRead)).")
            sizeToRead -= read
            totalRead += read
        }
        
        let dataArray: Data = Data(bytes: data, count: Int(size))
        let stringArray = String(data: dataArray, encoding: String.Encoding.utf8)
        
        data.deinitialize(count: Int(size))
        data.deallocate()
        return stringArray as AnyObject
    }
    
    func readManifest(inputStream: InputStream) {
        logger.info("Reading manifest...")
        let str = readString(inputStream: inputStream)
        
        let lines = str.components(separatedBy: "\n")
        logger.debug("States: \(lines).")
        
        for i in 0...lines.count-1 {
            let items = lines[i].components(separatedBy: ",")
            
            if items.count == 3 {
                let stateID: Int32 = Int32(items[0])!
                
                if (stateID & CommandBase) == CommandBase {
                    CommandsDict[items[2]] = CommandInfo(path: items[2], ID: stateID)
                } else {
                    StateInfoDict[items[2]] = StateInfo(path: items[2], type: Int(items[1])!, ID: stateID)
                    stateInfo.append(StateInfo(path: items[2], type: Int(items[1]), ID: stateID))
                    StateInfoByID[stateID] = StateInfo(path: items[2], type: Int(items[1]), ID: stateID)//stateInfo[i]
                    
                    let stateData = State(path: items[2], value: "" as AnyObject, ID: stateID)
                    States.append(stateData)
                    StateByID[stateID] = stateData
                }
            }
        }
        stateInfo.sort {$0.ID! < $1.ID!}
        refreshAllValues()
    }
    
    public func getID(str: String) -> Int32 {
        if let ID = StateInfoDict[str]?.ID {
            return ID
        }
        if let ID = CommandsDict[str]?.ID {
            return ID
        }
        return -1
    }
    
    public func getStateByString(str: String) {
        getState(ID: getID(str: str))
    }
    
    public func getStateValue(str: String) -> Any? {
        if let id = StateInfoDict[str]?.ID {
            return StateByID[id]?.value ?? nil
        }
        return nil
    }
    
    public func isConnected() -> Bool {
        if status == ConnectionStates.Connected {
            return true
        }
        return false
    }
    
    public func closeConnection() {
        if status == ConnectionStates.Connected {
            inputStream.close()
            outputStream.close()
            status = ConnectionStates.Lost
            
            CommandsDict.removeAll()
            StateInfoByID.removeAll()
            stateInfo.removeAll()
            StateInfoDict.removeAll()
            States.removeAll()
            StateByID.removeAll()
            
            requestedStates.removeAll()
            updatedStates.removeAll()
        }
    }
    
}

@available(iOS 14.0, *)
extension ConnectAPI: StreamDelegate {
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            logger.debug("new message received: bytes")
            readCommand(stream: aStream as! InputStream)
        case .endEncountered:
            logger.info("new message received: end")
        case .errorOccurred:
            logger.debug("error occured")
            self.closeConnection()
        case .hasSpaceAvailable:
            logger.info("has space available")
        case .openCompleted:
            logger.info("open completed")
            self.status = ConnectionStates.Connected
            self.sendCommand(commandID: -1)
        default:
            logger.info("some other event...")
        }
    }
    
    private func readCommand(stream: InputStream) {
        
        let commandID = readInt(inputStream: stream)
        let dataLength = readInt(inputStream: stream)
        
        logger.debug("commandID \(commandID), length \(dataLength)")
        
        if commandID == -1 {
            readManifest(inputStream: inputStream)
        } else {
            
            guard let expectedCommandIndex: Int = requestedStates.firstIndex(where: { $0.id == commandID }) else {
                closeConnection()       // received an unrequested state
                return
            }
            
            let expectedCommand: TimedState = requestedStates[expectedCommandIndex]
            requestedStates.remove(at: expectedCommandIndex)
            
            let hasBeenUpdated = updatedStates[commandID] ?? 0 >= (expectedCommand.time - 200)
            // check if the value has been updated locally since requesting it, or within 200 ms
            // before requesting. this allows Infinite Flight some time to process the update
            
            let stateInfo = StateInfoByID[commandID]
            let state = StateByID[commandID]
            
            logger.debug("ID \(String(describing: stateInfo?.ID)) Type \(self.getTypeFromInt(int: (stateInfo?.type) ?? -1)), State \(String(describing: stateInfo?.path))")
            
            if stateInfo?.type == 0 {    //bool
                let value = readBoolean(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(value)")
                if !hasBeenUpdated {
                    state?.value = value as Bool
                }
                
            } else if stateInfo?.type == 1 {    //int
                let value = readInt(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(value)")
                if !hasBeenUpdated {
                    state?.value = value as Int32
                }
                
            } else if stateInfo?.type == 2 {    //float
                let value = readFloat(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(value)")
                if !hasBeenUpdated {
                    state?.value = value as Float
                }
                
            } else if stateInfo?.type == 3 {    //double
                let value = readDouble(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(value)")
                if !hasBeenUpdated {
                    state?.value = value as Double
                }
                
            } else if stateInfo?.type == 4 {    //string
                let value = readString(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(String(describing: value))")
                if !hasBeenUpdated {
                    state?.value = "\(value)"
                }
                
            } else if stateInfo?.type == 5 {    //long
                let value = readLong(inputStream: inputStream)
                logger.debug("\(String(describing: stateInfo?.path)): \(value)")
                if !hasBeenUpdated {
                    state?.value = value as Int64
                }
            } else if stateInfo?.type == -1 { //sound?
//                let value = readString(inputStream: inputStream)
//                if debug {
//                    print(stateInfo?.type as Any)
//                    print("\(String(describing: stateInfo?.path)): \(value)")
//
//                }
//                state?.value = "\(value)"
            } else {
                logger.debug("invalid commandID: \(commandID)")
                closeConnection()
            }
        }
    }
    
    private func getTypeFromInt(int: Int) -> String {
        switch int {
            case 0: return "bool"
            case 1: return "int"
            case 2: return "float"
            case 3: return "double"
            case 4: return "string"
            case 5: return "long"
            default: return "unknown"
        }
    }
    
    private func timestampMilliseconds() -> Int {
        return Int(1000 * Date().timeIntervalSince1970)
    }
    
}
