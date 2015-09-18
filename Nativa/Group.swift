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
            self.downloads.update(downloads, strategy: SyncStrategy.Replace)
        }
    }
}

extension Group: SyncableArrayDelegate {
    func idFromRaw(dict: [String: AnyObject]) -> String? {
        guard let info = dict["info"] as? [String: AnyObject], let id = info["id"] as? String else {
            return nil
        }
        
        return id
    }
    
    func idFromObject(o: Download) -> String {
        return o.id
    }
    
    func updateObject(dictionary: [String: AnyObject], object: Download) -> Download {
        object.update(dictionary)
        return object
    }
    
    func createObject(dict: [String: AnyObject]) -> Download? {
        return Download(dict)
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