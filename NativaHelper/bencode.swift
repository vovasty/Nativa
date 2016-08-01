//
//  BinaryTorrent.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/29/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

enum BencodeError: ErrorProtocol {
    case failure(msg: String)
}

private class Tokenizer: IteratorProtocol {
    private var values = [(String, Int)]()
    private var index = 0
    
    init(_ data: Data) throws {
        let begin = UnsafePointer<UInt8>((data as NSData).bytes)
        var bytes = begin
        let bytesEnd = bytes + data.count
        
        while bytes < bytesEnd
        {
            let byte = bytes[0]
            
            
            switch byte {
            case 100, 101, 105, 108: //d e i l
                let token = String(Character(UnicodeScalar(byte)))
                values.append((token, bytes - begin))
                bytes += 1
            case 48 ... 57: //0...9
                break
            default:
                 //skip junk
                 bytes += 1
                 continue
            }
            
            var numberPtr = bytes
            var numberLength = 0
            //numbers
            //0...9
            while case 48 ... 57 = numberPtr[0], numberPtr < bytesEnd {
                numberPtr += 1
                numberLength += 1
            }
            
            guard numberPtr <= bytesEnd else {
                throw BencodeError.failure(msg: "buffer overflow")
            }
            
            if numberLength > 0
            {
                let number = NSString(bytes: bytes, length: numberLength, encoding: String.Encoding.utf8.rawValue)!
                
                //:
                if bytes[numberLength] == 58
                {
                    if let stringLength = Int((number as String))
                    {
                        values.append(("s", bytes - begin))
                        
                        if let string  = NSString(bytes: numberPtr + 1, length: stringLength, encoding: String.Encoding.utf8.rawValue) {
                            values.append((string as String, numberPtr + 1 - begin))
                        }
                        else {
                            values.append((String(repeating: Character("?"), count: stringLength), numberPtr + 1 - begin))
                        }
                        
                        bytes = numberPtr + 1 + stringLength
                    }
                    
                }
                else
                {
                    values.append((number as String, bytes - begin))
                    bytes = numberPtr
                }
            }
        }
    }
    
    func next() -> (String, Int)? {
        guard index < values.count else { return nil }
        
        let value = values[index]
        index += 1
        return value
    }
}


private func bdecode(_ gen: Tokenizer, token: (String, Int), findInfoRange: Bool = false) throws -> (AnyObject,  Int?, Int?)?
{
    var data: AnyObject?
    var infoBegin: Int?
    var infoEnd: Int?

    switch ( token.0 )
    {
    case "i":
        if let number = gen.next(){
            let nextToken = gen.next()
            guard nextToken?.0 == "e" else {
                throw BencodeError.failure(msg: "no end token")
            }
            data = (number.0 as NSString).doubleValue
        }
    case "s":
        data = gen.next()!.0
    case "l", "d":
        if var tok = gen.next(){
            var array = [AnyObject]()
            
            var index = 0
            while tok.0 != "e"{
                let v = try bdecode(gen, token: tok)!
                array.append(v.0)
                
                tok = gen.next()!
                
                if findInfoRange && token.0 == "d" {
                    if infoBegin != nil && infoEnd == nil{
                        infoEnd = tok.1
                    }
                    if index % 2 == 0 && v.0 as? String == "info" {
                        infoBegin = tok.1
                    }
                    index += 1
                }
            }
            
            if token.0 == "d" {
                var dict = [String: AnyObject]()
                
                for i in stride(from: array.startIndex, to: array.count, by: 2) {
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
        throw BencodeError.failure(msg: "invalid token")
    }
    
    return data == nil ? nil : (data!, infoBegin, infoEnd)
}

public func bdecode<T>(_ data: Data) throws -> (T, String?)? {
    let gen = try Tokenizer(data)

    guard let token = gen.next() else {
        return nil
    }
    
    guard let torrent = try bdecode(gen, token: token, findInfoRange: true) else{
        return nil
    }
    var infoHash: String?
    if let infoBegin = torrent.1, let infoEnd = torrent.2 {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes + infoBegin, CC_LONG(infoEnd - infoBegin), &digest)
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02x", byte)
        }
        infoHash = output as String
    }
    else {
        infoHash = nil
    }
    
    if let result = torrent.0 as? T {
        return (result, infoHash)
    }
    
    return nil
}
