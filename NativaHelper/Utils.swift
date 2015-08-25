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
    func map<T>(@noescape transform: (Generator.Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for x in self {
            result.append(try transform(x))
        }
        return result
    }
}

//throwable map for dictionary
extension EnumerateSequence {
    func map<T>(@noescape transform: (Generator.Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for x in self {
            result.append(try transform(x))
        }
        return result
    }
}

//combine dicionaries
func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
