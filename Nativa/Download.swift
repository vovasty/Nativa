//
//  Torrent.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa


enum DownloadState {
    case Stopped
    case Paused
    case Downloading(dl: Double, ul: Double)
    case Seeding(ul: Double)
    case Checking
    case Unknown
}

enum DownloadPriority: Int {
    case High = 2
    case Normal = 1
    case Skip = 0
}

class Download
{
    let id: String
    var title: String!
    var priority: DownloadPriority!
    var folder: Bool = false
    var state = DownloadState.Unknown
    var size: Double = 0
    var complete: Double = 0
    let comment: String?
    var flatFileList: [FileListNode]?
    var file: FileListNode!
    private var _icon: NSImage?
    weak var group :Group?
    var message: String?
    var dataPath: String?
    var peersConnected: Int?
    var peersNotConnected: Int?
    var peersCompleted: Int?
    
    init?(_ torrent: [String: AnyObject]) {
        guard let info = torrent["info"] as? [String: AnyObject],
            let name = info["name"] as? String else {
            size = 0
            comment = nil
            flatFileList = []
            file = nil
            id = ""
            return nil
        }
        
        //FIXME: WTF?
        self.id = info["id"] as? String ?? NSUUID().UUIDString

        self.title = name
        
        self.comment = torrent["comment"] as? String
        
        update(torrent)
    }
    
     var icon: NSImage? {
        if _icon == nil
        {
            _icon = NSWorkspace.sharedWorkspace().iconForFileType(folder == true ? NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon)) :title.pathExtension)
        }
            
        return _icon
    }
    
    func update(torrent: [String: AnyObject])
    {
        guard let info = torrent["info"] as? [String: AnyObject] else {
            return
        }
        
        if let complete = info["complete"] as? Double {
            self.complete = complete
        }

        if let priorityRaw = info["priority"] as? Int,  let priority = DownloadPriority(rawValue: priorityRaw){
            self.priority = priority
        }

        
        if let active = info["active"] as? Bool, let opened = info["opened"] as? Bool, let state = info["state"] as? Int, let completed = info["completed"] as? Bool, let hashChecking = info["hashChecking"] as? Bool {
            if hashChecking {
                self.state = .Checking
            }
            else if !active {
                self.state = opened ? .Paused : .Stopped
            }
            else {
                switch state {
                case 1: //started
                    if opened {
                        
                        let downloadSpeed = info["downloadSpeed"] as? Double ?? 0
                        let uploadSpeed = info["uploadSpeed"] as? Double ?? 0
                        
                        self.state = (completed ? DownloadState.Seeding(ul: uploadSpeed) : DownloadState.Downloading(dl: downloadSpeed, ul: uploadSpeed))
                    }
                    else {
                        self.state = .Stopped
                    }
                case 0: //stopped
                    self.state = .Stopped
                default:
                    self.state = .Unknown
                }
            }
        }
        else {
            self.state = .Unknown
        }
        
        if let path = info["path"] as? String where path.utf8.count > 0{
            self.dataPath = path
        }
        
        if let peersConnected = info["peersConnected"] as? Int,
            let peersNotConnected = info["peersNotConnected"] as? Int,
            let peersCompleted = info["peersCompleted"] as? Int {
                
            self.peersConnected = peersConnected
            self.peersNotConnected = peersNotConnected
            self.peersCompleted = peersCompleted
        }

        message = info["message"] as? String
        
        //parse size and files
        var torrentSize: Double = 0
        if let size = info["length"] as? Double {
            torrentSize = size
        }
        
        if let tfiles = info["files"] as? [[String: AnyObject]] {
            var flatFiles: [FileListNode] = []
            let root = FileListNode(name: title, path: title, folder: true, size:0)
            var fileIndex = 0
            var folders: [String: FileListNode] = [:]
            self.folder = true
            
            for f in tfiles {
                var parent = root
                
                guard let fileList = f["path"] as? [String],
                    let fileName = fileList.last,
                    let fileSize = f["length"] as? Double else {
                            assert(false, "wrong structure")
                        break
                }
                
                let priority: DownloadPriority
                
                if let prRaw = f["priority"] as? Int, let prParsed = DownloadPriority(rawValue: prRaw)  {
                    priority = prParsed
                }
                else {
                    priority = .Normal
                }
                
                torrentSize += fileSize;
                
                
                
                for pe in fileList
                {
                    let path = "\(parent.path)/\(pe)"
                    if pe == fileName
                    {
                        let file = FileListNode(name: fileName, path: path, folder: false, size: fileSize)
                        file.index = fileIndex
                        file.priority = priority
                        file.parent = parent
                        
                        if parent.children == nil {
                            parent.children = [file]
                        }
                        else {
                            parent.children!.append(file)
                        }
                        
                        flatFiles.append(file);
                        
                        var p: FileListNode? = parent
                        while p != nil {
                            p?.size += fileSize
                            p = p!.parent
                        }
                        
                    }
                    else
                    {
                        if let folder = folders[path] {
                            parent = folder
                        }
                        else {
                            let folder = FileListNode(name: pe, path: path, folder: true, size: 0)
                            
                            if parent.children == nil {
                                parent.children = [folder]
                            }
                            else {
                                parent.children!.append(folder)
                            }
                            
                            folder.parent = parent
                            parent = folder
                            folders[path] = folder
                        }
                    }
                }
                fileIndex++;
            }
            self.flatFileList = flatFiles
            self.file = root
        }
        else {
            if let folder = info["folder"] as? Bool {
                self.folder = folder
            }
            else {
                self.folder = false
            }
            let root = FileListNode(name: title, path: title, folder: false, size: torrentSize)
            root.index = 0
            self.file = root
        }
        
        self.size = torrentSize
    }

}


extension Download: Equatable {}

func ==(lhs: Download, rhs: Download) -> Bool {
    return lhs.id == rhs.id
}


extension Download: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
}