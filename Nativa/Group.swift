//
//  Group.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

class Group
{
    let id :String!
    var title :String!
    var downloads: SyncableArray<Group>!
    
    init(id:String)
    {
        self.id = id
        downloads = SyncableArray(delegate: self)
    }
    
    func update(dict: [String: AnyObject])
    {
        if let title = dict["title"] as? String {
            self.title = title
        }
        
        if let downloads = dict["downloads"] as? [[String: AnyObject]] {
            self.downloads.update(downloads, strategy: .replace)
        }
    }
}

extension Group: SyncableArrayDelegate {
    func id(fromRaw raw: [String: AnyObject]) -> String? {
        guard let info = raw["info"] as? [String: AnyObject], let id = info["id"] as? String else {
            return nil
        }
        
        return id
    }
    
    func id(fromObject object: Download) -> String {
        return object.id
    }
    
    func update(fromRaw raw: [String: AnyObject], object: Download) -> Download {
        object.update(torrent: raw)
        return object
    }
    
    func create(fromRaw raw: [String: AnyObject]) -> Download? {
        return Download(raw)
    }
}

extension Group: Equatable {}

func ==(lhs: Group, rhs: Group) -> Bool {
    return lhs.id == rhs.id
}


extension Group: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
}
