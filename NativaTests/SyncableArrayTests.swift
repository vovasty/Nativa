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
        
        array.update("1")
        array.update("2")
        array.update("3")
        array.update("4")
        
        XCTAssert(array.containsId("1"))
        XCTAssert(array.containsId("2"))
        XCTAssert(array.containsId("3"))
        XCTAssert(array.containsId("4"))
    }

    func testFilter() {
        let array = SyncableArray<SyncableArrayTests>(delegate: self)
        array.filterHandler { (s) -> Bool in
            return s.compare("4") == .OrderedDescending
        }
        
        array.update("1")
        array.update("2")
        array.update("3")
        array.update("4")
        
        XCTAssert(array.containsId("1"))
        XCTAssert(array.containsId("2"))
        XCTAssert(array.containsId("3"))
        XCTAssertFalse(array.containsId("4"))
    }
    
    func testSorter() {
        let array = SyncableArray<SyncableArrayTests>(delegate: self)
        array.sorter { (a, b) -> Bool in
            return a > b
        }
        
        array.update("1")
        XCTAssertEqual(array[0], "1")
        array.update("2")
        XCTAssertEqual(array[0], "2")
        array.update("3")
        XCTAssertEqual(array[0], "3")
        array.update("4")
        XCTAssertEqual(array[0], "4")
        
        XCTAssertEqual(array[0], "4")
        XCTAssertEqual(array[1], "3")
        XCTAssertEqual(array[2], "2")
        XCTAssertEqual(array[3], "1")
    }
    
    
    //MARK: SyncableArrayDelegate
    func idFromRaw(object: String) -> String? {
        return object
    }
    
    func idFromObject(object: String) -> String {
        return object
    }
    
    func updateObject(source: String, object: String) -> String {
        return object
    }
    
    func createObject(object: String) -> String? {
        return object
    }
}
