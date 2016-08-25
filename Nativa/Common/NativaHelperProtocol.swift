//
//  NativaHelperProtocol.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

@objc public protocol NativaHelperProtocol {
    func connect(_ user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: @escaping (Error?)->Void)
    func connect(_ host: String, port: UInt16, connect: @escaping (Error?)->Void)
    func version(_ response: @escaping (String?, Error?)->Void)
    func update(_: @escaping  ([[String:Any]]?, Error?)->Void)->Void
    func update(_ id: String, handler: @escaping ([String:Any]?, Error?)->Void)
    func parseTorrent(_ data:[Data], handler: @escaping ([[String:Any]]?, Error?)->Void)
    func addTorrentData(_ id: String, data: Data, priorities: [Int: Int]?, folder: String?, start: Bool, group: String?, handler: @escaping (Error?)->Void)
    func startTorrent(_ id:String, handler: @escaping ([String:Any]?, Error?)->Void)
    func stopTorrent(_ id:String, handler: @escaping ([String:Any]?, Error?)->Void)
    func removeTorrent(_ id: String, path: String?, removeData: Bool, response: @escaping (Error?) -> Void)
    func setFilePriority(_ id: String, priorities:[Int: Int], handler: @escaping (Error?)->Void)
    func getStats(_ handler: @escaping ([String:Any]?, Error?)->Void)
    func setMaxDownloadSpeed(_ speed: Int, handler: @escaping (Error?)->Void)
    func setMaxUploadSpeed(_ speed: Int, handler: @escaping (Error?)->Void)
}

@objc public protocol ConnectionEventListener {
    func connectionDropped(withError error: Error?)
}
