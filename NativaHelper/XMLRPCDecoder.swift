//
//  XMLRPCParser.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/6/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum XMLRPCDecoderError: ErrorProtocol {
    case noElementName
    case unsupportedDataType(type: String)
    case unknown
    case fault(code: Int, message: String)
}

//FIXME: replace NSXMLDocument (memory leaks) with libxml2
//http://www.cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html
public func XMLRPCDecode(_ data: Data) throws -> AnyObject? {
    let document = try XMLDocument(data: data, options: Int(UInt(XMLNodeOptions.documentTidyXML.rawValue)))
    
    
    guard let root = document.rootElement() else {
        return nil
    }
    
    if let params = root.elements(forName: "params").first {
        guard let param = params.elements(forName: "param").first else {
            return nil
        }

        guard let value = param.elements(forName: "value").first else {
            return nil
        }
        
        return try parseObject(value)
    }
    else {
        guard let fault = root.elements(forName: "fault").first?.elements(forName: "value").first?.elements(forName: "struct").first else {
            throw XMLRPCDecoderError.unknown
        }
        
        let msg = try parseDictionary(fault)

        guard let code = msg["faultCode"] as? Int, let message = msg["faultString"] as? String else {
            throw XMLRPCDecoderError.unknown
        }
        
        throw XMLRPCDecoderError.fault(code: code, message: message)
    }
    
    
}


private func parseObject(_ object: XMLElement) throws -> AnyObject? {
    guard object.childCount > 0 else {
        return nil
    }
    
    guard let object = object.child(at: 0) as? XMLElement else {
        return nil
    }

    guard let name = object.name else {
        throw XMLRPCDecoderError.noElementName
    }
    
    switch name {
    case "array":
        return try parseArray(object)
    case "struct":
        return try parseDictionary(object)
    case "int", "i4", "i8":
        return parseInteger(object)
    case "double":
        return parseDouble(object)
    case "boolean":
        return parseBoolean(object)
    case "string":
        return parseString(object)
    case "dateTime.iso8601":
        return parseDate(object)
    case "base64":
        return parseData(object)
    default:
        throw XMLRPCDecoderError.unsupportedDataType(type: name)
    }
}

private func parseArray(_ element: XMLElement) throws ->[AnyObject] {
    guard let parent = element.elements(forName: "data").first, let children = parent.children else {
        return []
    }
    
    let filtered = children.filter { (e) -> Bool in
        return e.name == "value"
    }
    
    return try filtered.map { (e) throws -> AnyObject in
        return try parseObject(e as! XMLElement)!
    }
}


private func parseDictionary(_ element: XMLElement) throws -> [String: AnyObject] {
    var result: [String: AnyObject] = [:]
    
    guard let children = element.children else {
        return result
    }
    
    for ch in children {
        guard let child = ch as? XMLElement, child.name == "member"  else {
            continue
        }
        
        guard let name = child.elements(forName: "name").first?.stringValue else {
            continue
        }

        guard let val = child.elements(forName: "value").first else {
            continue
        }
        
        let value = try parseObject(val)
        
        result[name] = value
        
    }
    
    return result
}

private func parseInteger(_ element: XMLElement) -> Int? {
    guard let s = element.stringValue else {
        return nil
    }
    
    return Int(s)
}

private func parseDouble(_ element: XMLElement) -> Double? {
    guard let s = element.stringValue else {
        return nil
    }
    
    return Double(s)
}

private func parseBoolean(_ element: XMLElement) -> Bool {
    return element.stringValue == "1"
}

private func parseString(_ element: XMLElement) -> String? {
    return element.stringValue?.removingPercentEncoding
}

private func parseDate(_ element: XMLElement) -> Date? {
    guard let s = element.stringValue else {
        return nil
    }
    return iso8601DateFormatter().date(from: s)
}

func parseData(_ element: XMLElement) -> Data? {
    guard let s = element.stringValue else {
        return nil
    }

    return Data(base64Encoded: s)
}
