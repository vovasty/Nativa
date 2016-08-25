//
//  SSHConnection.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation
import SwiftySSH

class SSHConnection: Connection {
    fileprivate let serviceHost: String!
    fileprivate let servicePort: UInt16!
    fileprivate let manager: Manager

    init(user: String,
        host: String,
        port: UInt16,
        password: String,
        serviceHost: String,
        servicePort: UInt16,
        connect: @escaping (Error?)->Void,
        disconnect:@escaping (Error?)->Void) {
        manager = Manager(user: user, host: host, port: port)
        self.serviceHost = serviceHost
        self.servicePort = servicePort
        
        
        
        manager.session.onDisconnect { (error) -> Void in
                disconnect(error)
            }
            .onValidate { (fingerptint, handler) in
                handler(true)
            }
            .onAuthenticate{ (methods, handler) in
                handler(.password(password))
            }
            .onConnect {
                connect(nil)
            }
            .connect()
    }
    
    
    func request(_ data: Data, response: @escaping (Data?, Error?) -> Void) {
        manager.request(serviceHost, port: servicePort, send: data, receive: response)
    }
}
