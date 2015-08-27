//
//  HelperTests.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/22/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import XCTest
@testable import Nativa

class HelperTests: XCTestCase {
    
    func testUpdateAll() {
        var expectation = expectationWithDescription("connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
     
        waitForExpectationsWithTimeout(100, handler: nil)
        
        expectation = expectationWithDescription("update")
        
        helper.update { (result, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertNotEqual(result?.count, 0)
            
            
            XCTAssertNotNil(result?.first?["info"])
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
    }
    
    func testUpdateSingle() {
        var expectation = expectationWithDescription("connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
        
        expectation = expectationWithDescription("update")
        
        helper.update ("8B3696F4B1EACBECE1917FBCC3FC4D13C2B475EA") { (result, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertNotEqual(result?.count, 0)
            
            let d = Download(result!)
            XCTAssertNotNil(d)
            XCTAssertNotEqual(d?.flatFileList?.count, 0)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
    }
    
    func testSetPriority() {
        var expectation = expectationWithDescription("connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
        
        expectation = expectationWithDescription("update")
        
        helper.setFilePriority("8B3696F4B1EACBECE1917FBCC3FC4D13C2B475EA", priorities: [0:0, 1:1, 2:2]) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(100, handler: nil)
    }
    
    func testRawConnection() {
        var expectation = expectationWithDescription("connect")
        
        let helper = NativaHelper()
        helper.connect("127.0.0.1", port: 5000)
        { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
        
        expectation = expectationWithDescription("version")
        
        helper.version { (version, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(version)
            print(version)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(100, handler: nil)
    }
}
