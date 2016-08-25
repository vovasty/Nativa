//
//  BCodeTests.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/4/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import XCTest

class BCodeTests: XCTestCase {

    fileprivate func multiTorrentData() -> Data {
        let path = Bundle(for: self.classForCoder).resourcePath! + "/multi.torrent"
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    fileprivate func singleTorrentData() -> Data {
        let path = Bundle(for: self.classForCoder).resourcePath! + "/single.torrent"
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    fileprivate func badTorrentData() -> Data {
        let path = Bundle(for: self.classForCoder).resourcePath! + "/bad.torrent"
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }

    
    func testBDecodeMulti() {
        let torrent: ([String: AnyObject], String?) = try! bdecode(multiTorrentData())!
        XCTAssertNotNil(torrent.0["info"])
        let files = (torrent.0["info"] as! [String: AnyObject])["files"]
        XCTAssertEqual(files?.count, 318)
    }
    
    func testBDecodeSingle() {
        let torrent: ([String: AnyObject], String?) = try! bdecode(singleTorrentData())!
        XCTAssertNotNil(torrent.0["info"])
        let files = (torrent.0["info"] as! [String: AnyObject])["files"]
        XCTAssertNil(files)
    }
    
    
    func testBDecodeBad() {
        let torrent: ([String: AnyObject], String?) = try! bdecode(badTorrentData())!
        XCTAssertNotNil(torrent.0["info"])
        let files = (torrent.0["info"] as! [String: AnyObject])["files"]
        XCTAssertNotNil(files)
    }

}
