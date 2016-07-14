//
//  Error.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/25/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum RTorrentError: ErrorProtocol, CustomStringConvertible{
    case unknown(message: String)

    public var description: String {
        switch self {
        case unknown(let message):
            return message
        }
    }
}

public extension NSError {
    convenience init?(_ error: ErrorProtocol?) {
        if let error = error {
            self.init(domain: error._domain, code: error._code, userInfo: [NSLocalizedDescriptionKey: "\(error)"])
        }
        else {
            //FIXME: must call initializer
            self.init(domain: "none", code: -1, userInfo: nil)
            return nil
        }
    }
}
