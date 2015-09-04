//
//  BinaryTorrent.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/29/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

enum BencodeError: ErrorType {
    case Failure(msg: String)
}

private class Tokenizer: GeneratorType {
    private var values = [String]()
    private var index = 0
    
    init(_ data: NSData) throws {
        var bytes = UnsafePointer<UInt8>(data.bytes)
        let bytesEnd = bytes + data.length
        
        while bytes < bytesEnd
        {
            let byte = bytes[0]
            
            //d e i l
            switch byte {
            case 100, 101, 105, 108:
                let token = String(Character(UnicodeScalar(byte)))
                values.append(token)
                bytes++
            //0...9
            case 48 ... 57:
                break
            default:
                 throw BencodeError.Failure(msg: "junk[\(bytesEnd-bytes)]:\(Character(UnicodeScalar(bytes[0])))")
            }
            
            var numberPtr = bytes
            var numberLength = 0
            //numbers
            //0...9
            while case 48 ... 57 = numberPtr[0] where numberPtr < bytesEnd {
                numberPtr++
                numberLength++
            }
            
            guard numberPtr <= bytesEnd else {
                throw BencodeError.Failure(msg: "buffer overflow")
            }
            
            if numberLength > 0
            {
                let number = NSString(bytes: bytes, length: numberLength, encoding: NSUTF8StringEncoding)!
                
                //:
                if bytes[numberLength] == 58
                {
                    if let stringLength = Int((number as String))
                    {
                        values.append("s")
                        
                        if let string  = NSString(bytes: numberPtr + 1, length: stringLength, encoding: NSUTF8StringEncoding) {
                            values.append(string as String)
                        }
                        else {
                            values.append("")
                        }
                        
                        bytes = numberPtr + 1 + stringLength
                    }
                    
                }
                else
                {
                    values.append(number as String)
                    bytes = numberPtr
                }
            }
        }
    }
    
    func next() -> String? {
        return index < values.count ? values[index++] : nil
    }
}


private func bdecode(gen: Tokenizer, token: String) throws -> AnyObject?
{
    var data: AnyObject?
    
    switch ( token )
    {
    case "i":
        if let number = gen.next(){
            let nextToken = gen.next()
            guard nextToken == "e" else {
                throw BencodeError.Failure(msg: "no end token")
            }
            data = (number as NSString).doubleValue
        }
    case "s":
        data = gen.next()!
    case "l", "d":
        if var tok = gen.next(){
            var array = [AnyObject]()
            
            while tok != "e"{
                let v = try bdecode(gen, token: tok)!
                array.append(v)
                tok = gen.next()!
            }
            
            if token == "d" {
                var dict = [String: AnyObject]()
                
                for var i = array.startIndex; i < array.count; i += 2 {
                    let k = array[i] as! String
                    let v = array[i + 1]
                    dict[k] = v
                }
                
                data = dict
            }
            else
            {
                data = array
            }
        }
    default:
        throw BencodeError.Failure(msg: "invalid token")
    }
    
    return data
}

public func bdecode<T>(data: NSData) throws -> T? {
    let gen = try Tokenizer(data)

    guard let token = gen.next() else {
        return nil
    }
    
    return try bdecode(gen, token: token) as? T
}
