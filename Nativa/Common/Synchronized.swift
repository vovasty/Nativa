//
//  Synchronized.swift
//  yumyum
//
//  Created by Vladimir Solomenchuk on 3/3/15.
//  Copyright (c) 2015 Vladimir Solomenchuk. All rights reserved.
//

import Foundation

private let locksTable = MapTable<AnyObject, AnyObject>.weakToWeakObjects()

var locksTableLock = OS_SPINLOCK_INIT

func synchronized(_ obj: AnyObject, f: (Void) -> Void) {
    OSSpinLockLock(&locksTableLock)
    var lock = locksTable.object(forKey: obj) as! RecursiveLock?
    if lock == nil {
        lock = RecursiveLock()
        locksTable.setObject(lock!, forKey: obj)
    }
    
    OSSpinLockUnlock(&locksTableLock)
    
    lock!.lock()
    f()
    lock!.unlock()
}
