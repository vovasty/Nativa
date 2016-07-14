//
//  SCGIEncoder.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/5/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation


private extension NSMutableData {
    
    @discardableResult
    final func appendString(_ string: String, encoding: String.Encoding = String.Encoding.ascii) -> Self {
        append(string.cString(using: encoding)!, length: string.lengthOfBytes(using: encoding))
        return self
    }
    
    @discardableResult
    final func appendZero() -> Self {
        append(UnsafePointer<Void>([0]), length: 1)
        return self
    }
}

public func encodeSCGI(_ string: String) -> Data
{
    let sLength = String(string.lengthOfBytes(using: String.Encoding.utf8))
    let lengthOfLength = String(sLength).lengthOfBytes(using: String.Encoding.ascii)
    let headerLength = 23 + lengthOfLength //23 = 14(CONTENT_LENGTH)+4(\0)+4(SCGI)+1(1)
    
    let result = NSMutableData()
    result.appendString("\(headerLength):")
        .appendString("CONTENT_LENGTH")
        .appendZero()
        .appendString(sLength)
        .appendZero()
        .appendString("SCGI")
        .appendZero()
        .appendString("1")
        .appendZero()
        .appendString(",")
        .appendString(string, encoding: String.Encoding.utf8)
    
    return result as Data;
}
