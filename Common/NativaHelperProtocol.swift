//
//  NativaHelperProtocol.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

@objc public protocol NativaHelperProtocol {
    func connect(user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void)
    func connect(host: String, port: UInt16, connect: (NSError?)->Void)
    func version(response: (String?, NSError?)->Void)
    func update(_: ([[String:AnyObject]]?, NSError?)->Void)->Void
    func update(id: String, handler:([String:AnyObject]?, NSError?)->Void)
    func parseTorrent(data:[NSData], handler:([[String:AnyObject]]?, NSError?)->Void)
    func addTorrentData(data: NSData, start: Bool, group: String?, handler:(NSError?)->Void)
    func startTorrent(id:String, handler:([String:AnyObject]?, NSError?)->Void)
    func stopTorrent(id:String, handler:([String:AnyObject]?, NSError?)->Void)
    func removeTorrent(id: String, path: String?, removeData: Bool, response: (NSError?) -> Void)
    func setFilePriority(id: String, priorities:[Int: Int], handler: (NSError?)->Void)
}

@objc public protocol ConnectionEventListener {
    func connectionDropped(error: NSError?)
}