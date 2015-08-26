//
//  main.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/15/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation
import Common


class ServiceDelegate : NSObject, NSXPCListenerDelegate {
    func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {

        newConnection.exportedInterface = NSXPCInterface(`withProtocol`: NativaHelperProtocol.self)
        
        let exportedObject = NativaHelper()
        
        newConnection.exportedObject = exportedObject
        newConnection.remoteObjectInterface = NSXPCInterface(`withProtocol`: ConnectionEventListener.self)

        exportedObject.xpcConnection = newConnection;

        newConnection.resume()
        
        return true
    }
}


// Create the listener and resume it:
//
let delegate = ServiceDelegate()
let listener = NSXPCListener.serviceListener()
listener.delegate = delegate;
listener.resume()
