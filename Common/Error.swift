//
//  Error.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/25/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum RTorrentError: ErrorType {
    case UnknownError(message: String)
}

public extension NSError {
    convenience init?(_ error: ErrorType?) {
        guard let error = error else {
            return nil
        }
        
        self.init(domain: error._domain, code: error._code, userInfo: [NSLocalizedDescriptionKey: "\(error)"])
    }
}
