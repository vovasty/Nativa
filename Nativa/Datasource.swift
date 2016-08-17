//
//  Datasource.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/6/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

enum NativaError: ErrorProtocol {
    case UnknownError(message: String)
}


struct DatasourceConnectionStateDidChange: NotificationProtocol {
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
    
    func id(fromRaw raw: [String: AnyObject]) -> String? {
        guard let info = raw["info"] as? [String: AnyObject], let id = (info["id"] as? String)?.uppercased() else {
            return nil
        }
        
        return id
    }
    
    func id(fromObject object: Download) -> String {
        return object.id
    }
    
    func update(fromRaw raw: [String: AnyObject], object: Download) -> Download {
        object.update(torrent: raw)
        object.processId = processId
        return object
    }
    
    func create(fromRaw raw: [String: AnyObject]) -> Download? {
        let object = Download(raw)
        object?.processId = processId
        return object
    }
}

class CompoundDownloadsSyncableArrayDelegate: SyncableArrayDelegate {
    func id(fromRaw raw: Download) -> String? {
        return "\(raw.id)\(raw.processId)"
    }
    
    func id(fromObject object: Download) -> String {
        return "\(object.id)\(object.processId)"
    }
    
    func update(fromRaw raw: Download, object: Download) -> Download {
        return raw
    }
    
    func create(fromRaw raw: Download) -> Download? {
        return raw
    }
}

class Datasource: ConnectionEventListener {
    typealias ProcessDescriptor = (id: String, xpc: NSXPCConnection?, downloader: NativaHelperProtocol?, downloads: SyncableArray<DownloadsSyncableArrayDelegate>?, state: DatasourceConnectionStatus, observer: AnyObject?, delegate: DownloadsSyncableArrayDelegate?)
    var processes: [String: ProcessDescriptor] = [:]
    let downloads: SyncableArray<CompoundDownloadsSyncableArrayDelegate>
    let queue = OperationQueue()
    let downloadsDelegate = CompoundDownloadsSyncableArrayDelegate()
    private (set) var statistics: [String: Statistics] = [:]
    
    static let instance = Datasource()
    
    init(){
        downloads = SyncableArray(delegate: downloadsDelegate)
        queue.isSuspended = true
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
        
        return establishing ? DatasourceConnectionStatus.Establishing :  DatasourceConnectionStatus.Disconnected(error: NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "all services are failed to connect"]))
        
    }
    
    private func createDownloader(erroHandler: (NSError)->Void) throws -> (NSXPCConnection, NativaHelperProtocol) {
        let downloaderService = NSXPCConnection(serviceName: "\(Bundle.main.bundleIdentifier!).NativaHelper")
        
        downloaderService.remoteObjectInterface = NSXPCInterface(with: NativaHelperProtocol.self)
        downloaderService.exportedInterface = NSXPCInterface(with: ConnectionEventListener.self)
        downloaderService.exportedObject = self
        downloaderService.resume()
        
        let downloader = downloaderService.remoteObjectProxyWithErrorHandler(erroHandler) as! NativaHelperProtocol
        
        return (downloaderService, downloader)
    }
    
    private func getProcess(id: String?) -> ProcessDescriptor? {
        guard let id = id, let process = processes[id] else{
            return nil
        }
        
        //FIXME: for some reason can not be placed into guard
        guard case DatasourceConnectionStatus.Established = process.state else { return nil }
        
        return process
    }
    
    private func addConnection(id: String, handler: (NSError?)->Void, connect: @noescape (NativaHelperProtocol, (NSError?)->Void)->Void) {
        statistics[id] = Statistics(id: id)
        processes[id] = (id: id, xpc: nil, downloader: nil, downloads: nil, state: .Establishing, observer: nil, delegate: nil)
        
        do {
            let result = try createDownloader{(error)->Void in
                self.processes[id] = (id: id, xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: error), observer: nil, delegate: nil)
                handler(NSError(error))
                notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
                return
            }
            
            processes[id] = (id: id, xpc: result.0, downloader: result.1, downloads: nil, state: .Establishing, observer: nil, delegate: nil)
        }
        catch {
            let err = NSError(error)
            self.processes[id] = (id: id, xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: err), observer: nil, delegate: nil)
            handler(err)
            notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
            return
        }
        
        notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
        
        connect(processes[id]!.downloader!) { (error) in
            guard error == nil else {
                self.processes[id] = (id: id, xpc: nil, downloader: nil, downloads: nil, state: .Disconnected(error: error), observer: nil, delegate: nil)
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
                    case .delete:
                        self.downloads.remove(change.object)
                    case .insert, .update:
                        self.downloads.update(change.object)
                    }
                }
            })
            process.observer = observer
            process.downloads = array
            process.delegate = delegate
            
            self.processes[id] = process
            
            self.queue.isSuspended = false
            
            self.update(process: process){ (error) -> Void in
                handler(error)
                notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: self.connectionState))
            }
        }
    }
    
    func addConnection(id: String, user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void) {
        addConnection(id: id, handler: connect){ (downloader, handler) -> Void in
            downloader.connect(user, host: host, port: port, password: password, serviceHost: serviceHost, servicePort: servicePort, connect: handler)
        }
    }
    
    
    func addConnection(id: String, host: String, port: UInt16, connect: (NSError?)->Void) {
        addConnection(id: id, handler: connect){ (downloader, handler) -> Void in
            downloader.connect(host, port: port, connect: handler)
        }
    }
    
    func closeAllConnections(){
        for process in processes {
            let pr = process.1
            if let observer = pr.observer as? String {
                pr.downloads?.removeObserver(observer)
            }
            if let xpc = pr.xpc {
                xpc.invalidate()
            }
        }
        processes = [:]
        statistics = [:]
    }

    func version(id: String, response: (String?, NSError?)->Void) {
        guard let process = getProcess(id: id) else{
            return
        }

        process.downloader?.version { (version, error) -> Void in
            dispatch_main { response(version, error) }
        }
    }
    
    func stopDownload(download: Download){
        guard let process = getProcess(id: download.processId),
            let downloads = process.downloads,
            let downloader = process.downloader else {
            return
        }
        
        downloads.update(["info": ["id": download.id, "active": false, "opened": false, "state": 1, "completed": false, "hashChecking": false]])
        downloader.stopTorrent(download.id) { (result, error) -> Void in
            guard let result = result, error == nil else {
                logger.error("failed to stop torrent \(error)")
                let message = error == nil ? "unable to stop torrent" : error!.localizedDescription
                downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            downloads.update(result)
        }
    }

    func startDownload(download: Download){
        guard let process = getProcess(id: download.processId),
            let downloads = process.downloads,
            let downloader = process.downloader else {
                return
        }
        
        downloads.update(["info": ["id": download.id, "active": true, "opened": true, "state": 1, "completed": false, "hashChecking": false]])
        downloader.startTorrent(download.id) { (result, error) -> Void in
            guard let result = result, error == nil else {
                logger.error("failed to start torrent \(error)")
                let message = error == nil ? "unable to start torrent" : error!.localizedDescription
                downloads.update(["info": ["id": download.id, "message": message]])
                return
            }
            downloads.update(result)
        }
    }
    
    func update()
    {
        for id in processes.keys {
            guard let process = getProcess(id: id) else { continue }
            update(process: process)
        }
    }
    
    private func updateStats(process: ProcessDescriptor, closure: ()->Void) {
        process.downloader?.getStats({ (result, error) in
            closure()
            dispatch_main() {
                let stat = self.statistics[process.id]!
                stat.downloadSpeed = result?["downloadSpeed"] as? Double ?? 0
                stat.maxDownloadSpeed = result?["maxDownloadSpeed"] as? Double ?? 0
                stat.uploadSpeed = result?["uploadSpeed"] as? Double ?? 0
                stat.maxUploadSpeed = result?["maxUploadSpeed"] as? Double ?? 0
            }
        })
    }


    private func update(process: ProcessDescriptor, closure: ((NSError?)->Void)? = nil)
    {
        updateStats(process: process) {
            process.downloader?.update { (result, error) -> Void in
                guard let result = result, error == nil else {
                    logger.error("unable to update torrents list \(error)")
                    dispatch_main { closure?(error) }
                    return
                }
                
                dispatch_main {
                    process.downloads?.update(result, strategy: .replace)
                    closure?(nil)
                }
            }
        }
    }
    
    func update(download: Download,  handler: (Download?, NSError?) -> Void) {
        guard let process = getProcess(id: download.processId),
            let downloads = process.downloads,
            let downloader = process.downloader else {
                return
        }
        
        downloader.update(download.id) {(result, error)->Void in
            guard let result = result, error == nil else {
                dispatch_main { handler(nil, error) }
                return
            }

            dispatch_main {
                downloads.update(result)
                handler(download, nil)
            }
        }
    }
    
    func setFilePriority(download: Download, priorities:[FileListNode: Int], handler: (NSError?)->Void) {
        guard let process = getProcess(id: download.processId) else{
            return
        }

        let pr = priorities.map { (file, priority) -> (Int, Int) in
            //immediately set priorities
            file.priority = DownloadPriority(rawValue: priority)!
            return (file.index!, priority)
        }
        
        process.downloader?.setFilePriority(download.id, priorities: pr) { (error) in
            dispatch_main { handler(error) }
        }
    }
    
    func parse(urls:[URL], handler: ([(path: URL, download: Download)]?, NSError?)->Void){
        queue.addOperation { () -> Void in
            
            var process: NativaHelperProtocol?
            for key in self.processes.keys {
                process = self.getProcess(id: key)?.downloader
                
                if process != nil {
                    break
                }
            }
            
            guard let downloader = process else {
                dispatch_main {
                    handler(nil, NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "all services are failed to connect"]))
                }
                return
            }
            
            var torrentDatas: [Data] = []
            
            do {
                for url in urls {
                    let torrentData = try Data(contentsOf: url)
                    torrentDatas.append(torrentData)
                }
            }
            catch {
                dispatch_main { handler(nil, NSError(error)) }
                return
            }
            
            downloader.parseTorrent(torrentDatas) { (parsed, error) -> Void in
                
                guard let parsed = parsed, error == nil else {
                    dispatch_main { handler(nil, error) }
                    return
                }
                
                let result = parsed.enumerated().map{ (index, parsedTorrent) -> (path: URL, download: Download?) in
                    return (path: urls[index], download: Download(parsedTorrent))
                    }
                    .filter{(d) -> Bool in
                        d.download != nil
                    }
                    .map({ (e) -> (path: URL, download: Download) in
                        return (path: e.path, download: e.download!)
                    })
                
                dispatch_main { handler(result, nil) }
            }
        }
    }
    
    func addTorrentFiles(processId: String, files: [(path: URL, download: Download, start: Bool, group: Group?, folder: String?, priorities: [FileListNode: Int]?)], handler: ()->Void) {
        guard let process = getProcess(id: processId) else{
            return
        }

        queue.addOperation { () -> Void in
            for file in files {
                guard !self.downloads.contains(file.download) else{
                    continue
                }

                do {
                    let torrentData = try Data(contentsOf: file.path)
                    file.download.processId = processId
                    file.download.state = file.start ? .Downloading(dl: 0, ul: 0) : .Stopped
                    process.downloads?.updateFromObject(file.download)
                    
                    var pr: [Int: Int]?
                    
                    if let priorities = file.priorities {
                        pr = priorities.map { (file, priority) -> (Int, Int) in
                            //immediately set priorities
                            file.priority = DownloadPriority(rawValue: priority)!
                            return (file.index!, priority)
                        }
                    }
                    
                    process.downloader?.addTorrentData(file.download.id, data: torrentData, priorities: pr, folder: file.folder, start: file.start, group: file.group?.id, handler: { (error) -> Void in
                        guard error == nil else {
                            logger.error("unable to add torrent \(error)")
                            return
                        }
                    })
                }
                catch {
                    logger.error("unable to add torrent \(error)")
                }
            }
            
            dispatch_main { handler() }
        }
    }
    
    func remove(download: Download, removeData: Bool, response:(NSError?) -> Void) {
        guard let process = getProcess(id: download.processId),
            let downloads = process.downloads,
            let downloader = process.downloader else {
                return
        }

        downloads.remove(download)
        downloader.removeTorrent(download.id, path: download.dataPath, removeData: removeData) { (error) in
            dispatch_main { response(error) }
        }
    }
    
    func setMaxDownloadSpeed(processId: String, speed: Int, handler:(NSError?)->Void) {
        guard let process = getProcess(id: processId) else { return }
        guard let stat = statistics[processId] else { return }
        
        stat.maxDownloadSpeed = Double(speed)
        
        process.downloader?.setMaxDownloadSpeed(speed) { (error) in
            dispatch_main { handler(error) }
        }
    }
    
    func setMaxUploadSpeed(processId: String, speed: Int, handler:(NSError?)->Void) {
        guard let process = getProcess(id: processId) else { return }
        guard let stat = statistics[processId] else { return }
        
        stat.maxUploadSpeed = Double(speed)

        process.downloader?.setMaxUploadSpeed(speed) { (error) in
            dispatch_main { handler(error) }
        }
    }

    //MARK: ConnectionEventListener
    @objc func connectionDropped(withError error: NSError?) {
        logger.error("connection dropped \(error)")
        notificationCenter.postOnMain(DatasourceConnectionStateDidChange(state: .Disconnected(error: error)))
    }
}
