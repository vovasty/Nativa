//
//  BCodeTests.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/4/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import XCTest

class BCodeTests: XCTestCase {

    private func multiTorrentData() -> NSData {
        let path = NSBundle(forClass: self.classForCoder).resourcePath!.stringByAppendingString("/multi.torrent")
        return NSData(contentsOfFile: path)!
    }
    
    private func singleTorrentData() -> NSData {
        let path = NSBundle(forClass: self.classForCoder).resourcePath!.stringByAppendingString("/single.torrent")
        return NSData(contentsOfFile: path)!
    }
    
    func testBDecode() {
        let torrent: [String: AnyObject] = try! bdecode(multiTorrentData())!
        XCTAssertNotNil(torrent["info"])
        let files = (torrent["info"] as! [String: AnyObject])["files"]
        XCTAssertEqual(files?.count, 318)
    }
}
