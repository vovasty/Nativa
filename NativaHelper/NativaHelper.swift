//
//  NativaHelper.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

private extension Bool {
    init(_ i: Int?) {
        self = (i ?? 0) != 0
    }
}

class NativaHelper : NSObject, NativaHelperProtocol {
    weak var xpcConnection: NSXPCConnection?
    fileprivate var rtorrent: RTorrent?
    fileprivate let fullDownloadsList = DMultiCommand("main", field: "list", commands: [
        ResultCommand("d.get_hash=", field: "id") { $0 as? String },
        ResultCommand("d.get_name=", field: "name") { $0 as? String },
        ResultCommand("d.get_size_bytes=", field: "length") { $0 as? Int },
        ResultCommand("d.get_bytes_done=", field: "complete") { $0 as? Int },
        ResultCommand("d.get_state=", field: "state") { $0 as? Int },
        ResultCommand("d.is_open=", field: "opened") { Bool($0 as? Int ) },
        ResultCommand("d.get_down_rate=", field: "downloadSpeed") { $0 as? Int },
        ResultCommand("d.get_up_rate=", field: "uploadSpeed") { $0 as? Int },
        ResultCommand("d.get_up_total=", field: "uploadTotal") { $0 as? Int },
        ResultCommand("d.get_base_path=", field: "path") { $0 as? String },
        ResultCommand("d.get_peers_connected=", field: "peersConnected") { $0 as? Int },
        ResultCommand("d.get_peers_not_connected=", field: "peersNotConnected") { $0 as? Int },
        ResultCommand("d.get_peers_complete=", field: "peersCompleted") { $0 as? Int },
        ResultCommand("d.get_priority=", field: "priority") { $0 as? Int },
        ResultCommand("d.is_multi_file=", field: "folder") { Bool($0 as? Int ) },
        ResultCommand("d.get_message=", field: "message") { $0 as? String },
        ResultCommand("d.is_hash_checking=", field: "hashChecking") { Bool($0 as? Int ) },
        ResultCommand("d.get_complete=", field: "completed") { Bool($0 as? Int ) },
        ResultCommand("d.is_active=", field: "active") { Bool($0 as? Int ) }
        ])
    
    public func connect(_ user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: @escaping (Error?) -> Void) {
        
        let connection = SSHConnection(user: user,
                                        host: host,
                                        port: port,
                                    password: password,
                                 serviceHost: serviceHost,
                                 servicePort: servicePort,
                                     connect: { (error)->Void in
                                        connect(error)
                                  },
                                  disconnect:{
                                    (error)->Void in
                                    (self.xpcConnection!.remoteObjectProxy as? ConnectionEventListener)?.connectionDropped(withError: error)
        })
        rtorrent = RTorrent(connection: connection)
    }
    
    public func connect(_ host: String, port: UInt16, connect: @escaping (Error?)->Void) {
        
        let connection = TCPConnection(host: host, port: port)
        connect(nil)
        rtorrent = RTorrent(connection: connection)
    }
    
    public func version(_ response: @escaping (String?, Error?) -> Void) {
        let command = ResultCommand("system.api_version", field: "version") { $0 as? String }
        
        rtorrent?.send(command){ (result: Result<[String: String]>) -> Void in
            switch result {
            case .failure(let error):
                response(nil, error)
            case .success(let data):
                if let version = data["version"] {
                    response(version, nil)
                }
                else {
                    response(nil, RTorrentError.unknown(message: "invalid response") as NSError)
                }
            }
        }
    }
    
    public func update(_ handler: @escaping ([[String:Any]]?, Error?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        rtorrent.send(fullDownloadsList) { (result: Result<[[String:Any]]>) -> Void in
            switch result {
            case .failure(let error):
                handler(nil, error)
            case .success(let data):
                let res = data.map { (e) -> [String: Any] in
                    return ["info": e]
                }

                handler(res, nil)
            }
        }
    }
    
    
    public func update(_ id: String, handler:@escaping ([String:Any]?, Error?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        let commands: [CommandWithResult] = [
            ResultCommand("d.get_hash", parameters: [id], field: "id") { $0 as? String },
            ResultCommand("d.get_bytes_done", parameters: [id], field: "complete") { $0 as? Int },
            ResultCommand("d.get_state", parameters: [id], field: "state") { $0 as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { Bool($0 as? Int ) },
            ResultCommand("d.get_down_rate", parameters: [id], field: "downloadSpeed") { $0 as? Int },
            ResultCommand("d.get_up_rate", parameters: [id], field: "uploadSpeed") { $0 as? Int },
            ResultCommand("d.get_up_total", parameters: [id], field: "uploadTotal") { $0 as? Int },
            ResultCommand("d.get_peers_connected", parameters: [id], field: "peersConnected") { $0 as? Int },
            ResultCommand("d.get_peers_not_connected", parameters: [id], field: "peersNotConnected") { $0 as? Int },
            ResultCommand("d.get_peers_complete", parameters: [id], field: "peersCompleted") { $0 as? Int },
            ResultCommand("d.get_priority", parameters: [id], field: "priority") { $0 as? Int },
            ResultCommand("d.get_message", parameters: [id], field: "message") { $0 as? String },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { Bool($0 as? Int ) },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { Bool($0 as? Int ) },
            ResultCommand("d.is_active", parameters: [id], field: "active") { Bool($0 as? Int ) },
            ResultCommand("d.get_free_diskspace", parameters: [id], field: "freeDiskspace") { $0 as? Int },
            FMultiCommand(id, index: nil, field: "files", commands: [
                ResultCommand("f.get_path=", field: "path") { (v) -> Any? in return (v as? String)?.characters.split(separator: "/").map{String($0)} },
                ResultCommand("f.get_size_bytes=", field: "length") { $0 as? Int },
                ResultCommand("f.get_priority=", field: "priority") { $0 as? Int },
                ResultCommand("f.get_completed_chunks=", field: "completed_chunks") { $0 as? Int },
                ResultCommand("f.get_size_chunks=", field: "size_chunks") { $0 as? Int }
                ])
        ]
        
        rtorrent.send(commands) { (result: Result<[String: Any]>) -> Void in
            switch result {
            case .failure(let error):
                handler(nil, error)
            case .success(let data):
                let result = ["info": data]
                
                handler(result, nil)
            }
        }
    }
    
    func setFilePriority(_ id: String, priorities:[Int: Int], handler: @escaping (Error?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        var commmands: [CommandWithResult] = priorities.map { (fileIndex, priority) -> CommandWithResult in
            let params: [Any] = [id as Any, fileIndex as Any, priority as Any]
            return ResultCommand("f.set_priority", parameters: params, field: "result_set_priority") { Bool($0 as? Int ) }
        }
        
        commmands.append(ResultCommand("d.update_priorities", parameters: [id as Any], field: "result_update_priority") { $0 as? Int })
        
        rtorrent.send(commmands) { (result: Result<[String: Any]>) -> Void in
            handler(result.error)
        }
    }
    
    public func parseTorrent(_ data:[Data], handler: @escaping ([[String:Any]]?, Error?)->Void) {
        var result: [[String:Any]] = []
        
        for data in data {
            do {
                guard let parsed: ([String: Any], String?) = try bdecode(data), let infoHash = parsed.1 else {
                    handler(nil, nil)
                    return
                }
                var torrent = parsed.0
                var info = torrent["info"] as! [String: Any]
                info["id"] = infoHash
                torrent["info"] = info
                result.append(torrent)
            }
            catch{
                handler(nil, error)
                return
            }
        }

        handler(result, nil)
    }
    
    func addTorrentData(_ id: String, data: Data, priorities: [Int: Int]?, folder: String?, start: Bool, group: String?, handler:@escaping (Error?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        let command =  start && (priorities?.count ?? 0) == 0 ? "load_raw_start" : "load_raw"
        var parameters: [Any] = [data as Any]
        if let folder = folder {
            parameters.append("d.set_directory_base=\(folder)")
        }
        
        rtorrent.send(ResultCommand(command, parameters: parameters, field: "result") { $0 as? Int }) { (result: Result<Int>) -> Void in
            switch result {
            case .failure(let error):
                handler(error)
            case .success(_):
                if let priorities = priorities, priorities.count > 0 {
                    self.setFilePriority(id, priorities: priorities) { (error) in
                        guard error == nil else {
                            handler (error)
                            return
                        }
                        
                        if start {
                            self.startTorrent(id) { (_, error) in
                                handler(error)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func startTorrent(_ id: String, handler: @escaping ([String:Any]?, Error?)->Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        rtorrent.send([
            ResultCommand("d.open", parameters: [id], field: "result_open") { Bool($0 as? Int ) },
            ResultCommand("d.start", parameters: [id], field: "result_start") { Bool($0 as? Int ) },
            ResultCommand("d.get_hash", parameters: [id], field: "id") { $0 as? String },
            ResultCommand("d.get_state", parameters: [id], field: "state") { $0 as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { Bool($0 as? Int ) },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { Bool($0 as? Int ) },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { Bool($0 as? Int ) },
            ResultCommand("d.get_base_path", parameters: [id], field: "path") { $0 as? [String] },
            ResultCommand("d.is_active", parameters: [id], field: "active") { Bool($0 as? Int ) }
        ]) { (result: Result<[String: Any]>) -> Void in
            switch result {
            case .failure(let error):
                handler(nil, error)
            case .success(let data):
                handler(["info": data], nil)
            }
        }
    }
    
    func stopTorrent(_ id: String, handler:@escaping ([String:Any]?, Error?)->Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        
        rtorrent.send([
            ResultCommand("d.close", parameters: [id], field: "result_close") { Bool($0 as? Int ) },
            ResultCommand("d.stop", parameters: [id], field: "result_stop") { Bool($0 as? Int ) },
            ResultCommand("d.get_hash", parameters: [id], field: "id") { $0 as? String },
            ResultCommand("d.get_state", parameters: [id], field: "state") { $0 as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { Bool($0 as? Int ) },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { Bool($0 as? Int ) },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { Bool($0 as? Int ) },
            ResultCommand("d.get_base_path", parameters: [id], field: "path") { $0 as? [String] },
            ResultCommand("d.is_active", parameters: [id], field: "active") { Bool($0 as? Int ) }
        ]) { (result: Result<[String:Any]>) -> Void in
            switch result {
            case .failure(let error):
                handler(nil, error)
            case .success(let data):
                handler(["info": data], nil)
            }
        }
    }
    
    func removeTorrent(_ id: String, path: String?, removeData: Bool, response: @escaping (Error?) -> Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        
        if removeData {
            var commands: [CommandWithResult] = [
                ResultCommand("d.delete_tied", parameters: [id as Any], field: "result_erase_tied") { Bool($0 as? Int ) },
                ResultCommand("d.erase", parameters: [id], field: "result_erase") { Bool($0 as? Int ) }
            ]
            if let path = path {
                commands.append(ResultCommand("execute", parameters: ["rm" as Any, "-r" as Any, path as Any], field: "result_execute") { $0 as? String })
            }
            
            rtorrent.send(commands) { (result: Result<Any>) -> Void in
                response(result.error)
            }
        }
        else {
            let cmd = ResultCommand("d.erase", parameters: [id as Any], field: "result_erase") { Bool($0 as? Int ) }
            
            rtorrent.send(cmd, response: { (result: Result<Any>) -> Void in
                response(result.error)
            })
        }
    }
    
    func getStats(_ handler:@escaping ([String:Any]?, Error?)->Void) {
        let commands: [CommandWithResult] = [
            ResultCommand("get_down_rate", field: "downloadSpeed") { $0 as? Int },
            ResultCommand("get_up_rate", field: "uploadSpeed") { $0 as? Int },
            ResultCommand("get_download_rate", field: "maxDownloadSpeed") { $0 as? Int },
            ResultCommand("get_upload_rate", field: "maxUploadSpeed") { $0 as? Int },
        ]
        
        rtorrent?.send(commands) { (result: Result<[String:Any]>) -> Void in
            handler(result.value, result.error)
        }
    }
    
    func setMaxDownloadSpeed(_ speed: Int, handler:@escaping (Error?)->Void) {
        let command = ResultCommand("set_download_rate", parameters: [speed as Any], field: "downloadSpeed") { $0 }
        rtorrent?.send(command, response: { (result: Result<Any>) in
            handler(result.error)
        })
    }
    
    func setMaxUploadSpeed(_ speed: Int, handler:@escaping (Error?)->Void) {
        let command = ResultCommand("set_upload_rate", parameters: [speed], field: "uploadSpeed") { $0 }
        rtorrent?.send(command, response: { (result: Result<Any>) in
            handler(result.error)
        })
    }

}
