//
//  SyncableArrayTests.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 12/10/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import XCTest

class SyncableArrayTests: XCTestCase, SyncableArrayDelegate {


    func testAppend() {
        let array = SyncableArray<SyncableArrayTests>(delegate: self)
        
        array.update(1)
        array.update(2)
        array.update(3)
        array.update(4)
        
        XCTAssert(array.containsId(1))
        XCTAssert(array.containsId(2))
        XCTAssert(array.containsId(3))
        XCTAssert(array.containsId(4))
    }

    func testFilter() {
        let array = SyncableArray<SyncableArrayTests>(delegate: self)
        array.filterHandler { (num) -> Bool in
            return num < 4
        }
        
        array.update(1)
        array.update(2)
        array.update(3)
        array.update(4)
        
        XCTAssert(array.containsId(1))
        XCTAssert(array.containsId(2))
        XCTAssert(array.containsId(3))
        XCTAssertFalse(array.containsId(4))
    }
    
    
    //MARK: SyncableArrayDelegate
    func idFromRaw(object: Int) -> Int? {
        return object
    }
    
    func idFromObject(object: Int) -> Int {
        return object
    }
    
    func updateObject(source: Int, object: Int) -> Int {
        return object
    }
    
    func createObject(object: Int) -> Int? {
        return object
    }
}
