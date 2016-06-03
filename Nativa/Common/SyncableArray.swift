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
    associatedtype RawType: Any
    associatedtype ObjectType: Equatable
    associatedtype KeyType: Hashable
    
    func idFromRaw(_: RawType) -> KeyType?
    func idFromObject(_: ObjectType) -> KeyType
    func updateObject(raw: RawType, object: ObjectType) -> ObjectType
    func createObject(_: RawType) -> ObjectType?
}

public enum SyncStrategy {
    case Update, Replace
}

public class SyncableArray<D: SyncableArrayDelegate>: ObservableArray<D.ObjectType> {
    private var index: [D.KeyType: D.ObjectType] = [:]
    private var order: [D.ObjectType] = []
    public weak var delegate: D!
    public var orderedArray: [D.ObjectType] {get {return order}}
    private var _sorter: ((D.ObjectType, D.ObjectType) -> Bool)?
    private var _filter: ((D.ObjectType) -> Bool)?
    public func sorter(sorter: ((D.ObjectType, D.ObjectType) -> Bool)?) {
        self._sorter = sorter
    }
    
    public func filterHandler(filter: ((D.ObjectType) -> Bool)?) {
        self._filter = filter
    }
    
    required public init(delegate: D){
        super.init()
        self.delegate = delegate
    }
    
    public subscript(id : D.KeyType) -> D.ObjectType? {
        get { return index[id] }
    }
    
    public subscript(idx : Int) -> D.ObjectType {
        get { return order[idx] }
    }
    
    public var count: Int {
        get { return order.count }
    }
    
    private func _append(value: D.ObjectType)-> (object: D.ObjectType, index: Int, type: ChangeType)? {
        guard (_filter?(value) ?? true) else { return nil }
        
        let key = delegate.idFromObject(value)
        index[key] = value
        
        var idx = -1
        if let s = _sorter {
            idx = order.insertionIndexOf(value, isOrderedBefore: s)
            order.insert(value, atIndex: idx)
        }
        else {
            order.append(value)
            idx = order.count - 1
        }
        
        return (object: value, index: idx, type: .Insert)
    }
    
    public func indexOf(value: D.ObjectType?) -> Int? {
        if let v  = value {
            return order.indexOf(v)
        }
        else {
            return nil
        }
    }
    
    public func updateFromObject(value: D.ObjectType) {
        let key = delegate.idFromObject(value)
        let change: (object: D.ObjectType, index: Int, type: ChangeType)?
        if index[key] == nil {
            change = _append(value)
        }
        else {
            let idx = order.indexOf(value)!
            change = (object: value, index: idx, type: .Update)
        }
        
        guard let chg = change else { return }
        
        index[key] = value
        
        notifyObservers([chg])
    }
    
    private func _remove(value: D.ObjectType) -> (object: D.ObjectType, index: Int, type: ChangeType)? {
        index.removeValueForKey(delegate.idFromObject(value))
        if let idx = order.indexOf(value) {
            return (object: order.removeAtIndex(idx), index: idx, type: .Delete)
        }
        
        return nil
    }
    
    public func remove(value: D.ObjectType) -> D.ObjectType? {
        if let result = _remove(value) {
            notifyObservers([result])
            return result.object
        }
        
        return nil
    }

    public func removeAll() {
        var changes: [(object: D.ObjectType, index: Int, type: ChangeType)] = []
        for o in order {
            guard let result = _remove(o) else { continue }
            changes.append(result)
        }
        notifyObservers(changes)
    }

    private func _update(dict: D.RawType)->[(object: D.ObjectType, index: Int, type: ChangeType)]? {
        guard let id = delegate?.idFromRaw(dict) else { return nil }
        
        if let object = index[id] {
            let o = delegate.updateObject(dict, object: object)
            if _filter?(o) ?? true {
                let idx = order.indexOf(o)!
                
                if let s = _sorter {
                    var newIndex = order.insertionIndexOf(o, isOrderedBefore: s)
                    if idx == newIndex {
                        return [(object: o, index: idx, type: .Update)]
                    }
                    
                    order.removeAtIndex(idx)
                    
                    if newIndex > idx {
                        newIndex -= 1
                    }
                    
                    order.insert(o, atIndex: newIndex)
                    return [(object: o, index: idx, type: .Delete), (object: o, index: newIndex, type: .Insert)]
                }
                else {
                    return [(object: o, index: idx, type: .Update)]
                }
            }
            else {
                let change = _remove(o)
                return change == nil ? nil : [change!]
            }
        }
        else if let o = delegate.createObject(dict) {
            let change = _append(o)
            return change == nil ? nil : [change!]
        }
        else {
            return nil
        }
    }
    
    public func update(raw: D.RawType)->D.ObjectType? {
        guard let change = _update(raw) else { return nil }
        
        notifyObservers(change)
        return change.first?.object
    }
    
    public func update(raw: D.RawType, forId: D.KeyType)->D.ObjectType? {
        guard let object = index.removeValueForKey(forId) else { return nil }
        guard let id = delegate.idFromRaw(raw) else { return nil }

        index[id] = object
        return update(raw)
    }
    
    public func update(array: [D.RawType], strategy: SyncStrategy)->[D.ObjectType] {
        var validIds: [D.KeyType: Bool] = [:]
        var result: [D.ObjectType] = []
        var changes: [(object: D.ObjectType, index: Int, type: ChangeType)] = []
        for dict in array {
            if let change = _update(dict) {
                changes.appendContentsOf(change)
                result.append(change.first!.object)
                validIds[delegate.idFromObject(change.first!.object)] = true
            }
        }
        
        switch strategy {
        case .Update:
            break
        case .Replace:
            var invalidObjs: [D.ObjectType] = []
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
    public func generate() -> IndexingGenerator<[D.ObjectType]> {
        return order.generate()
    }
}
