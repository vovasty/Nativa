//
//  Logger.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/27/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public struct Logger {
    public func debug(msg: String) {
        print("debug: \(msg)")
    }
    public func error(msg: String) {
        print("error: \(msg)")
    }
    public func info(msg: String) {
        print("info: \(msg)")
    }
}

public let logger = Logger()
