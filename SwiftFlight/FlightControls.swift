//
//  FlightControls.swift
//  InfiniteControl
//
//  Created by Thomas Hogrefe on 5/13/19.
//  Copyright © 2019 Tom Hogrefe. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 14.0, *)
public class FlightControls: NSObject {
    
    let connectAPI: ConnectAPI?
    public init(API: ConnectAPI) {
        self.connectAPI = API
    }
    
    // MARK: - Axes
    
    public func axisCommand(axis: Int, val: Float) {
        if let pitchCommand = connectAPI?.StateInfoDict["api_joystick/axes/\(axis)/value"]?.ID {
            connectAPI?.setState(commandID: pitchCommand, value: Int32(-val))
        }
    }
    
    public func throttleCommand(val: Float) {
        if let throttleCommand = connectAPI?.StateInfoDict["api_joystick/axes/3/value"]?.ID {
            connectAPI?.setState(commandID: throttleCommand, value: Int32(-(val - 1024)))
        }
    }
    
    // MARK: - Flight Controls
    
    //speedbrakes() moves the speedbrakes to the specified position
    public func speedbrakes(pos: Int) {
        if let spoilers = connectAPI?.StateInfoDict["aircraft/0/systems/spoilers/state"]?.ID {
            connectAPI?.setState(commandID: spoilers, value: Int32(pos))
        }
    }
    
    //flaps() takes a double 1 or -1, and steps the flaps +1 or -1
    public func flaps(direction: Int) {
        guard let flaps = connectAPI?.StateInfoDict["aircraft/0/systems/flaps/state"]?.ID else {
            return
        }
        let flapsPosition = connectAPI?.StateByID[flaps]?.value as? Int32 ?? 0
        connectAPI?.setState(commandID: flaps, value: flapsPosition + Int32(direction))
    }
    
    //trim() takes an integer and steps the trim that many percent
    public func trim(step: Int) {
        if (step > 0) {
            guard let trim = connectAPI?.CommandsDict["commands/ElevatorTrimDown"]?.ID else {
                return
            }
            for _ in 1...abs(step) {
                connectAPI?.sendCommand(commandID: trim)
            }
        } else if (step < 0) {
            guard let trim = connectAPI?.CommandsDict["commands/ElevatorTrimUp"]?.ID else {
                return
            }
            for _ in 1...abs(step) {
                connectAPI?.sendCommand(commandID: trim)
            }
        }
    }
    
    // MARK: - Throttle
    
    //reverseStart() takes a boolean and sets reverse to true or false
    public func reverseState(state: Bool) {
//        connectAPI.sendCommand(command: ConnectCommand.Reverse, parameter: "Down", parameterName: "KeyAction")
        if let rev = connectAPI?.StateInfoDict["aircraft/0/systems/reverse/state"]?.ID {
            connectAPI?.setState(commandID: rev, value: state)
        }
    }
    
    // MARK: - Cameras
    
    //cameraPan() pans the camera like a hat switch
    public func cameraPan(x: Float, y: Float) {
        if let xCommand = connectAPI?.StateInfoDict["api_joystick/pov/x"]?.ID {
            connectAPI?.setState(commandID: xCommand, value: x/60)
        }
        if let yCommand = connectAPI?.StateInfoDict["api_joystick/pov/y"]?.ID {
            connectAPI?.setState(commandID: yCommand, value: -y/100)
        }
    }
    
    //virtualCockpitPan() takes two doubles, and moves the cockpit camera that number of radians in the x and y direction respectively
    public func virtualCockpitPan(x: Double, y: Double, cameraNumber: Int) {
        
        if let or = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/angle_override"]?.ID {
            connectAPI?.setState(commandID: or, value: true)
        }
        if let xCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/y_angle"]?.ID {
            connectAPI?.setState(commandID: xCommand, value: x)
        }
        if let yCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/x_angle"]?.ID {
            connectAPI?.setState(commandID: yCommand, value: y)
        }
    }
    
    public func virtualCockpitTranslate(x: Double, y: Double, z: Double, cameraNumber: Int) {
        if let xCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/x_offset"]?.ID {
            connectAPI?.setState(commandID: xCommand, value: x)
        }
        if let yCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/y_offset"]?.ID {
            connectAPI?.setState(commandID: yCommand, value: y)
        }
        if let zCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/\(cameraNumber)/z_offset"]?.ID {
            connectAPI?.setState(commandID: zCommand, value: z)
        }
    }
    
    //cameraReset() resets a panned POV (currently modded to go to previous camera)
    public func cameraReset() {
        if let reset = connectAPI?.CommandsDict["commands/Reset"]?.ID {
            connectAPI?.sendCommand(commandID: reset)
        }
    }
    
    //virtualCockpitReset() resets the VC view
    public func virtualCockpitReset() {
        if let reset = connectAPI?.CommandsDict["commands/Reset"]?.ID {
            connectAPI?.sendCommand(commandID: reset)
        }
        
        if let or = connectAPI?.StateInfoDict["infiniteflight/cameras/8/angle_override"]?.ID {
            connectAPI?.setState(commandID: or, value: false)
        }
        if let xCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/8/y_angle"]?.ID {
            connectAPI?.getState(ID: xCommand)
        }
        if let yCommand = connectAPI?.StateInfoDict["infiniteflight/cameras/8/x_angle"]?.ID {
            connectAPI?.getState(ID: yCommand)
        }
    }
    
    //nextCamera() cycles to next camera
    public func nextCamera() {
        if let nextCam = connectAPI?.CommandsDict["commands/NextCamera"]?.ID {
            connectAPI?.sendCommand(commandID: nextCam)
        }
    }
    
    //toggleHUD() toggles the HUD
    public func toggleHUD() {
        if let hud = connectAPI?.CommandsDict["commands/ToggleHUD"]?.ID {
            connectAPI?.sendCommand(commandID: hud)
        }
    }
    
    public func setCameraPosition(camera: Int, axis: String, offset: Double) {
        let str = "infiniteflight/cameras/\(camera)/\(axis)_offset"
        if let cameraOffset = connectAPI?.StateInfoDict[str]?.ID {
            connectAPI?.setState(commandID: cameraOffset, value: offset)
        }
    }
    
    public func setCameraAngle(camera: Int, axis: String, angle: Double) {
        if let cameraAngle = connectAPI?.getID(str: "infiniteflight/cameras/\(camera)/\(axis)_angle") {
            print(angle)
            connectAPI?.setState(commandID: cameraAngle, value: angle)
        }
    }
    
    public func setCameraOverride(camera: Int, value: Bool) {
        if let angle_override = connectAPI?.getID(str: "infiniteflight/cameras/\(camera)/angle_override") {
            connectAPI?.setState(commandID: angle_override, value: true)
        }
    }
    // MARK: - wheels and gear
    
    //brakes() takes a boolean and sets the brakes accordingly.
    public func brakes(value: Bool) {
        guard let brakes = connectAPI?.StateInfoDict["aircraft/0/systems/parking_brake/state"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: brakes, value: value)
    }
    
    //gear() takes a boolean and sets the landing gear to the correct state
    public func gear(value: Bool) {
        guard let lever = connectAPI?.StateInfoDict["aircraft/0/systems/landing_gear/lever_state"]?.ID else {
            return
        }
        guard let gearCommand = connectAPI?.CommandsDict["commands/LandingGear"]?.ID else {
            return
        }
        connectAPI?.sendCommand(commandID: gearCommand)
        connectAPI?.updateState(commandID: lever, value: value)
        // this is a little bit of a hack while aircraft/0/systems/landing_gear/lever_state is broken
    }
    
    //push() takes no arguments and toggles pushback
    public func push() {
        if let pb = connectAPI?.CommandsDict["commands/Pushback"]?.ID {
            connectAPI?.sendCommand(commandID: pb)
        }
    }
    
    // MARK: -  Lights
    
    public func nav(value: Int) {
        guard let nav = connectAPI?.StateInfoDict["aircraft/0/systems/electrical_switch/nav_lights_switch/state"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: nav, value: Int32(value))
    }
    
    public func beacon(value: Int) {
        guard let beacon = connectAPI?.StateInfoDict["aircraft/0/systems/electrical_switch/beacon_lights_switch/state"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: beacon, value: Int32(value))
    }
    
    public func strobe(value: Int) {
        guard let strobe = connectAPI?.StateInfoDict["aircraft/0/systems/electrical_switch/strobe_lights_switch/state"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: strobe, value: Int32(value))
    }
    
    public func landing(value: Int) {
        guard let landing = connectAPI?.StateInfoDict["aircraft/0/systems/electrical_switch/landing_lights_switch/state"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: landing, value: Int32(value))
    }
    
    public func autobrakes(value: Int) {
        if let autobrakes = connectAPI?.StateInfoDict["aircraft/0/systems/auto_brakes/command_state"]?.ID {
            connectAPI?.setState(commandID: autobrakes, value: Int32(value))
        }
    }
    
    // Autopilot
    
    public func apToggle() {
        if let ap = connectAPI?.CommandsDict["commands/Autopilot.Toggle"]?.ID {
            connectAPI?.sendCommand(commandID: ap)
        }
    }
    
    public func apNavToggle(value: Bool) {
        if let nav = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/nav/on"]?.ID {
            connectAPI?.setState(commandID: nav, value: !value)
        }
    }
    
    public func vnavToggle(value: Bool) {
        if let vnav = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/vnav/on"]?.ID {
            connectAPI?.setState(commandID: vnav, value: !value)
        }
    }
    
    public func headingToggle(value: Bool) {
        guard let hdg = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/hdg/on"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: hdg, value: !value)
    }
    
    public func stepHeading(step: Int) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/hdg/target"]?.ID {
            let currVal: Float = radToDeg(connectAPI?.StateByID[cmd]?.value as! Float)
            var newValDeg: Float = currVal + Float(step)
            if newValDeg < 1 { newValDeg += 360 }
            let newValRad: Float = degToRad(newValDeg)
            connectAPI?.setState(commandID: cmd, value: newValRad)
        }
    }
    
    public func setHeading(value: Int) {
        if let command = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/hdg/target"]?.ID {
            let valueRadians: Float = degToRad(Float(value))
            connectAPI?.setState(commandID: command, value: valueRadians)
        }
    }
    
    public func speedToggle(value: Bool) {
        guard let spd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/spd/on"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: spd, value: !value)
    }
    
    public func stepSpeed(step: Float) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/spd/target"]?.ID {
            var currVal: Float = connectAPI?.StateByID[cmd]?.value as! Float

            if let altitude: Float = ((connectAPI?.StateByID[(connectAPI?.StateInfoDict["aircraft/0/altitude_msl"]?.ID)!]?.value ?? 0)) as? Float {
                
                if  altitude < 28000 {
                    currVal = ifSpdToKnots(currVal)
                    let newVal: Float = knotsToIFSpd(currVal + Float(step))
                    connectAPI?.setState(commandID: cmd, value: newVal)
                } else {
                    let newVal: Float = currVal + Float(step)
                    connectAPI?.setState(commandID: cmd, value: newVal)
                }
                
                connectAPI?.getState(ID: cmd)
                
            }
        }
    }
    
    public func setSpeedKnots(value: Int) {
        if let command = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/spd/target"]?.ID {
            let valueMPS: Float = knotsToIFSpd(Float(value))
            connectAPI?.setState(commandID: command, value: valueMPS)
        }
    }
    
    public func setSpeedMach(value: Float) {
        if let command = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/spd/target"]?.ID {
            connectAPI?.setState(commandID: command, value: value)
        }
    }
    
    public func altitudeToggle(value: Bool) {
        if let alt =  connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/alt/on"]?.ID {
            connectAPI?.setState(commandID: alt, value: !value)
        }
    }
    
    public func stepAltitude(step: Int) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/alt/target"]?.ID {
            let currVal: Float = ifAltToFeet(connectAPI?.StateByID[cmd]?.value as! Float)
            var newVal: Float = feetToIFAlt(roundToHundreds(currVal + Float(step)))
            if newVal < 0 { newVal = 0 }
            connectAPI?.setState(commandID: cmd, value: newVal)
        }
    }
    
    public func setAltitude(value: Int) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/alt/target"]?.ID {
            let valueMeters = feetToIFAlt(Float(value))
            connectAPI?.setState(commandID: cmd, value: valueMeters)
        }
    }
    
    public func vsToggle(value: Bool) {
        guard let vs = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/vs/on"]?.ID else {
            return
        }
        connectAPI?.setState(commandID: vs, value: !value)
    }
    
    public func stepVS(step: Int) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/vs/target"]?.ID {
            let currVal: Float = ifAltToFeet(connectAPI?.StateByID[cmd]?.value as! Float)
            let newVal: Float = feetToIFAlt(roundToHundreds(currVal + Float(step)))
            connectAPI?.setState(commandID: cmd, value: newVal)
        }
    }
    
    public func setVerticalSpeed(value: Int) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/vs/target"]?.ID {
            let valueMeters = feetToIFAlt(Float(value))
            connectAPI?.setState(commandID: cmd, value: valueMeters)
        }
    }
    
    private func apStep(function: String, step: Float) {
        if let cmd = connectAPI?.StateInfoDict["aircraft/0/systems/autopilot/\(function)/target"]?.ID {
            let currVal: Float = connectAPI?.StateByID[cmd]?.value as! Float
            let newVal: Float = currVal + step
            connectAPI?.setState(commandID: cmd, value: newVal)
        }
    }
    
    private func getAPToggleStates() {
        let APs = ["aircraft/0/systems/autopilot/on", "aircraft/0/systems/autopilot/hdg/on", "aircraft/0/systems/autopilot/spd/on",
            "aircraft/0/systems/autopilot/alt/on",
            "aircraft/0/systems/autopilot/vs/on"]
        for AP in APs {
            if let cmd = connectAPI?.StateInfoDict[AP]?.ID {
                connectAPI?.getState(ID: cmd)
            }
        }
    }
    
    public func openATCWindow() {
        if let window = connectAPI?.CommandsDict["commands/ShowATCWindowCommand"]?.ID {
            connectAPI?.sendCommand(commandID: window)
        }
    }
    
    public func atcEntry(num: Int) {
        if let atc = connectAPI?.CommandsDict["commands/ATCEntry\(num)"]?.ID {
            connectAPI?.sendCommand(commandID: atc)
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
    
}
