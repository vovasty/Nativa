//
//  SyncableArray.swift
//  yumyum
//
//  Created by Vladimir Solomenchuk on 12/17/14.
//  Copyright (c) 2014 Vladimir Solomenchuk. All rights reserved.
//

import Foundation

extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}


public enum ChangeType {
    case Update, Insert, Delete
}

public class ObservableArray<T> {
    private var observers: [String: ([(object: T, index: Int, type: ChangeType)])->Void] = [:]
    
    init(){}
    
    public func addObserver(observer: ([(object: T, index: Int, type: ChangeType)])->Void)->String {
        let id = NSUUID().UUIDString
        
        synchronized(self, f: {
            self.observers[id] = observer
        })
        
        return id
    }
    
    public func removeObserver(id: String) {
        observers.removeValueForKey(id)
    }
    
    internal func notifyObservers(changeset: [(object: T, index: Int, type: ChangeType)]) {
        synchronized(self, f: {
            for observer in self.observers.values {
                observer(changeset)
            }
        })
    }
}

public protocol SyncableArrayDelegate: class {
    typealias ValueType: Equatable
    typealias KeyType: Hashable
    
    func idFromDictionary(_: [KeyType: AnyObject]) -> KeyType?
    func idFromObject(_: ValueType) -> KeyType
    func updateObject(dictionary: [KeyType: AnyObject], object: ValueType)
    func createObjectFromDictionary(_: [KeyType: AnyObject]) -> ValueType?
}

public enum SyncStrategy {
    case Update, Replace
}

public class SyncableArray<D: SyncableArrayDelegate>: ObservableArray<D.ValueType> {
    private var index: [D.KeyType: D.ValueType] = [:]
    private var order: [D.ValueType] = []
    public weak var delegate: D!
    public var orderedArray: [D.ValueType] {get {return order}}
    public var sorter: ((D.ValueType, D.ValueType) -> Bool)?
    
    public init(delegate: D){
        super.init()
        self.delegate = delegate
    }
    
    public subscript(id : D.KeyType) -> D.ValueType? {
        get { return index[id] }
    }
    
    public subscript(idx : Int) -> D.ValueType {
        get { return order[idx] }
    }
    
    public var count: Int {
        get { return order.count }
    }
    
    private func _append(value: D.ValueType)-> (object: D.ValueType, index: Int, type: ChangeType) {
        let key = delegate.idFromObject(value)
        index[key] = value
        
        var idx = -1
        if let s = sorter {
            idx = order.insertionIndexOf(value, isOrderedBefore: s)
            order.insert(value, atIndex: idx)
        }
        else {
            order.append(value)
            idx = order.count - 1
            
        }
        
        return (object: value, index: idx, type: .Insert)
    }
    
    public func indexOf(value: D.ValueType?) -> Int? {
        if let v  = value {
            return order.indexOf(v)
        }
        else {
            return nil
        }
    }
    
    public func update(value: D.ValueType) {
        let key = delegate.idFromObject(value)
        let change: (object: D.ValueType, index: Int, type: ChangeType)
        if index[key] == nil {
            change = _append(value)
        }
        else {
            let idx = order.indexOf(value)!
            change = (object: value, index: idx, type: .Update)
        }
        
        index[key] = value

        notifyObservers([change])
    }
    
    private func _remove(value: D.ValueType) -> (object: D.ValueType, index: Int, type: ChangeType)? {
        index.removeValueForKey(delegate.idFromObject(value))
        if let idx = order.indexOf(value) {
            return (object: order.removeAtIndex(idx), index: idx, type: .Delete)
        }
        
        return nil
    }
    
    public func remove(value: D.ValueType) -> D.ValueType? {
        if let result = _remove(value) {
            notifyObservers([result])
            return result.object
        }
        
        return nil
    }
    
    private func _update(dict: [D.KeyType: AnyObject])->(object: D.ValueType, index: Int, type: ChangeType)? {
        if let id = delegate?.idFromDictionary(dict) {
            
            var change: (object: D.ValueType, index: Int, type: ChangeType)!
            
            if let object = index[id] {
                delegate.updateObject(dict, object: object)
                let idx = order.indexOf(object)!
                change = (object: object, index: idx, type: .Update)
            }
            else {
                if let o = delegate.createObjectFromDictionary(dict) {
                    change = _append(o)
                }
            }
            
            return change
        }
        
        return nil
    }
    
    public func update(dict: [D.KeyType: AnyObject])->D.ValueType? {
        if let change = _update(dict) {
            notifyObservers([change])
            return change.object
        }
        
        return nil
    }
    
    public func update(dict: [D.KeyType: AnyObject], forId: D.KeyType)->D.ValueType? {
        if let object = index.removeValueForKey(forId) {
            if let id = delegate.idFromDictionary(dict) {
                index[id] = object
                return update(dict)
            }
        }
        
        return  nil
    }
    
    public func update(array: [[D.KeyType: AnyObject]], strategy: SyncStrategy)->[D.ValueType] {
        var validIds: [D.KeyType: Bool] = [:]
        var result: [D.ValueType] = []
        var changes: [(object: D.ValueType, index: Int, type: ChangeType)] = []
        for dict in array {
            if let change = _update(dict) {
                changes.append(change)
                result.append(change.object)
                validIds[delegate.idFromObject(change.object)] = true
            }
        }
        
        switch strategy {
        case .Update:
            break
        case .Replace:
            var invalidObjs: [D.ValueType] = []
            for (k, v) in index {
                if validIds[k] == nil {
                    invalidObjs.append(v)
                }
            }
            
            for o in invalidObjs {
                if let change = _remove(o) {
                    changes.append(change)
                }
            }
        }
        
        if changes.count > 0 {
            notifyObservers(changes)
        }
        
        return result
    }
    
    public func containsId(key: D.KeyType) -> Bool {
        return index[key] != nil
    }
}

extension SyncableArray : SequenceType {
    public func generate() -> IndexingGenerator<[D.ValueType]> {
        return order.generate()
    }
}