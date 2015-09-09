//
//  NotificationCenter.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/8/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

private struct Entry<T where T: AnyObject> {
    typealias Element = T
    weak var element: Element?
}

private class ListenerPointer {
    private let id = NSUUID()
    var value: ((Any) -> Void)?
    init (_ value: (Any) -> Void) {
        self.value = value
    }
}

extension ListenerPointer: Equatable {}

private func ==(lhs: ListenerPointer, rhs: ListenerPointer) -> Bool {
    return lhs.id == rhs.id
}

class EventEmitter {
    private var listeners: [Entry<ListenerPointer>] = []
    private var valueSet: Bool = false
    
    init () {
    }
    
    func add<T>(listener: (T) -> Void) -> AnyObject {
        let cmd = ListenerPointer{(arg) in
            print(arg)
            if let arg = arg as? T {
                listener(arg)
            }
        }
        let entry = Entry(element: cmd)
        listeners.append(entry)
        return cmd
    }
    
    func remove(listener: AnyObject?) {
        listeners = listeners.filter({ (entry) -> Bool in
            return entry.element == nil || entry.element != listener as? ListenerPointer
        })
    }
    
    func emit(value: Any) {
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

class NotificationCenter{
    private let eventListeners = EventEmitter()
    
    func add<T>(name: String, listener: (T) -> Void) -> AnyObject {
        return eventListeners.add({ (note: (String, Any)) -> Void in
            if let arg = note.1 as? T where name == note.0 {
                listener(arg)
            }
        })
    }
    
    func post(name: String, info: Any) {
        eventListeners.emit((name, info))
    }
    
    func remove(listener: AnyObject) {
        eventListeners.remove(listener)
    }
}

extension NotificationCenter{
    func postOnMain(name: String, info: Any) {
        eventListeners.emitOnMain((name, info))
    }
}

let notificationCenter = NotificationCenter()