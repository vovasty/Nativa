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
    
    fileprivate func multiTorrentData() -> Data {
        let path = Bundle(for: self.classForCoder).resourcePath! + "/multi.torrent"
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    fileprivate func singleTorrentData() -> Data {
        let path = Bundle(for: self.classForCoder).resourcePath! + "/single.torrent"
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    func testUpdateAll() {
        var expectation = self.expectation(description: "connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
     
        waitForExpectations(timeout: 100, handler: nil)
        
        expectation = self.expectation(description: "update")
        
        helper.update { (result, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertNotEqual(result?.count, 0)
            
            
            XCTAssertNotNil(result?.first?["info"])
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testUpdateSingle() {
        var expectation = self.expectation(description: "connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
        
        expectation = self.expectation(description: "update")
        
        helper.update ("8B3696F4B1EACBECE1917FBCC3FC4D13C2B475EA") { (result, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertNotEqual(result?.count, 0)
            
            let d = Download(result!)
            XCTAssertNotNil(d)
            XCTAssertNotEqual(d?.flatFileList?.count, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testSetPriority() {
        var expectation = self.expectation(description: "connect")
        
        let helper = NativaHelper()
        helper.connect("vovasty", host: "127.0.0.1", port: 2222, password: "3Dk@hmPC", serviceHost: "127.0.0.1", servicePort: 5000) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
        
        expectation = self.expectation(description: "update")
        
        helper.setFilePriority("8B3696F4B1EACBECE1917FBCC3FC4D13C2B475EA", priorities: [0:0, 1:1, 2:2]) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testRawConnection() {
        var expectation = self.expectation(description: "connect")
        
        let helper = NativaHelper()
        helper.connect("127.0.0.1", port: 5000)
        { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
        
        expectation = self.expectation(description: "version")
        
        helper.version { (version, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(version)
            print(version)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testAddDownload() {
        var expectation = self.expectation(description: "connect")
        
        let helper = NativaHelper()
        helper.connect("127.0.0.1", port: 5000)
            { (error) -> Void in
                XCTAssertNil(error)
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
        
        expectation = self.expectation(description: "upload")
        
        helper.addTorrentData("8B3696F4B1EACBECE1917FBCC3FC4D13C2B475EA", data: multiTorrentData(), priorities: [0:0, 4:0, 2: 1], folder: "/tmp/tmp", start: false, group: nil) { (error) -> Void in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }

}
