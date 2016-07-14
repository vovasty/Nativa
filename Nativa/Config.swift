//
//  Config.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 1/2/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Foundation


struct _Config {
    let refreshTimeout = 5
    let maxReconnectCounter = 4
    let reconnectTimeout = 1.0
}

let Config = _Config()
