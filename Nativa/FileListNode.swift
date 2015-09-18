//
//  FileListNode.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/30/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa


class FileListNode {
    var name: String
    var path: String
    var index: Int?
    var children: [FileListNode]?
    var size: Double
    var folder: Bool
    var percentCompleted: Float = 0
    var priority: DownloadPriority = .Normal
    weak var parent: FileListNode?
    private var _icon: NSImage?
    
    init(name: String, path:String, folder: Bool, size: Double){
        self.name = name
        self.folder = folder
        self.size = size
        self.path = path
    }
    
    var icon: NSImage? {
        if _icon == nil
        {
            _icon = NSWorkspace.sharedWorkspace().iconForFileType(folder == true ? NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon)) :name.pathExtension)
        }
        
        return _icon
    }
}

extension FileListNode: Equatable {}

func ==(lhs: FileListNode, rhs: FileListNode) -> Bool {
    return lhs.path == rhs.path
}


extension FileListNode: Hashable {
    var hashValue: Int {
        return path.hashValue
    }
}