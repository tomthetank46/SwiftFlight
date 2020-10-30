//
//  FlightControls.swift
//  InfiniteControl
//
//  Created by Thomas Hogrefe on 5/13/19.
//  Copyright © 2019 Tom Hogrefe. All rights reserved.
//

import Foundation
import UIKit

class FlightControls: NSObject {
    
    // MARK: - variables
    
    let impact = UIImpactFeedbackGenerator()
    let selection = UISelectionFeedbackGenerator()
    let notification = UINotificationFeedbackGenerator()
    
    // MARK: - Axes
    
    public func axisCommand(axis: Int, val: Float) {
        if let pitchCommand = newConnectAPI.StateInfoDict["api_joystick/axes/\(axis)/value"]?.ID {
            newConnectAPI.setState(commandID: pitchCommand, value: Int32(-val))
        }
    }
    
    public func throttleCommand(val: Float) {
        if let throttleCommand = newConnectAPI.StateInfoDict["api_joystick/axes/3/value"]?.ID {
            newConnectAPI.setState(commandID: throttleCommand, value: Int32(-(val - 1024)))
        }
        updateValue(path: "aircraft/0/systems/engines/0/throttle_lever", value: val / 2048)
    }
    
    // MARK: - Flight Controls
    
    //speedbrakes() moves the speedbrakes to the specified position
    public func speedbrakes(pos: Int) {
        if let spoilers = newConnectAPI.StateInfoDict["aircraft/0/systems/spoilers/state"]?.ID {
            newConnectAPI.setState(commandID: spoilers, value: Int32(pos))
            newConnectAPI.getState(ID: spoilers)
            selection.selectionChanged()
            updateValue(path: "aircraft/0/systems/spoilers/state", value: pos)
        }
    }
    
    //flaps() takes a double 1 or -1, and steps the flaps +1 or -1
    public func flaps(direction: Int) {
        guard let flaps = newConnectAPI.StateInfoDict["aircraft/0/systems/flaps/state"]?.ID else {
            return
        }
        let flapsPosition = newConnectAPI.StateByID[flaps]?.value as? Int32 ?? 0
        newConnectAPI.setState(commandID: flaps, value: flapsPosition + Int32(direction))
        selection.selectionChanged()
        updateValue(path: "aircraft/0/systems/flaps/state", value: flapsPosition + Int32(direction))
        newConnectAPI.getState(ID: flaps)
    }
    
    //trim() takes an integer and steps the trim that many percent
    public func trim(step: Int) {
        if (step > 0) {
            guard let trim = newConnectAPI.CommandsDict["commands/ElevatorTrimDown"]?.ID else {
                return
            }
            for _ in 1...abs(step) {
                newConnectAPI.sendCommand(commandID: trim)
            }
        } else if (step < 0) {
            guard let trim = newConnectAPI.CommandsDict["commands/ElevatorTrimUp"]?.ID else {
                return
            }
            for _ in 1...abs(step) {
                newConnectAPI.sendCommand(commandID: trim)
            }
        }
        selection.selectionChanged()
    }
    
    // MARK: - Throttle
    
    //reverseStart() takes a boolean and sets reverse to true or false
    public func reverseState(state: Bool) {
//        connectAPI.sendCommand(command: ConnectCommand.Reverse, parameter: "Down", parameterName: "KeyAction")
        if let rev = newConnectAPI.StateInfoDict["aircraft/0/systems/reverse/state"]?.ID {
            newConnectAPI.setState(commandID: rev, value: state)
        }
        updateValue(path: "aircraft/0/systems/reverse/state", value: state)
        selection.selectionChanged()
    }
    
    // MARK: - Cameras
    
    //cameraPan() pans the camera like a hat switch
    public func cameraPan(x: Float, y: Float) {
        if let xCommand = newConnectAPI.StateInfoDict["api_joystick/pov/x"]?.ID {
            newConnectAPI.setState(commandID: xCommand, value: x/60)
        }
        if let yCommand = newConnectAPI.StateInfoDict["api_joystick/pov/y"]?.ID {
            newConnectAPI.setState(commandID: yCommand, value: -y/100)
        }
    }
    
    //virtualCockpitPan() takes two doubles, and moves the cockpit camera that number of radians in the x and y direction respectively
    public func virtualCockpitPan(x: Double, y: Double) {

//        if let currentCamera = newConnectAPI.StateInfoDict["infiniteflight/current_camera"]?.ID {
//            if let cameraName: String = newConnectAPI.StateByID[currentCamera]?.value as? String {
//                if cameraName == "NORMAL" || cameraName == "LOCKED" {
//                    cameraPan(x: Float(x), y: Float(y))
//                } else {
//                    let xToSend: Double = 0//cameraInfo.x! + x/100
//                    let yToSend: Double = 0//cameraInfo.y! + y/60
//                    let cameraNumber = newConnectAPI.cameraInfo[cameraName]?.number
//                    if let or = newConnectAPI.StateInfoDict["infiniteflight/cameras/\(String(cameraNumber!))/angle_override"]?.ID {
//                        newConnectAPI.setState(commandID: or, value: true)
//                    }
//                    if let xCommand = newConnectAPI.StateInfoDict["infiniteflight/cameras/\(String(cameraNumber!))/y_angle"]?.ID {
//                        newConnectAPI.setState(commandID: xCommand, value: xToSend)
//                    }
//                    if let yCommand = newConnectAPI.StateInfoDict["infiniteflight/cameras/\(String(cameraNumber!))/x_angle"]?.ID {
//                        newConnectAPI.setState(commandID: yCommand, value: yToSend)
//                    }
//                }
//            }
//        }
    }
    
    //cameraReset() resets a panned POV (currently modded to go to previous camera)
    public func cameraReset() {
        if let reset = newConnectAPI.CommandsDict["commands/Reset"]?.ID {
            newConnectAPI.sendCommand(commandID: reset)
        }
    }
    
    //virtualCockpitReset() resets the VC view
    public func virtualCockpitReset() {
        if let reset = newConnectAPI.CommandsDict["commands/Reset"]?.ID {
            newConnectAPI.sendCommand(commandID: reset)
        }
        
        if let or = newConnectAPI.StateInfoDict["infiniteflight/cameras/8/angle_override"]?.ID {
            newConnectAPI.setState(commandID: or, value: false)
        }
        if let xCommand = newConnectAPI.StateInfoDict["infiniteflight/cameras/8/y_angle"]?.ID {
            newConnectAPI.getState(ID: xCommand)
        }
        if let yCommand = newConnectAPI.StateInfoDict["infiniteflight/cameras/8/x_angle"]?.ID {
            newConnectAPI.getState(ID: yCommand)
        }
    }
    
    //nextCamera() cycles to next camera
    public func nextCamera() {
        if let nextCam = newConnectAPI.CommandsDict["commands/NextCamera"]?.ID {
            newConnectAPI.sendCommand(commandID: nextCam)
        }
    }
    
    //toggleHUD() toggles the HUD
    public func toggleHUD() {
        if let hud = newConnectAPI.CommandsDict["commands/ToggleHUD"]?.ID {
            newConnectAPI.sendCommand(commandID: hud)
        }
    }
    
    // MARK: - wheels and gear
    
    //brakes() takes no arguments, toggles the brakes.
    public func brakes() {
        guard let brakesCommand = newConnectAPI.CommandsDict["commands/ParkingBrakes"]?.ID else {
            return
        }
        newConnectAPI.sendCommand(commandID: brakesCommand)
        selection.selectionChanged()
    }
    
    //gear() takes no arguments and toggles the gear
    public func gear() {
        guard let gearCommand = newConnectAPI.CommandsDict["commands/LandingGear"]?.ID else {
            return
        }
        newConnectAPI.sendCommand(commandID: gearCommand)
        guard let gear = newConnectAPI.StateInfoDict["aircraft/0/systems/landing_gear/state"]?.ID else {
            return
        }
        notification.notificationOccurred(.success)
        newConnectAPI.getState(ID: gear)
    }
    
    //push() takes no arguments and toggles pushback
    public func push() {
        if let pb = newConnectAPI.CommandsDict["commands/Pushback"]?.ID {
            newConnectAPI.sendCommand(commandID: pb)
            selection.selectionChanged()
        }
    }
    
    // MARK: -  Lights
    
    public func nav(value: Int) {
        guard let nav = newConnectAPI.StateInfoDict["aircraft/0/systems/electrical_switch/nav_lights_switch/state"]?.ID else {
            return
        }
        newConnectAPI.setState(commandID: nav, value: Int32(value))
        newConnectAPI.getState(ID: nav)
        selection.selectionChanged()
        updateValue(path: "aircraft/0/systems/electrical_switch/nav_lights_switch/state", value: value)
    }
    
    public func beacon(value: Int) {
        guard let beacon = newConnectAPI.StateInfoDict["aircraft/0/systems/electrical_switch/beacon_lights_switch/state"]?.ID else {
            return
        }
        newConnectAPI.setState(commandID: beacon, value: Int32(value))
        newConnectAPI.getState(ID: beacon)
        selection.selectionChanged()
        updateValue(path: "aircraft/0/systems/electrical_switch/beacon_lights_switch/state", value: value)
    }
    
    public func strobe(value: Int) {
        guard let strobe = newConnectAPI.StateInfoDict["aircraft/0/systems/electrical_switch/strobe_lights_switch/state"]?.ID else {
            return
        }
        newConnectAPI.setState(commandID: strobe, value: Int32(value))
        newConnectAPI.getState(ID: strobe)
        selection.selectionChanged()
        updateValue(path: "aircraft/0/systems/electrical_switch/strobe_lights_switch/state", value: value)
    }
    
    public func landing(value: Int) {
        guard let landing = newConnectAPI.StateInfoDict["aircraft/0/systems/electrical_switch/landing_lights_switch/state"]?.ID else {
            return
        }
        newConnectAPI.setState(commandID: landing, value: Int32(value))
        newConnectAPI.getState(ID: landing)
        selection.selectionChanged()
        updateValue(path: "aircraft/0/systems/electrical_switch/landing_lights_switch/state", value: value)
    }
    
    // Autopilot
    
    public func apToggle() {
        if let ap = newConnectAPI.CommandsDict["commands/Autopilot.Toggle"]?.ID {
            newConnectAPI.sendCommand(commandID: ap)
            notification.notificationOccurred(.warning)
        }
    }
    
    public func apNavToggle(value: Bool) {
        if let nav = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/nav/on"]?.ID {
            newConnectAPI.setState(commandID: nav, value: !value)
            newConnectAPI.getState(ID: nav)
            selection.selectionChanged()
            self.updateValue(path: "aircraft/0/systems/autopilot/nav/on", value: value)
        }
    }
    
    public func vnavToggle(value: Bool) {
        if let vnav = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/vnav/on"]?.ID {
            newConnectAPI.setState(commandID: vnav, value: !value)
            newConnectAPI.getState(ID: vnav)
            selection.selectionChanged()
            self.updateValue(path: "aircraft/0/systems/autopilot/vnav/on", value: value)
        }
    }
    
    public func headingToggle(value: Bool) {
        guard let hdg = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/hdg/on"]?.ID else {
            return
        }
        guard let target = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/hdg/target"]?.ID else {
            return
        }
        guard let current = newConnectAPI.StateInfoDict["aircraft/0/heading_magnetic"]?.ID else {
            return
        }
        let currentValue: Float = newConnectAPI.StateByID[current]?.value as! Float
        newConnectAPI.setState(commandID: target, value: currentValue)
        newConnectAPI.setState(commandID: hdg, value: !value)
        newConnectAPI.getState(ID: hdg)
        selection.selectionChanged()
        self.updateValue(path: "aircraft/0/systems/autopilot/hdg/on", value: value)
    }
    
    public func stepHeading(step: Int) {
        if let cmd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/hdg/target"]?.ID {
            let currVal: Float = radToDeg(newConnectAPI.StateByID[cmd]?.value as! Float)
            var newValDeg: Float = currVal + Float(step)
            if newValDeg < 1 { newValDeg += 360 }
            let newValRad: Float = degToRad(newValDeg)
            newConnectAPI.setState(commandID: cmd, value: newValRad)
            selection.selectionChanged()
            newConnectAPI.getState(ID: cmd)
        }
    }
    
    public func speedToggle(value: Bool) {
        guard let spd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/spd/on"]?.ID else {
            return
        }
        guard let target = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/spd/target"]?.ID else {
            return
        }
        
        var current: Int32 = 0
        
        guard let altitude: Float = ((newConnectAPI.StateByID[(newConnectAPI.StateInfoDict["aircraft/0/altitude_msl"]?.ID)!]?.value ?? 0)) as? Float else {
                return
        }
        if  altitude < 28000 {
            current = newConnectAPI.StateInfoDict["aircraft/0/indicated_airspeed"]?.ID ?? 0
        } else {
            current = newConnectAPI.StateInfoDict["aircraft/0/mach_speed"]?.ID ?? 0
        }
        
        let currentValue: Float = newConnectAPI.StateByID[current]?.value as! Float
        
        newConnectAPI.setState(commandID: target, value: currentValue)
        newConnectAPI.setState(commandID: spd, value: !value)
        newConnectAPI.getState(ID: spd)
        selection.selectionChanged()
        self.updateValue(path: "aircraft/0/systems/autopilot/spd/on", value: value)
    }
    
    public func stepSpeed(step: Float) {
        if let cmd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/spd/target"]?.ID {
            var currVal: Float = newConnectAPI.StateByID[cmd]?.value as! Float

            if let altitude: Float = ((newConnectAPI.StateByID[(newConnectAPI.StateInfoDict["aircraft/0/altitude_msl"]?.ID)!]?.value ?? 0)) as? Float {
                
                if  altitude < 28000 {
                    currVal = ifSpdToKnots(currVal)
                    let newVal: Float = knotsToIFSpd(currVal + Float(step))
                    newConnectAPI.setState(commandID: cmd, value: newVal)
                } else {
                    let newVal: Float = currVal + Float(step)
                    newConnectAPI.setState(commandID: cmd, value: newVal)
                }
                
                newConnectAPI.getState(ID: cmd)
                
            }
            selection.selectionChanged()
        }
    }
    
    public func altitudeToggle(value: Bool) {
        if let alt =  newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/alt/on"]?.ID {
            newConnectAPI.setState(commandID: alt, value: !value)
            newConnectAPI.getState(ID: alt)
            selection.selectionChanged()
            self.updateValue(path: "aircraft/0/systems/autopilot/alt/on", value: value)
        }
    }
    
    public func stepAltitude(step: Int) {
        if let cmd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/alt/target"]?.ID {
            let currVal: Float = ifAltToFeet(newConnectAPI.StateByID[cmd]?.value as! Float)
            var newVal: Float = feetToIFAlt(roundToHundreds(currVal + Float(step)))
            if newVal < 0 { newVal = 0 }
            newConnectAPI.setState(commandID: cmd, value: newVal)
            selection.selectionChanged()
            newConnectAPI.getState(ID: cmd)
        }
    }
    
    public func vsToggle(value: Bool) {
        guard let vs = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/vs/on"]?.ID else {
            return
        }
        guard let target = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/vs/target"]?.ID else {
            return
        }
        guard let current = newConnectAPI.StateInfoDict["aircraft/0/vertical_speed"]?.ID else {
            return
        }
        let currentValue: Float = ifAltToFeet(newConnectAPI.StateByID[current]?.value as! Float)
        newConnectAPI.setState(commandID: target, value: 60 * feetToIFAlt(currentValue))
        newConnectAPI.setState(commandID: vs, value: !value)
        newConnectAPI.getState(ID: vs)
        selection.selectionChanged()
        self.updateValue(path: "aircraft/0/systems/autopilot/vs/on", value: value)
    }
    
    public func stepVS(step: Int) {
        if let cmd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/vs/target"]?.ID {
            let currVal: Float = ifAltToFeet(newConnectAPI.StateByID[cmd]?.value as! Float)
            let newVal: Float = feetToIFAlt(roundToHundreds(currVal + Float(step)))
            newConnectAPI.setState(commandID: cmd, value: newVal)
            selection.selectionChanged()
            newConnectAPI.getState(ID: cmd)
        }
    }
    
    private func apStep(function: String, step: Float) {
        if let cmd = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/\(function)/target"]?.ID {
            let currVal: Float = newConnectAPI.StateByID[cmd]?.value as! Float
            let newVal: Float = currVal + step
            newConnectAPI.setState(commandID: cmd, value: newVal)
            newConnectAPI.getState(ID: cmd)
            selection.selectionChanged()
        }
    }
    
    private func getAPToggleStates() {
        let APs = ["aircraft/0/systems/autopilot/on", "aircraft/0/systems/autopilot/hdg/on", "aircraft/0/systems/autopilot/spd/on",
            "aircraft/0/systems/autopilot/alt/on",
            "aircraft/0/systems/autopilot/vs/on"]
        for AP in APs {
            if let cmd = newConnectAPI.StateInfoDict[AP]?.ID {
                newConnectAPI.getState(ID: cmd)
            }
        }
    }
    
    public func openATCWindow() {
        if let window = newConnectAPI.CommandsDict["commands/ShowATCWindowCommand"]?.ID {
            newConnectAPI.sendCommand(commandID: window)
            selection.selectionChanged()
        }
    }
    
    public func atcEntry(num: Int) {
        if let atc = newConnectAPI.CommandsDict["commands/ATCEntry\(num)"]?.ID {
            newConnectAPI.sendCommand(commandID: atc)
            selection.selectionChanged()
        }
    }
    
    public func degToRad(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }
    
    public func radToDeg(_ radians: Float) -> Float {
        return radians * 180 / .pi
    }
    public func knotsToIFSpd(_ knots: Float) -> Float {
        return knots / 1.94384438
    }
    public func ifSpdToKnots(_ speed: Float) -> Float {
        return speed * 1.94384438
    }
    public func feetToIFAlt(_ feet: Float) -> Float {
        return feet / 3.2808399
    }
    public func ifAltToFeet(_ alt: Float) -> Float {
        return alt * 3.2808399
    }
    public func roundToTens(_ num: Float) -> Float {
        return 10 * Float(Int(round(num / 10.0)))
    }
    public func roundToHundreds(_ num: Float) -> Float {
        return 100 * Float(Int(round(num / 100.0)))
    }
    public func roundToFiveHundreds(_ num: Float) -> Float {
        return 500 * Float(Int(round(num / 500.0)))
    }
    
    public func updateValue(path: String, value: Any) {
        if let id = newConnectAPI.StateInfoDict[path]?.ID {
            newConnectAPI.StateByID[id]?.value = value
        }
    }
    
}
