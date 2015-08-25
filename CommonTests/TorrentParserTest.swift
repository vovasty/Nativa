//
//  TorrentParserTest.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/24/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa
import XCTest

class TorrentParserTest: XCTestCase {


    
    func testExample() {
        let text = "d8:announce75:http://tr1.kinozal.tv/announce.php?passkey=55ba92de144986e76bdc6bed842feb2e13:announce-listll75:http://tr1.kinozal.tv/announce.php?passkey=55ba92de144986e76bdc6bed842feb2eel31:http://retracker.local/announceee7:comment40:http://kinozal.tv/details.php?id=12317714:infod5:filesld6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_5.VOBeed6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_6.VOBeed6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_1.VOBeed6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_4.VOBeed6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_3.VOBeed6:lengthi1073739776e4:pathl8:VIDEO_TS12:VTS_07_2.VOBeed6:lengthi958420992e4:pathl8:VIDEO_TS12:VTS_07_7.VOBeed6:lengthi427978752e4:pathl8:VIDEO_TS12:VTS_08_1.VOBeed6:lengthi218165248e4:pathl8:VIDEO_TS12:VTS_09_1.VOBeed6:lengthi19554304e4:pathl8:VIDEO_TS12:VTS_03_1.VOBeed6:lengthi12251136e4:pathl8:VIDEO_TS12:VTS_04_1.VOBeed6:lengthi6025216e4:pathl8:VIDEO_TS12:VTS_07_0.VOBeed6:lengthi1232896e4:pathl8:VIDEO_TS12:VIDEO_TS.VOBeed6:lengthi188416e4:pathl8:VIDEO_TS12:VTS_01_1.VOBeed6:lengthi81920e4:pathl8:VIDEO_TS12:VTS_07_0.IFOeed6:lengthi81920e4:pathl8:VIDEO_TS12:VTS_07_0.BUPeed6:lengthi26624e4:pathl8:VIDEO_TS12:VIDEO_TS.BUPeed6:lengthi26624e4:pathl8:VIDEO_TS12:VIDEO_TS.IFOeed6:lengthi16384e4:pathl8:VIDEO_TS12:VTS_09_0.IFOeed6:lengthi16384e4:pathl8:VIDEO_TS12:VTS_08_0.IFOeed6:lengthi16384e4:pathl8:VIDEO_TS12:VTS_09_0.BUPeed6:lengthi16384e4:pathl8:VIDEO_TS12:VTS_08_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_04_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_02_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_02_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_05_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_06_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_01_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_01_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_03_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_03_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_04_0.BUPeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_05_0.IFOeed6:lengthi14336e4:pathl8:VIDEO_TS12:VTS_06_0.BUPeed6:lengthi8192e4:pathl8:VIDEO_TS12:VTS_05_1.VOBeed6:lengthi8192e4:pathl8:VIDEO_TS12:VTS_02_1.VOBeed6:lengthi8192e4:pathl8:VIDEO_TS12:VTS_06_1.VOBeee4:name44:Воздушный маршал DVD-9_Custom12:piece lengthi4194304e6:pieces3:123ee"
        
        let data: NSData = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        let torrent = BinaryTorrent(data: data)
        
        XCTAssert(torrent["info"]["files"].array!.count == 37, "should be 37")
    }

}
