//
//  Datasource.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/6/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation
import Common


private var parseTorrentsLock: OSSpinLock = OS_SPINLOCK_INIT

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
        guard let info = dict["info"] as? [String: AnyObject], let id = info["id"] as? String else {
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

class Datasource {
    let downloaderService = NSXPCConnection(serviceName: "net.aramzamzam.Nativa.NativaHelper")
    var downloader: NativaHelperProtocol!
    private let downloadsSyncableArrayDelegate = DownloadsSyncableArrayDelegate()
    let downloads: SyncableArray<DownloadsSyncableArrayDelegate>

    
    static let instance = Datasource()
    
    required init(){
        
        downloaderService.remoteObjectInterface = contructInterfaceForNativaHelper()
        downloaderService.resume()

        downloads = SyncableArray(delegate: downloadsSyncableArrayDelegate)
    }
    
    func connect(user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void) {
        
        downloader = downloaderService.remoteObjectProxyWithErrorHandler {
            (error) in
            
            OSSpinLockUnlock(&parseTorrentsLock)
            
            connect(error)
            
            } as! NativaHelperProtocol
        
        downloader.connect(user, host: host, port: port, password: password, serviceHost: serviceHost, servicePort: servicePort) { (error) -> Void in
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
                print("failed to stop torrent \(error)")
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
                print("failed to start torrent \(error)")
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
                print(error)
                return
            }
            
            self.downloads.update(result, strategy: SyncStrategy.Replace)
        }
    }
    
    func update(download: Download,  handler: (Download?, NSError?) -> Void) {
        downloader.update(download.id) {(result, error)->Void in
            guard let result = result where error == nil else {
                handler(nil, error)
                return
            }
            
            self.downloads.update(result)
            handler(download, nil)
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
    
    func parseTorrents(files:[String]) throws ->[Download]? {
        OSSpinLockLock(&parseTorrentsLock)
        defer { OSSpinLockUnlock(&parseTorrentsLock) }
        
        var result: [Download]?
        var torrentDatas: [NSData] = []
        for file in files {
            let torrentData: NSData = try NSData(contentsOfFile:file, options: NSDataReadingOptions(rawValue: 0))
            torrentDatas.append(torrentData)
        }
        
        downloader.parseTorrent(torrentDatas) { (parsed, error) -> Void in
            guard let parsed = parsed where error == nil else{
                return
            }
            defer { OSSpinLockUnlock(&parseTorrentsLock) }
            
            result = []
            for parsedTorrent in parsed {
                if let download = Download(parsedTorrent) {
                    result!.append(download)
                }
            }
        }
        
        OSSpinLockLock(&parseTorrentsLock)
        return result;
    }
    
    func addTorrentFiles(files: [(path: String, download: Download)]) throws {
        for file in files {
            let torrentData: NSData = try NSData(contentsOfFile:file.path, options: NSDataReadingOptions(rawValue: 0))
            downloads.append(file.download)
            downloader.addTorrentData(torrentData, start: false, group: nil, handler: { (error) -> Void in
                print(error)
            })
        }
    }
    
    func addTorrentFiles(urls: [NSURL]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            for url in urls {
                if let torrentData: NSData = NSData(contentsOfURL: url) {
                    self.downloader.addTorrentData(torrentData, start: false, group: nil, handler: { (error) -> Void in
                        if let error = error {
                            print("unable to add torrent \(error)")
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

}