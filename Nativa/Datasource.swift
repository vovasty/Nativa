//
//  Datasource.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/6/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

enum NativaError: ErrorType {
    case UnknownError(message: String)
}


let DatasourceConnectionStateDidChange = "net.aramzamzam.Nativa.DatasourceConnectionStateDidChange"

enum DatasourceConnectionStatus {
    case Disconnected(error: NSError?)
    case Establishing
    case Established
}

class GroupsSyncableArrayDelegate: SyncableArrayDelegate {
    
    func idFromDictionary(dict: [String: AnyObject]) -> String? {
        return dict["id"] as? String
    }
    
    func idFromObject(o: Group) -> String {
        return o.id
    }
    
    func updateObject(dictionary: [String: AnyObject], object: Group) {
        object.update(dictionary)
    }
    
    func createObjectFromDictionary(dict: [String: AnyObject]) -> Group? {
        if let id = idFromDictionary(dict) {
            let object = Group(id: id)
            updateObject(dict, object: object)
            return object
        }
        
        return nil
    }
    
}

class DownloadsSyncableArrayDelegate: SyncableArrayDelegate {
    func idFromDictionary(dict: [String: AnyObject]) -> String? {
        guard let info = dict["info"] as? [String: AnyObject], let id = (info["id"] as? String)?.uppercaseString else {
            return nil
        }
        
        return id
    }
    
    func idFromObject(o: Download) -> String {
        return o.id
    }
    
    func updateObject(dictionary: [String: AnyObject], object: Download) {
        object.update(dictionary)
    }
    
    func createObjectFromDictionary(dict: [String: AnyObject]) -> Download? {
        return Download(dict)
    }
}

class Datasource: ConnectionEventListener {
    var downloaderService: NSXPCConnection?
    var downloader: NativaHelperProtocol!
    private let downloadsSyncableArrayDelegate = DownloadsSyncableArrayDelegate()
    let downloads: SyncableArray<DownloadsSyncableArrayDelegate>
    
    private (set) var connectionState = DatasourceConnectionStatus.Disconnected(error: nil) {
        didSet{
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(DatasourceConnectionStateDidChange, object: self)
            }
        }
    }

    static let instance = Datasource()
    
    init(){
        downloads = SyncableArray(delegate: downloadsSyncableArrayDelegate)
    }
    
    private func createDownloader(erroHandler: (NSError)->Void) throws -> (NSXPCConnection, NativaHelperProtocol) {
        let downloaderService = NSXPCConnection(serviceName: "\(NSBundle.mainBundle().bundleIdentifier!).NativaHelper")
        
        downloaderService.remoteObjectInterface = NSXPCInterface(`withProtocol`: NativaHelperProtocol.self)
        downloaderService.exportedInterface = NSXPCInterface(`withProtocol`: ConnectionEventListener.self)
        downloaderService.exportedObject = self
        downloaderService.resume()
        
        let downloader = downloaderService.remoteObjectProxyWithErrorHandler {
            (error) in
            
            erroHandler(error)
            
            } as! NativaHelperProtocol
        
        return (downloaderService, downloader)
    }
    
    func connect(user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void) {
        
        connectionState = .Establishing
        
        do {
            let result = try createDownloader{(error)->Void in
                self.connectionState = .Disconnected(error: error)
                connect(NSError(error))
            }
            
            downloaderService = result.0
            downloader = result.1
        }
        catch let error {
            let err = NSError(error)
            connectionState = .Disconnected(error: err)
            connect(err)
        }

        downloader.connect(user, host: host, port: port, password: password, serviceHost: serviceHost, servicePort: servicePort) { (error) -> Void in
            
            if error == nil {
                self.connectionState = .Established
            }
            else {
                self.connectionState = .Disconnected(error: error)
            }

            connect(error)
        }
    }
    
    func connect(host: String, port: UInt16, connect: (NSError?)->Void) {
        connectionState = .Establishing
        
        do {
            let result = try createDownloader{(error)->Void in
                self.connectionState = .Disconnected(error: error)
                connect(NSError(error))
            }
            
            downloaderService = result.0
            downloader = result.1
        }
        catch let error {
            let err = NSError(error)
            connectionState = .Disconnected(error: err)
            connect(err)
        }
        
        downloader.connect(host, port: port) { (error) -> Void in
            if error == nil {
                self.connectionState = .Established
            }
            else {
                self.connectionState = .Disconnected(error: error)
            }
            
            connect(error)
        }
    }
    
    func version(response: (String?, NSError?)->Void) {
        self.downloader.version { (version, error) -> Void in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                response(version, error)
            }
        }
    }
    
    func stopDownload(download: Download){
        downloads.update(["info": ["id": download.id, "active": false, "opened": false, "state": 1, "completed": false, "hashChecking": false]])
        downloader.stopTorrent(download.id) { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("failed to stop torrent \(error)")
                let message = error == nil ? "unable to stop torrent" : error!.localizedDescription
                self.downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            self.downloads.update(result)
        }
    }

    func startDownload(download: Download){
        downloads.update(["info": ["id": download.id, "active": true, "opened": true, "state": 1, "completed": false, "hashChecking": false]])
        downloader.startTorrent(download.id) { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("failed to start torrent \(error)")
                let message = error == nil ? "unable to start torrent" : error!.localizedDescription
                self.downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            self.downloads.update(result)
        }
    }

    func update()
    {
        downloader.update { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("unable to update torrents list \(error)")
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.downloads.update(result, strategy: SyncStrategy.Replace)
            })
        }
    }
    
    func update(download: Download,  handler: (Download?, NSError?) -> Void) {
        downloader.update(download.id) {(result, error)->Void in
            guard let result = result where error == nil else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(nil, error)
                })
                return
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.downloads.update(result)
                handler(download, nil)
            })
        }
    }
    
    func setFilePriority(download: Download, priorities:[FileListNode: Int], handler: (NSError?)->Void) {
        let pr = priorities.map { (file, priority) -> (Int, Int) in
            //immediately set priorities
            file.priority = DownloadPriority(rawValue: priority)!
            return (file.index!, priority)
        }
        
        downloader.setFilePriority(download.id, priorities: pr, handler: handler)
    }
    
    func parseTorrents(files:[String], handler: ([(path: String, download: Download)]?, NSError?)->Void){
        var torrentDatas: [NSData] = []
        
        do {
            for file in files {
                let torrentData: NSData = try NSData(contentsOfFile:file, options: NSDataReadingOptions(rawValue: 0))
                torrentDatas.append(torrentData)
            }
        }
        catch let error {
            handler(nil, NSError(error))
            return
        }
        
        downloader.parseTorrent(torrentDatas) { (parsed, error) -> Void in

            guard let parsed = parsed where error == nil else {
                handler(nil, error)
                return
            }
            
            let result = parsed.enumerate().map{ (index, parsedTorrent) -> (path: String, download: Download?) in
                return (path: files[index], download: Download(parsedTorrent))
            }
            .filter{(d) -> Bool in
                    d.download != nil
            }
            .map({ (e) -> (path: String, download: Download) in
                return (path: e.path, download: e.download!)
            })
            
            handler(result, nil)
        }
    }
    
    func addTorrentFiles(files: [(path: String, download: Download)]) throws {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            for file in files {
                guard !self.downloads.contains(file.download) else{
                    continue
                }

                do {
                    let torrentData: NSData = try NSData(contentsOfFile:file.path, options: NSDataReadingOptions(rawValue: 0))
                    self.downloads.update(file.download)
                    self.downloader.addTorrentData(torrentData, start: false, group: nil, handler: { (error) -> Void in
                        logger.error("unable to add torrent \(error)")
                    })
                }
                catch let error {
                    logger.error("unable to add torrent \(error)")
                }
            }
        }
    }
    
    func addTorrentFiles(urls: [NSURL]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            for url in urls {
                if let torrentData: NSData = NSData(contentsOfURL: url) {
                    self.downloader.addTorrentData(torrentData, start: false, group: nil, handler: { (error) -> Void in
                        if let error = error {
                            logger.error("unable to add torrent \(error)")
                        }
                    })
                }
                self.update()
            }
        }
    }
    
    func removeTorrent(download: Download, removeData: Bool, response:(NSError?) -> Void) {
        self.downloads.remove(download)
        downloader.removeTorrent(download.id, path: download.dataPath, removeData: removeData, response: response)
    }

    //MARK: ConnectionEventListener
    @objc func connectionDropped(error: NSError?) {
        logger.error("connection dropped \(error)")
        self.connectionState = .Disconnected(error: error)
    }
}