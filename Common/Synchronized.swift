//
//  Synchronized.swift
//  yumyum
//
//  Created by Vladimir Solomenchuk on 3/3/15.
//  Copyright (c) 2015 Vladimir Solomenchuk. All rights reserved.
//

import Foundation

private let locksTable = NSMapTable.weakToWeakObjectsMapTable()
var locksTableLock = OS_SPINLOCK_INIT

func synchronized(obj: AnyObject, f: Void -> Void) {
    OSSpinLockLock(&locksTableLock)
//    var lock = locksTable.objectForKey(obj) as! NSRecursiveLock?
    var lock = locksTable.objectForKey(obj) as! NSRecursiveLock?
    if lock == nil {
        lock = NSRecursiveLock()
        locksTable.setObject(lock!, forKey: obj)
    }
    
    OSSpinLockUnlock(&locksTableLock)
    
    lock!.lock()
    f()
    lock!.unlock()
}
