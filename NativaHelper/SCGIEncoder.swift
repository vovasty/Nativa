//
//  SCGIEncoder.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/5/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation


private extension NSMutableData {
    final func appendString(string: String, encoding: UInt) -> Self {
        appendBytes(string.cStringUsingEncoding(NSASCIIStringEncoding)!, length: string.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
        return self
    }
    
    final func appendZero() -> Self {
        appendBytes(UnsafePointer<Void>([0]), length: 1)
        return self
    }
}

public func encodeSCGI(string: String) -> NSData
{
    let sLength = String(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    let lengthOfLength = String(sLength).lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
    let headerLength = 23 + lengthOfLength //23 = 14(CONTENT_LENGTH)+4(\0)+4(SCGI)+1(1)
    
    let result = NSMutableData()
    result.appendString("\(headerLength):", encoding: NSASCIIStringEncoding)
        .appendString("CONTENT_LENGTH", encoding: NSASCIIStringEncoding)
        .appendZero()
        .appendString(sLength, encoding: NSASCIIStringEncoding)
        .appendZero()
        .appendString("SCGI", encoding: NSASCIIStringEncoding)
        .appendZero()
        .appendString("1", encoding: NSASCIIStringEncoding)
        .appendZero()
        .appendString(",", encoding: NSASCIIStringEncoding)
        .appendString(string, encoding: NSUTF8StringEncoding)
    
    return result;
}