//
//  SyncableArray.swift
//  yumyum
//
//  Created by Vladimir Solomenchuk on 12/17/14.
//  Copyright (c) 2014 Vladimir Solomenchuk. All rights reserved.
//

import Foundation

extension Array {
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
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
    case update, insert, delete
}

public class ObservableArray<T> {
    private var observers: [String: ([(object: T, index: Int, type: ChangeType)])->Void] = [:]
    
    init(){}
    
    public func addObserver(_ observer: ([(object: T, index: Int, type: ChangeType)])->Void)->String {
        let id = UUID().uuidString
        
        synchronized(self, f: {
            self.observers[id] = observer
        })
        
        return id
    }
    
    public func removeObserver(_ id: String) {
        observers.removeValue(forKey: id)
    }
    
    internal func notifyObservers(_ changeset: [(object: T, index: Int, type: ChangeType)]) {
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
    
    func id(fromRaw raw: RawType) -> KeyType?
    func id(fromObject object: ObjectType) -> KeyType
    func update(fromRaw raw: RawType, object: ObjectType) -> ObjectType
    func create(fromRaw raw: RawType) -> ObjectType?
}

public enum SyncStrategy {
    case update, replace
}

public class SyncableArray<D: SyncableArrayDelegate>: ObservableArray<D.ObjectType> {
    private var index: [D.KeyType: D.ObjectType] = [:]
    private var order: [D.ObjectType] = []
    public weak var delegate: D!
    public var orderedArray: [D.ObjectType] {get {return order}}
    private var _sorter: ((D.ObjectType, D.ObjectType) -> Bool)?
    private var _filter: ((D.ObjectType) -> Bool)?
    public func sorter(_ sorter: ((D.ObjectType, D.ObjectType) -> Bool)?) {
        self._sorter = sorter
    }
    
    public func filterHandler(_ filter: ((D.ObjectType) -> Bool)?) {
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
    
    private func _append(_ value: D.ObjectType)-> (object: D.ObjectType, index: Int, type: ChangeType)? {
        guard (_filter?(value) ?? true) else { return nil }
        
        let key = delegate.id(fromObject: value)
        index[key] = value
        
        var idx = -1
        if let s = _sorter {
            idx = order.insertionIndexOf(value, isOrderedBefore: s)
            order.insert(value, at: idx)
        }
        else {
            order.append(value)
            idx = order.count - 1
        }
        
        return (object: value, index: idx, type: .insert)
    }
    
    public func indexOf(_ value: D.ObjectType?) -> Int? {
        if let v  = value {
            return order.index(of: v)
        }
        else {
            return nil
        }
    }
    
    public func updateFromObject(_ value: D.ObjectType) {
        let key = delegate.id(fromObject: value)
        let change: (object: D.ObjectType, index: Int, type: ChangeType)?
        if index[key] == nil {
            change = _append(value)
        }
        else {
            let idx = order.index(of: value)!
            change = (object: value, index: idx, type: .update)
        }
        
        guard let chg = change else { return }
        
        index[key] = value
        
        notifyObservers([chg])
    }
    
    private func _remove(_ value: D.ObjectType) -> (object: D.ObjectType, index: Int, type: ChangeType)? {
        index.removeValue(forKey: delegate.id(fromObject: value))
        if let idx = order.index(of: value) {
            return (object: order.remove(at: idx), index: idx, type: .delete)
        }
        
        return nil
    }
    
    @discardableResult
    public func remove(_ value: D.ObjectType) -> D.ObjectType? {
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

    private func _update(_ dict: D.RawType)->[(object: D.ObjectType, index: Int, type: ChangeType)]? {
        guard let id = delegate?.id(fromRaw: dict) else { return nil }
        
        if let object = index[id] {
            let o = delegate.update(fromRaw: dict, object: object)
            if _filter?(o) ?? true {
                let idx = order.index(of: o)!
                
                if let s = _sorter {
                    var newIndex = order.insertionIndexOf(o, isOrderedBefore: s)
                    if idx == newIndex {
                        return [(object: o, index: idx, type: .update)]
                    }
                    
                    order.remove(at: idx)
                    
                    if newIndex > idx {
                        newIndex -= 1
                    }
                    
                    order.insert(o, at: newIndex)
                    return [(object: o, index: idx, type: .delete), (object: o, index: newIndex, type: .insert)]
                }
                else {
                    return [(object: o, index: idx, type: .update)]
                }
            }
            else {
                let change = _remove(o)
                return change == nil ? nil : [change!]
            }
        }
        else if let o = delegate.create(fromRaw: dict) {
            let change = _append(o)
            return change == nil ? nil : [change!]
        }
        else {
            return nil
        }
    }
    
    @discardableResult
    public func update(_ raw: D.RawType)->D.ObjectType? {
        guard let change = _update(raw) else { return nil }
        
        notifyObservers(change)
        return change.first?.object
    }
    
    @discardableResult
    public func update(_ raw: D.RawType, forId: D.KeyType)->D.ObjectType? {
        guard let object = index.removeValue(forKey: forId) else { return nil }
        guard let id = delegate.id(fromRaw: raw) else { return nil }

        index[id] = object
        return update(raw)
    }
    
    @discardableResult
    public func update(_ array: [D.RawType], strategy: SyncStrategy)->[D.ObjectType] {
        var validIds: [D.KeyType: Bool] = [:]
        var result: [D.ObjectType] = []
        var changes: [(object: D.ObjectType, index: Int, type: ChangeType)] = []
        for dict in array {
            if let change = _update(dict) {
                changes.append(contentsOf: change)
                result.append(change.first!.object)
                validIds[delegate.id(fromObject: change.first!.object)] = true
            }
        }
        
        switch strategy {
        case .update:
            break
        case .replace:
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
    
    public func containsId(_ key: D.KeyType) -> Bool {
        return index[key] != nil
    }
}

extension SyncableArray : Sequence {
    public func makeIterator() -> IndexingIterator<[D.ObjectType]> {
        return order.makeIterator()
    }
}
