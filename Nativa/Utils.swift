//
//  Utils.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/9/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

extension String {
    var pathExtension: String {
        return NSString(string: self).pathExtension
    }
    
    func hosAndPort(port: UInt16) -> (host: String, port: UInt16) {
        let hp = self.characters.split(":")
        if hp.count == 2 {
            return (host: String(hp[0]), port: UInt16(String(hp[1])) ?? port)
        }
        else {
            return (host: self, port: port)
        }
    }
}

extension NSUserDefaults {
    public subscript(keypath : String) -> AnyObject? {
        get { return self.valueForKey(keypath) }
        set { self.setObject(newValue, forKey: keypath) }
    }
}

//http://stackoverflow.com/a/24219069/449547
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}
extension Dictionary {
    func map<OutKey: Hashable, OutValue>(transform: Element -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(self.map(transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key: Value] {
        return Dictionary(self.filter(includeElement))
    }
}

extension NSView {
    func findSubview<T>()->T? {
        for v in subviews {
            if let k = v as? T {
                return k
            }
        }
        
        return nil
    }
}

func dispatch_main( closure: ()-> Void) {
    dispatch_async(dispatch_get_main_queue()) { closure() }
}