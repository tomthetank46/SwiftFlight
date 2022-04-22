//
//  TimedState.swift
//  SwiftFlight
//
//  Created by Thomas Hogrefe on 3/28/22.
//

import Foundation

class TimedState {
    
    public var id: Int32
    public var time: Int
    
    init(id: Int32) {
        self.id = id
        self.time = Int(1000 * Date().timeIntervalSince1970)
    }
    
}
