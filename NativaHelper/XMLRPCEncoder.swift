//
//  XMLRPCEncoder.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/5/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

public enum XMLRPCEncoderError: ErrorProtocol {
    case unsupportedType
}


public func XMLRPCEncode(_ method: String, parameters: [AnyObject]?) throws -> String {
    
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

func iso8601DateFormatter() -> DateFormatter{
    let enUSPosixLocale = Locale(localeIdentifier: "en_US_POSIX")
    let dateFormatter = DateFormatter()
    dateFormatter.locale = enUSPosixLocale
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return dateFormatter
}

private func encodedParametersFragment(_ parameters: [AnyObject]) throws -> String {
    var result = ""
    for parameter in parameters {
        
        let encodedParameters = try encode(parameter)
        result += "<param>\n" +
                    encodedParameters +
                  "</param>"
    }
    
    return result
}

private func encode(_ array: [AnyObject]) throws -> String {
    var buffer  = "<value><array><data>"
    
    for object in array {
        buffer += try encode(object)
    }
    
    buffer += "</data></array></value>"
    return buffer
}

private func encode(_ dictionary: [String: AnyObject]) throws -> String {
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

private func valueTag(_ tag: String, value: String) -> String {
    return "<value><\(tag)>\(value)</\(tag)></value>"
}


private func encode(_ boolean: Bool) -> String {
    return valueTag("boolean", value: boolean ? "1" : "0")
}

private func encode(_ int: Int) -> String {
    return valueTag("i4", value: String(int))
}

private func encode(_ double: Double) -> String {
    return valueTag("double", value: String(double))
}


private func encode(_ string: String) -> String {
    
    //escape only XML entities
    let s = NSMutableString(string: string)
    s.replaceOccurrences(of: "&", with:"&amp;", options: .literal, range:NSMakeRange(0, s.length))
    s.replaceOccurrences(of: "\"", with:"&quot;", options: .literal, range:NSMakeRange(0, s.length))
    s.replaceOccurrences(of: "'", with:"&#x27;", options: .literal, range:NSMakeRange(0, s.length))
    s.replaceOccurrences(of: ">", with:"&gt;", options: .literal, range:NSMakeRange(0, s.length))
    s.replaceOccurrences(of: "<", with:"&lt;", options: .literal, range:NSMakeRange(0, s.length))

    return valueTag("string", value: s as String)
}

private func encode(_ date: Date) -> String {
    return valueTag("dateTime.iso8601", value: iso8601DateFormatter().string(from: date))
}

private func encode(_ data: Data)  -> String {
    let encoded = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    return valueTag("base64", value: encoded)
}

private func encode(_ object: AnyObject) throws -> String {
    switch object {
    case let o as [AnyObject]:
        return try encode(o)
    case let o as [String: AnyObject]:
        return try encode(o)
    case is Int:
        return encode(object as! Int)
    case is Double:
        return encode(object as! Double)
    case is Bool:
        return encode(object as! Bool)
    case let o as String:
        return encode(o)
    case let o as Date:
        return encode(o)
    case let o as Data:
        return encode(o)
    default:
        throw XMLRPCEncoderError.unsupportedType
    }
}
