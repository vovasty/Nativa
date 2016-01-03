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
    var state = DownloadState.Unknown
    var size: Double = 0
    var complete: Double = 0
    let comment: String?
    var flatFileList: [FileListNode]?
    var file: FileListNode
    private var _icon: NSImage?
    weak var group :Group?
    var message: String?
    var dataPath: String?
    var peersConnected: Int?
    var peersNotConnected: Int?
    var peersCompleted: Int?
    var processId: String?
    private var allFiles: [String: FileListNode] = [:]
    
    init?(_ torrent: [String: AnyObject]) {
        guard let info = torrent["info"] as? [String: AnyObject],
            let name = info["name"] as? String, let id = (info["id"] as? String)?.uppercaseString else {
            size = 0
            comment = nil
            flatFileList = []
            file = FileListNode(name: "", path: "", folder: false, size: 0)
            self.id = ""
            return nil
        }
        
        self.id = id

        self.title = name
        
        self.comment = torrent["comment"] as? String
        
        let folder: Bool
        if let f = info["folder"] as? Bool {
            folder = f
        }
        else {
            folder = false
        }
        
        if let size = info["length"] as? Double {
            self.size = size
        }
        
        file = FileListNode(name: title, path: title, folder: folder, size: size)
        file.index = 0
        
        update(torrent)
    }
    
     var icon: NSImage? {
        if _icon == nil
        {
            _icon = NSWorkspace.sharedWorkspace().iconForFileType(file.folder ? NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon)) :title.pathExtension)
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
        if let tfiles = info["files"] as? [[String: AnyObject]] {
            var torrentSize: Double = 0
            if let size = info["length"] as? Double {
                torrentSize = size
            }

            var flatFiles: [FileListNode] = []
            file.folder = true
            file.children?.removeAll()
            let root = file
            var fileIndex = 0
            var folders: [String: FileListNode] = [:]
            
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
                        var file: FileListNode! = allFiles[path]
                        if file == nil {
                            file = FileListNode(name: fileName, path: path, folder: false, size: fileSize)
                            allFiles[path] = file
                        }
                        
                        file.index = fileIndex
                        file.priority = priority
                        file.parent = parent
                        
                        if let completed_chunks = f["completed_chunks"] as? Float, let size_chunks = f["size_chunks"] as? Float {
                            file.completedChunks = completed_chunks
                            file.sizeChunks = size_chunks == 0 ? 1 : size_chunks
                            file.percentCompleted = file.completedChunks / file.sizeChunks
                        }
                        
                        if parent.children == nil {
                            parent.children = [file]
                        }
                        else {
                            parent.children!.append(file)
                        }
                        
                        flatFiles.append(file);
                        
                        var par: FileListNode? = parent
                        while let p = par {
                            p.size += fileSize
                            p.completedChunks += file.completedChunks
                            p.sizeChunks += file.sizeChunks
                            p.percentCompleted = p.completedChunks / p.sizeChunks
                            par = p.parent
                        }
                    }
                    else
                    {
                        if let folder = folders[path] {
                            parent = folder
                        }
                        else {
                            var folder: FileListNode! = allFiles[path]
                            if folder == nil {
                                folder = FileListNode(name: pe, path: path, folder: true, size: 0)
                                allFiles[path] = folder
                            }
                            else {
                                //reset stat for folder
                                folder.children = nil
                                folder.size = 0
                                folder.sizeChunks = 0
                                folder.completedChunks = 0
                            }

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
            self.size = torrentSize
        }
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