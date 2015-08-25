//
//  XMLRPCParser.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/6/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum XMLRPCDecoderError: ErrorType {
    case NoElementName
    case UnsupportedDataType(type: String)
    case Unknown
    case Fault(code: Int, message: String)
}

//FIXME: replace NSXMLDocument (memory leaks) with libxml2
//http://www.cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html
public func XMLRPCDecode(data: NSData) throws -> AnyObject? {
    let document = try NSXMLDocument(data: data, options: NSXMLDocumentTidyXML)
    
    
    guard let root = document.rootElement() else {
        return nil
    }
    
    if let params = root.elementsForName("params").first {
        guard let param = params.elementsForName("param").first else {
            return nil
        }

        guard let value = param.elementsForName("value").first else {
            return nil
        }
        
        return try parseObject(value)
    }
    else {
        guard let fault = root.elementsForName("fault").first?.elementsForName("value").first?.elementsForName("struct").first else {
            throw XMLRPCDecoderError.Unknown
        }
        
        let msg = try parseDictionary(fault)

        guard let code = msg["faultCode"] as? Int, let message = msg["faultString"] as? String else {
            throw XMLRPCDecoderError.Unknown
        }
        
        throw XMLRPCDecoderError.Fault(code: code, message: message)
    }
    
    
}


private func parseObject(object: NSXMLElement) throws -> AnyObject? {
    guard object.childCount > 0 else {
        return nil
    }
    
    guard let object = object.childAtIndex(0) as? NSXMLElement else {
        return nil
    }

    guard let name = object.name else {
        throw XMLRPCDecoderError.NoElementName
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
        throw XMLRPCDecoderError.UnsupportedDataType(type: name)
    }
}

private func parseArray(element: NSXMLElement) throws ->[AnyObject] {
    guard let parent = element.elementsForName("data").first, let children = parent.children else {
        return []
    }
    
    let filtered = children.filter { (e) -> Bool in
        return e.name == "value"
    }
    
    return try filtered.map { (e) throws -> AnyObject in
        return try parseObject(e as! NSXMLElement)!
    }
}


private func parseDictionary(element: NSXMLElement) throws -> [String: AnyObject] {
    var result: [String: AnyObject] = [:]
    
    guard let children = element.children else {
        return result
    }
    
    for ch in children {
        guard let child = ch as? NSXMLElement where child.name == "member"  else {
            continue
        }
        
        guard let name = child.elementsForName("name").first?.stringValue else {
            continue
        }

        guard let val = child.elementsForName("value").first else {
            continue
        }
        
        let value = try parseObject(val)
        
        result[name] = value
        
    }
    
    return result
}

private func parseInteger(element: NSXMLElement) -> Int? {
    guard let s = element.stringValue else {
        return nil
    }
    
    return Int(s)
}

private func parseDouble(element: NSXMLElement) -> Double? {
    guard let s = element.stringValue else {
        return nil
    }
    
    return Double(s)
}

private func parseBoolean(element: NSXMLElement) -> Bool {
    return element.stringValue == "1"
}

private func parseString(element: NSXMLElement) -> String? {
    return element.stringValue?.stringByRemovingPercentEncoding
}

private func parseDate(element: NSXMLElement) -> NSDate? {
    guard let s = element.stringValue else {
        return nil
    }
    return iso8601DateFormatter().dateFromString(s)
}

func parseData(element: NSXMLElement) -> NSData? {
    guard let s = element.stringValue else {
        return nil
    }

    return NSData(base64EncodedString: s, options: NSDataBase64DecodingOptions(rawValue: 0))
}