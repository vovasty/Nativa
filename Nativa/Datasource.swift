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


struct DatasourceConnectionStateDidChange: Notification {
    let state: DatasourceConnectionStatus
}

enum DatasourceConnectionStatus {
    case Disconnected(error: NSError?)
    case Establishing
    case Established
}


class DownloadsSyncableArrayDelegate: SyncableArrayDelegate {
    var processId: String
    
    init(processId: String) {
        self.processId = processId
    }
    
    func idFromRaw(dict: [String: AnyObject]) -> String? {
        guard let info = dict["info"] as? [String: AnyObject], let id = (info["id"] as? String)?.uppercaseString else {
            return nil
        }
        
        return id
    }
    
    func idFromObject(o: Download) -> String {
        return o.id
    }
    
    func updateObject(dictionary: [String: AnyObject], object: Download) -> Download {
        object.update(dictionary)
        object.processId = processId
        return object
    }
    
    func createObject(dict: [String: AnyObject]) -> Download? {
        let object = Download(dict)
        object?.processId = processId
        return object
    }
}

class CompoundDownloadsSyncableArrayDelegate: SyncableArrayDelegate {
    func idFromRaw(object: Download) -> String? {
        return "\(object.id)\(object.processId)"
    }
    
    func idFromObject(object: Download) -> String {
        return "\(object.id)\(object.processId)"
    }
    
    func updateObject(raw: Download, object: Download) -> Download {
        return raw
    }
    
    func createObject(raw: Download) -> Download? {
        return raw
    }
}


class Datasource: ConnectionEventListener {
    private var processes: [String: (xpc: NSXPCConnection!, downloader: NativaHelperProtocol!, downloads: SyncableArray<DownloadsSyncableArrayDelegate>!, state: DatasourceConnectionStatus, observer: AnyObject?, delegate: DownloadsSyncableArrayDelegate?)] = [:]
    let downloads: SyncableArray<CompoundDownloadsSyncableArrayDelegate>
    let queue = NSOperationQueue()
    let downloadsDelegate = CompoundDownloadsSyncableArrayDelegate()
    
    var processIds: [String] { return processes.keys.map({ (k) -> String in k}) }
    
    static let instance = Datasource()
    
    init(){
        downloads = SyncableArray(delegate: downloadsDelegate)
        queue.suspended = true
    }
    
    var connectionState: DatasourceConnectionStatus {
        var establishing = false
        
        for p in processes.values {
            switch p.state {
            case .Established:
                return .Established
            case .Establishing:
                establishing = true
            case .Disconnected(_):
                break
            }
        }
        
        return establishing ? DatasourceConnectionStatus.Establishing :  DatasourceConnectionStatus.Disconnected(error: NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "no one service is connected"]))
        
    }
    
    private func createDownloader(erroHandler: (NSError)->Void) throws -> (NSXPCConnection, NativaHelperProtocol) {
        let downloaderService = NSXPCConnection(serviceName: "\(NSBundle.mainBundle().bundleIdentifier!).NativaHelper")
        
        downloaderService.remoteObjectInterface = NSXPCInterface(`withProtocol`: NativaHelperProtocol.self)
        downloaderService.exportedInterface = NSXPCInterface(`withProtocol`: ConnectionEventListener.self)
        downloaderService.exportedObject = self
        downloaderService.resume()
        
        let downloader = downloaderService.remoteObjectProxyWithErrorHandler(erroHandler) as! NativaHelperProtocol
        
        return (downloaderService, downloader)
    }
    
    private func getProcess(processId: String?) -> (xpc: NSXPCConnection!, downloader: NativaHelperProtocol!, downloads: SyncableArray<DownloadsSyncableArrayDelegate>!, state: DatasourceConnectionStatus, observer: AnyObject?, delegate: DownloadsSyncableArrayDelegate?)? {
        guard let processId = processId, let process = processes[processId] else{
            return nil
        }
        
        //FIXME: for some reason can not be placed into guard
        if case DatasourceConnectionStatus.Established = process.state {
            return process
        }
        
        return nil
    }
    
    private func addConnection(id: String, handler: (NSError?)->Void, @noescape connect: (NativaHelperProtocol, (NSError?)->Void)->Void) {
        processes[id] = (xpc: nil, downloader: nil, downloads: nil, state: .Establishing, observer: nil, delegate: nil)
        
        do {
            let result = try createDownloader{(error)->Void in
                self.processes[id] = (xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: error), observer: nil, delegate: nil)
                handler(NSError(error))
                notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
                return
            }
            
            processes[id] = (xpc: result.0, downloader: result.1, downloads: nil, state: .Establishing, observer: nil, delegate: nil)
        }
        catch let error {
            let err = NSError(error)
            self.processes[id] = (xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: err), observer: nil, delegate: nil)
            handler(err)
            notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
            return
        }
        
        connect(processes[id]!.downloader) { (error) in
            guard error == nil else {
                self.processes[id] = (xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: error), observer: nil, delegate: nil)
                handler(error)
                notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
                return
            }
            
            var process = self.processes[id]!
            process.state = .Established
            let delegate = DownloadsSyncableArrayDelegate(processId: id)
            let array = SyncableArray(delegate: delegate)
            let observer = array.addObserver({ (changes: [(object: Download, index: Int, type: ChangeType)]) -> Void in
                for change in changes {
                    switch change.type {
                    case .Delete:
                        self.downloads.remove(change.object)
                    case .Insert, .Update:
                        self.downloads.update(change.object)
                    }
                }
            })
            process.observer = observer
            process.downloads = array
            process.delegate = delegate
            
            self.processes[id] = process
            
            self.queue.suspended = false
            
            self.update(id){ (error) -> Void in
                handler(error)
                notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
            }
        }
    }
    
    func addConnection(id: String, user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void) {
        addConnection(id, handler: connect){ (downloader, handler) -> Void in
            downloader.connect(user, host: host, port: port, password: password, serviceHost: serviceHost, servicePort: servicePort, connect: handler)
        }
    }
    
    
    func addConnection(id: String, host: String, port: UInt16, connect: (NSError?)->Void) {
        addConnection(id, handler: connect){ (downloader, handler) -> Void in
            downloader.connect(host, port: port, connect: handler)
        }
    }

    func version(id: String, response: (String?, NSError?)->Void) {
        guard let process = getProcess(id) else{
            return
        }

        process.downloader.version { (version, error) -> Void in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                response(version, error)
            }
        }
    }
    
    func stopDownload(download: Download){
        guard let process = getProcess(download.processId) else{
            return
        }
        
        process.downloads.update(["info": ["id": download.id, "active": false, "opened": false, "state": 1, "completed": false, "hashChecking": false]])
        process.downloader.stopTorrent(download.id) { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("failed to stop torrent \(error)")
                let message = error == nil ? "unable to stop torrent" : error!.localizedDescription
                process.downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            process.downloads.update(result)
        }
    }

    func startDownload(download: Download){
        guard let process = getProcess(download.processId) else{
            return
        }
        
        process.downloads.update(["info": ["id": download.id, "active": true, "opened": true, "state": 1, "completed": false, "hashChecking": false]])
        process.downloader.startTorrent(download.id) { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("failed to start torrent \(error)")
                let message = error == nil ? "unable to start torrent" : error!.localizedDescription
                process.downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            process.downloads.update(result)
        }
    }
    
    func update()
    {
        for id in processes.keys {
            if getProcess(id) == nil{
                continue
            }
            update(id)
        }
    }

    private func update(id: String, closure: ((NSError?)->Void)? = nil)
    {
        guard let process = getProcess(id) else{
            return
        }
        
        process.downloader.update { (result, error) -> Void in
            guard let result = result where error == nil else {
                logger.error("unable to update torrents list \(error)")
                closure?(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                process.downloads.update(result, strategy: SyncStrategy.Replace)
                closure?(nil)
            })
        }
    }
    
    func update(download: Download,  handler: (Download?, NSError?) -> Void) {
        guard let process = getProcess(download.processId) else{
            return
        }
        
        process.downloader.update(download.id) {(result, error)->Void in
            guard let result = result where error == nil else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(nil, error)
                })
                return
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                process.downloads.update(result)
                handler(download, nil)
            })
        }
    }
    
    func setFilePriority(download: Download, priorities:[FileListNode: Int], handler: (NSError?)->Void) {
        guard let process = getProcess(download.processId) else{
            return
        }

        let pr = priorities.map { (file, priority) -> (Int, Int) in
            //immediately set priorities
            file.priority = DownloadPriority(rawValue: priority)!
            return (file.index!, priority)
        }
        
        process.downloader.setFilePriority(download.id, priorities: pr, handler: handler)
    }
    
    func parseTorrents(files:[NSURL], handler: ([(path: NSURL, download: Download)]?, NSError?)->Void){
        queue.addOperationWithBlock { () -> Void in
            guard let downloader = self.processes.first?.1.downloader else {
                return
            }
            
            var torrentDatas: [NSData] = []
            
            do {
                for file in files {
                    let torrentData: NSData = try NSData(contentsOfURL:file, options: NSDataReadingOptions(rawValue: 0))
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
                
                let result = parsed.enumerate().map{ (index, parsedTorrent) -> (path: NSURL, download: Download?) in
                    return (path: files[index], download: Download(parsedTorrent))
                    }
                    .filter{(d) -> Bool in
                        d.download != nil
                    }
                    .map({ (e) -> (path: NSURL, download: Download) in
                        return (path: e.path, download: e.download!)
                    })
                
                handler(result, nil)
            }
        }
    }
    
    func addTorrentFiles(processId: String, files: [(path: NSURL, download: Download, start: Bool, group: Group?, folder: String?, priorities: [FileListNode: Int]?)]) {
        guard let process = getProcess(processId) else{
            return
        }

        queue.addOperationWithBlock { () -> Void in
            for file in files {
                guard !self.downloads.contains(file.download) else{
                    continue
                }

                do {
                    let torrentData: NSData = try NSData(contentsOfURL:file.path, options: NSDataReadingOptions(rawValue: 0))
                    file.download.processId = processId
                    process.downloads.updateFromObject(file.download)
                    
                    var pr: [Int: Int]?
                    
                    if let priorities = file.priorities {
                        pr = priorities.map { (file, priority) -> (Int, Int) in
                            //immediately set priorities
                            file.priority = DownloadPriority(rawValue: priority)!
                            return (file.index!, priority)
                        }
                    }
                    
                    process.downloader.addTorrentData(file.download.id, data: torrentData, priorities: pr, folder: file.folder, start: file.start, group: file.group?.id, handler: { (error) -> Void in
                        logger.error("unable to add torrent \(error)")
                    })
                }
                catch let error {
                    logger.error("unable to add torrent \(error)")
                }
            }
        }
    }
    
    func removeTorrent(download: Download, removeData: Bool, response:(NSError?) -> Void) {
        guard let process = getProcess(download.processId) else{
            return
        }

        process.downloads.remove(download)
        process.downloader.removeTorrent(download.id, path: download.dataPath, removeData: removeData, response: response)
    }

    //MARK: ConnectionEventListener
    @objc func connectionDropped(error: NSError?) {
        logger.error("connection dropped \(error)")
        notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: .Disconnected(error: error)))
    }
}