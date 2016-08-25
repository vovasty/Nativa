//
//  Error.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/25/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum RTorrentError: Error, CustomStringConvertible{
    case unknown(message: String)

    public var description: String {
        switch self {
        case .unknown(let message):
            return message
        }
    }
}
