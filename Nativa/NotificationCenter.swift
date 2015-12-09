//
//  NotificationCenter.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/8/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

private protocol Entry {
    var element: ClosurePointer? {get set}
    func valid() -> Bool
}

private struct WeakEntry: Entry {
    weak var element: ClosurePointer?
    func valid() -> Bool {
        return element != nil
    }
}

private struct StrongEntry: Entry {
    var element: ClosurePointer?
    private var _valid : () -> Bool
    
    func valid() -> Bool {
        
        if !_valid() {
            return false
        } else {
            return true
        }
    }
    
    init(owner o: AnyObject?, element: ClosurePointer) {
        if o == nil {
            _valid = { true }
        } else {
            _valid = { [weak o] in o != nil }
        }
        self.element = element
    }
}


private class ClosurePointer {
    private let id = NSUUID()
    var value: ((Any) -> Void)?
    
    init (_ value: (Any) -> Void) {
        self.value = value
    }
}

extension ClosurePointer: Equatable {}

private func ==(lhs: ClosurePointer, rhs: ClosurePointer) -> Bool {
    return lhs.id == rhs.id
}

class EventEmitter {
    private var listeners: [Entry] = []
    private var valueSet: Bool = false
    
    init () {
    }
    
    func add<T>(owner: AnyObject? = nil, listener: (T) -> Void) -> AnyObject {
        let cmd = ClosurePointer{(arg) in
            if let arg = arg as? T {
                listener(arg)
            }
        }
        let entry: Entry
        
        if owner == nil {
            entry = WeakEntry(element: cmd)
        }
        else {
            entry = StrongEntry(owner: owner, element: cmd)
        }
        listeners.append(entry)
        return cmd
    }
    
    func remove(listener: AnyObject?) {
        listeners = listeners.filter{
            return $0.element == nil || $0.element != listener as? ClosurePointer
        }
    }

    func removeAll() {
        listeners = []
    }

    func emit(value: Any) {
        listeners = listeners.filter{
            $0.valid()
        }
        
        for listener in listeners {
            listener.element?.value?(value)
        }
    }
}


extension EventEmitter {
    func emitOnMain<T>(arg: T) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            self?.emit(arg)
        }
    }
}

protocol Notification {
    
}

extension EventEmitter{
    func post(note: Notification) {
        emit(note)
    }
    
    func postOnMain(note: Notification) {
        emitOnMain(note)
    }
}

let notificationCenter = EventEmitter()