//
//  Utils.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/15/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

//throwable map for array
extension Array {
    func map<T>( _ transform: (Iterator.Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for x in self {
            result.append(try transform(x))
        }
        return result
    }
}

//throwable map for dictionary
extension EnumeratedSequence {
    func map<T>( _ transform: (Iterator.Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for x in self {
            result.append(try transform(x))
        }
        return result
    }
}

//combine dicionaries
func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

func + <KeyType, ValueType> (left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) -> Dictionary<KeyType, ValueType> {
    
    var res = left
    for (k, v) in right {
        res.updateValue(v, forKey: k)
    }
    
    return res
}
