//
//  NativaHelperProtocol.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

@objc public protocol NativaHelperProtocol {
    func connect(_ user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void)
    func connect(_ host: String, port: UInt16, connect: (NSError?)->Void)
    func version(_ response: (String?, NSError?)->Void)
    func update(_: ([[String:AnyObject]]?, NSError?)->Void)->Void
    func update(_ id: String, handler:([String:AnyObject]?, NSError?)->Void)
    func parseTorrent(_ data:[Data], handler:([[String:AnyObject]]?, NSError?)->Void)
    func addTorrentData(_ id: String, data: Data, priorities: [Int: Int]?, folder: String?, start: Bool, group: String?, handler:(NSError?)->Void)
    func startTorrent(_ id:String, handler:([String:AnyObject]?, NSError?)->Void)
    func stopTorrent(_ id:String, handler:([String:AnyObject]?, NSError?)->Void)
    func removeTorrent(_ id: String, path: String?, removeData: Bool, response: (NSError?) -> Void)
    func setFilePriority(_ id: String, priorities:[Int: Int], handler: (NSError?)->Void)
    func getStats(_ handler:([String:AnyObject]?, NSError?)->Void)
    func setMaxDownloadSpeed(_ speed: Int, handler:(NSError?)->Void)
    func setMaxUploadSpeed(_ speed: Int, handler:(NSError?)->Void)
}

@objc public protocol ConnectionEventListener {
    func connectionDropped(withError error: NSError?)
}
