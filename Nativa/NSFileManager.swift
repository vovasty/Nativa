//
//  NSFileManager.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 12/9/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

enum FileManagerError: ErrorType {
    case UnableToMoveToTrash(message: String)
}

extension NSFileManager {
    func trashPath(path: NSURL) throws{
        let script =
        "with timeout 15 seconds\n" +
            "tell application \"Finder\"\n" +
            "delete POSIX file \"\(path.path!)\"\n" +
            "end tell\n" +
        "end timeout\n"

        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        appleScript?.executeAndReturnError(&errorInfo)
        
        if let errorInfo = errorInfo {
            let localizedDescription = errorInfo[NSAppleScriptErrorBriefMessage] as! String
            throw FileManagerError.UnableToMoveToTrash(message: localizedDescription)
        }
    }
}