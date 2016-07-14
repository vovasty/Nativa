//
//  NativaHelper.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

class NativaHelper : NSObject, NativaHelperProtocol {
    weak var xpcConnection: NSXPCConnection?
    private var rtorrent: RTorrent?
    private let fullDownloadsList = DMultiCommand("main", field: "list", commands: [
        ResultCommand("d.get_hash=", field: "id") { (v) -> AnyObject? in return v as? String },
        ResultCommand("d.get_name=", field: "name") { (v) -> AnyObject? in return v as? String },
        ResultCommand("d.get_size_bytes=", field: "length") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.get_bytes_done=", field: "complete") { (v) -> AnyObject? in return v as? Double },
        ResultCommand("d.get_state=", field: "state") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.is_open=", field: "opened") { (v) -> AnyObject? in return v as? Bool },
        ResultCommand("d.get_down_rate=", field: "downloadSpeed") { (v) -> AnyObject? in return v as? Double },
        ResultCommand("d.get_up_rate=", field: "uploadSpeed") { (v) -> AnyObject? in return v as? Double },
        ResultCommand("d.get_up_total=", field: "uploadTotal") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.get_base_path=", field: "path") { (v) -> AnyObject? in return v as? String },
        ResultCommand("d.get_peers_connected=", field: "peersConnected") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.get_peers_not_connected=", field: "peersNotConnected") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.get_peers_complete=", field: "peersCompleted") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.get_priority=", field: "priority") { (v) -> AnyObject? in return v as? Int },
        ResultCommand("d.is_multi_file=", field: "folder") { (v) -> AnyObject? in
            if let v = v as? Bool{
                return v
            }
            
            return false
        },
        ResultCommand("d.get_message=", field: "message") { (v) -> AnyObject? in return v as? String },
        ResultCommand("d.is_hash_checking=", field: "hashChecking") { (v) -> AnyObject? in return v as? Bool },
        ResultCommand("d.get_complete=", field: "completed") { (v) -> AnyObject? in return v as? Bool },
        ResultCommand("d.is_active=", field: "active") { (v) -> AnyObject? in return v as? Bool }
        ])
    
    func connect(_ user: String, host: String, port: UInt16, password: String, serviceHost: String, servicePort: UInt16, connect: (NSError?)->Void) {
        
        let connection = SSHConnection(user: user,
                                        host: host,
                                        port: port,
                                    password: password,
                                 serviceHost: serviceHost,
                                 servicePort: servicePort,
                                     connect: { (error)->Void in
                                        connect(NSError(error))
                                  },
                                  disconnect:{
                                    (error)->Void in
                                    (self.xpcConnection!.remoteObjectProxy as? ConnectionEventListener)?.connectionDropped(withError: NSError(error))
        })
        rtorrent = RTorrent(connection: connection)
    }
    
    func connect(_ host: String, port: UInt16, connect: (NSError?)->Void) {
        
        let connection = TCPConnection(host: host,
            port: port,
            connect: { (error)->Void in connect(NSError(error)) },
            disconnect:{ (error)->Void in
                (self.xpcConnection!.remoteObjectProxy as? ConnectionEventListener)?.connectionDropped(withError: NSError(error))
        })
        rtorrent = RTorrent(connection: connection)
    }
    
    func version(_ handler: (String?, NSError?)->Void) {
        let command = ResultCommand("system.api_version", field: "version") { (v) -> AnyObject? in return v as? String }
        
        
        rtorrent?.send(command){ (response, error) -> Void in
            guard error == nil else {
                handler(nil, NSError(error!))
                return
            }
            
            handler(response?["version"] as? String, nil)
        }
    }
    
    func update(_ handler:([[String:AnyObject]]?, NSError?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        rtorrent.send(fullDownloadsList) { (response, error) -> Void in
            guard let response = response as? [[String:AnyObject]] where error == nil else{
                handler(nil, NSError(error))
                return
            }
            
            let result = response.map { (e) -> [String: AnyObject] in
                return ["info": e]
            }
            handler(result, nil)
        }
    }
    
    
    func update(_ id: String, handler:([String:AnyObject]?, NSError?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        rtorrent.send([
            ResultCommand("d.get_hash", parameters: [id], field: "id") { (v) -> AnyObject? in return v as? String },

            ResultCommand("d.get_bytes_done", parameters: [id], field: "complete") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("d.get_state", parameters: [id], field: "state") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_down_rate", parameters: [id], field: "downloadSpeed") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("d.get_up_rate", parameters: [id], field: "uploadSpeed") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("d.get_up_total", parameters: [id], field: "uploadTotal") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.get_peers_connected", parameters: [id], field: "peersConnected") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.get_peers_not_connected", parameters: [id], field: "peersNotConnected") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.get_peers_complete", parameters: [id], field: "peersCompleted") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.get_priority", parameters: [id], field: "priority") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.get_message", parameters: [id], field: "message") { (v) -> AnyObject? in return v as? String },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.is_active", parameters: [id], field: "active") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_free_diskspace", parameters: [id], field: "freeDiskspace") { (v) -> AnyObject? in return v as? Double },            
            FMultiCommand(id, index: nil, field: "files", commands: [
                ResultCommand("f.get_path=", field: "path") { (v) -> AnyObject? in return (v as? String)?.characters.split(separator: "/").map{String($0)} as? AnyObject },
                ResultCommand("f.get_size_bytes=", field: "length") { (v) -> AnyObject? in return v as? Double },
                ResultCommand("f.get_priority=", field: "priority") { (v) -> AnyObject? in return v as? Int },
                ResultCommand("f.get_completed_chunks=", field: "completed_chunks") { (v) -> AnyObject? in return v as? Int },
                ResultCommand("f.get_size_chunks=", field: "size_chunks") { (v) -> AnyObject? in return v as? Int }
                ])
            ]) { (response, error) -> Void in
                guard let response = response where error == nil else{
                    handler(nil, NSError(error))
                    return
                }

                let result = ["info": response]

                handler(result, nil)
        }
    }
    
    func setFilePriority(_ id: String, priorities:[Int: Int], handler: (NSError?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        
        var commmands: [Command] = priorities.map { (fileIndex, priority) -> Command in
            let params: [AnyObject] = [id, fileIndex, priority]
            return ResultCommand("f.set_priority", parameters: params, field: "result_set_priority") { (v) -> AnyObject? in return v as? Bool }
        }
        
        commmands.append(ResultCommand("d.update_priorities", parameters: [id], field: "result_update_priority") { (v) -> AnyObject? in return v as? Bool })
        
        rtorrent.send(commmands) { (result, error) -> Void in
            handler(NSError(error))
        }
    }
    
    func parseTorrent(_ data:[Data], handler:([[String:AnyObject]]?, NSError?)->Void) {
        var result: [[String:AnyObject]] = []
        
        for data in data {
            
            do {
                guard let parsed: ([String: AnyObject], String?) = try bdecode(data), let infoHash = parsed.1 else {
                    handler(nil, nil)
                    return
                }
                var torrent = parsed.0
                var info = torrent["info"] as! [String: AnyObject]
                info["id"] = infoHash
                torrent["info"] = info
                result.append(torrent)
            }
            catch{
                handler(nil, NSError(error))
                return
            }
        }

        handler(result, nil)
    }
    
    func addTorrentData(_ id: String, data: Data, priorities: [Int: Int]?, folder: String?, start: Bool, group: String?, handler:(NSError?)->Void) {
        guard let rtorrent = rtorrent else {
            return
        }
        let command =  start ? "load_raw_start" : "load_raw"
        var parameters: [AnyObject] = [data]
        if let folder = folder {
            parameters.append("d.set_directory_base=\(folder)")
        }
        
        rtorrent.send(ResultCommand(command, parameters: parameters, field: "result") { (v) -> AnyObject? in return v as? Bool }) { (response, error) -> Void in
            guard error == nil else {
                handler(NSError(error))
                return
            }
            
            guard let priorities = priorities else{
                handler(nil)
                return
            }
            
            self.setFilePriority(id, priorities:priorities, handler: handler)
        }
    }
    
    func startTorrent(_ id: String, handler: ([String:AnyObject]?, NSError?)->Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        rtorrent.send([
            ResultCommand("d.open", parameters: [id], field: "result_open") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.start", parameters: [id], field: "result_start") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_hash", parameters: [id], field: "id") { (v) -> AnyObject? in return v as? String },
            ResultCommand("d.get_state", parameters: [id], field: "state") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_base_path", parameters: [id], field: "path") { (v) -> AnyObject? in return v as? [String] },
            ResultCommand("d.is_active", parameters: [id], field: "active") { (v) -> AnyObject? in return v as? Bool }
            ]) { (response, error) -> Void in
                guard let response  = response where error == nil else {
                    let err: NSError? = error == nil ? nil : NSError(error!)
                    handler(nil, err)
                    return
                }
                
                handler(["info": response], nil)
        }
    }
    
    func stopTorrent(_ id: String, handler:([String:AnyObject]?, NSError?)->Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        
        rtorrent.send([
            ResultCommand("d.close", parameters: [id], field: "result_close") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.stop", parameters: [id], field: "result_stop") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_hash", parameters: [id], field: "id") { (v) -> AnyObject? in return v as? String },
            ResultCommand("d.get_state", parameters: [id], field: "state") { (v) -> AnyObject? in return v as? Int },
            ResultCommand("d.is_open", parameters: [id], field: "opened") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.is_hash_checking", parameters: [id], field: "hashChecking") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_complete", parameters: [id], field: "completed") { (v) -> AnyObject? in return v as? Bool },
            ResultCommand("d.get_base_path", parameters: [id], field: "path") { (v) -> AnyObject? in return v as? [String] },
            ResultCommand("d.is_active", parameters: [id], field: "active") { (v) -> AnyObject? in return v as? Bool }
            ]) { (response, error) -> Void in
                guard let response  = response where error == nil else {
                    let err: NSError? = error == nil ? nil : NSError(error!)
                    handler(nil, err)
                    return
                }
                
                handler(["info": response], nil)
        }
    }
    
    func removeTorrent(_ id: String, path: String?, removeData: Bool, response: (NSError?) -> Void)
    {
        guard let rtorrent = rtorrent else {
            return
        }
        
        if removeData {
            var commands: [Command] = [
                ResultCommand("d.delete_tied", parameters: [id], field: "result_erase_tied") { (v) -> AnyObject? in return v as? Bool },
                ResultCommand("d.erase", parameters: [id], field: "result_erase") { (v) -> AnyObject? in return v as? Bool }
            ]
            if let path = path {
                commands.append(ResultCommand("execute", parameters: ["rm", "-r", path], field: "result_execute") { (v) -> AnyObject? in return v as? String })
            }
            
            rtorrent.send(commands) { (rsp, error) -> Void in
                response(NSError(error))
            }
        }
        else {
            let cmd = ResultCommand("d.erase", parameters: [id], field: "result_erase") { (v) -> AnyObject? in return v as? Bool }
            
            rtorrent.send(cmd, response: { (_, error) -> Void in
                response(NSError(error))
            })
        }
    }
    
    func getStats(_ handler:([String:AnyObject]?, NSError?)->Void) {
        let commands: [Command] = [
            ResultCommand("get_down_rate", field: "downloadSpeed") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("get_up_rate", field: "uploadSpeed") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("get_download_rate", field: "maxDownloadSpeed") { (v) -> AnyObject? in return v as? Double },
            ResultCommand("get_upload_rate", field: "maxUploadSpeed") { (v) -> AnyObject? in return v as? Double },
        ]
        
        rtorrent?.send(commands) { (rsp, error) -> Void in
            handler(rsp, NSError(error))
        }
    }
    
    func setMaxDownloadSpeed(_ speed: Int, handler:(NSError?)->Void) {
        let command = ResultCommand("set_download_rate", parameters: [speed], field: "downloadSpeed") { (v) -> AnyObject? in return v }
        rtorrent?.send(command, response: { (_, error) in
            handler(NSError(error))
        })
    }
    
    func setMaxUploadSpeed(_ speed: Int, handler:(NSError?)->Void) {
        let command = ResultCommand("set_upload_rate", parameters: [speed], field: "uploadSpeed") { (v) -> AnyObject? in return v }
        rtorrent?.send(command, response: { (_, error) in
            handler(NSError(error))
        })
    }

}
