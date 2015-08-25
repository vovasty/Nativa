//
//  XMLRPCEncoder.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/5/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum XMLRPCEncoderError: ErrorType {
    case UnsupportedType
}


public func XMLRPCEncode(method: String, parameters: [AnyObject]?) throws -> String {
    
    guard let parameters = parameters else {
        return   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<methodCall>\n" +
            "  <methodName>\(method)</methodName>\n" +
            "  <params/>\n" +
        "</methodCall>"
    }
    
    let parametersFragment = try encodedParametersFragment(parameters)
    
    return   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
        "<methodCall>\n" +
        "  <methodName>\(method)</methodName>\n" +
        "  <params>\n" +
        parametersFragment +
        "  </params>\n" +
    "</methodCall>"
}

func iso8601DateFormatter() -> NSDateFormatter{
    let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = enUSPosixLocale
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return dateFormatter
}

private func encodedParametersFragment(parameters: [AnyObject]) throws -> String {
    var result = ""
    for parameter in parameters {
        
        let encodedParameters = try encode(parameter)
        result += "<param>\n" +
                    encodedParameters +
                  "</param>"
    }
    
    return result
}

private func encode(array: [AnyObject]) throws -> String {
    var buffer  = "<value><array><data>"
    
    for object in array {
        buffer += try encode(object)
    }
    
    buffer += "</data></array></value>"
    return buffer
}

private func encode(dictionary: [String: AnyObject]) throws -> String {
    var buffer = "<value><struct>"
    
    for (k, v) in dictionary {
        buffer += "<member>"
        buffer += "<name>\(k)</name>"
        buffer += try encode(v)
        buffer += "</member>"
    }
    
    buffer += "</struct></value>"
    
    return buffer
}

private func valueTag(tag: String, value: String) -> String {
    return "<value><\(tag)>\(value)</\(tag)></value>"
}


private func encode(boolean: Bool) -> String {
    return valueTag("boolean", value: boolean ? "1" : "0")
}

private func encode(int: Int) -> String {
    return valueTag("i4", value: String(int))
}

private func encode(double: Double) -> String {
    return valueTag("double", value: String(double))
}


private func encode(string: String) -> String {
    
    //escape only XML entities
    let s = NSMutableString(string: string)
    s.replaceOccurrencesOfString("&", withString:"&amp;", options: .LiteralSearch, range:NSMakeRange(0, s.length))
    s.replaceOccurrencesOfString("\"", withString:"&quot;", options: .LiteralSearch, range:NSMakeRange(0, s.length))
    s.replaceOccurrencesOfString("'", withString:"&#x27;", options: .LiteralSearch, range:NSMakeRange(0, s.length))
    s.replaceOccurrencesOfString(">", withString:"&gt;", options: .LiteralSearch, range:NSMakeRange(0, s.length))
    s.replaceOccurrencesOfString("<", withString:"&lt;", options: .LiteralSearch, range:NSMakeRange(0, s.length))

    return valueTag("string", value: s as String)
}

private func encode(date: NSDate) -> String {
    return valueTag("dateTime.iso8601", value: iso8601DateFormatter().stringFromDate(date))
}

private func encode(data: NSData)  -> String {
    let encoded = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    return valueTag("base64", value: encoded)
}

private func encode(object: AnyObject) throws -> String {
    switch object {
    case let o as [AnyObject]:
        return try encode(o)
    case let o as [String: AnyObject]:
        return try encode(o)
    case let o as Int:
        return encode(o)
    case let o as Double:
        return encode(o)
    case let o as Bool:
        return encode(o)
    case let o as String:
        return encode(o)
    case let o as NSDate:
        return encode(o)
    case let o as NSData:
        return encode(o)
    default:
        throw XMLRPCEncoderError.UnsupportedType
    }
}