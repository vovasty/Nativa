//
//  Logger.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/27/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation
import Cocoa

public struct Logger {
    public func debug(_ msg: Any) {
        NSLog("%@", "debug: \(msg)")
    }
    public func error(_ msg: String) {
        NSLog("%@", "error: \(msg)")

        let center = NSUserNotificationCenter.default
        center.removeAllDeliveredNotifications()
        let note = NSUserNotification()
        note.title = "Error"
        note.informativeText = msg
        center.scheduleNotification(note)
    }
    public func info(_ msg: String) {
        NSLog("%@", "info: \(msg)")
    }
}

public let logger = Logger()
