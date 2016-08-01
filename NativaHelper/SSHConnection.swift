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
    private let serviceHost: String!
    private let servicePort: UInt16!
    private let manager: Manager

    init(user: String,
        host: String,
        port: UInt16,
        password: String,
        serviceHost: String,
        servicePort: UInt16,
        connect: (ErrorProtocol?)->Void,
        disconnect:(ErrorProtocol?)->Void) {
        manager = Manager(user: user, host: host, port: port)
        self.serviceHost = serviceHost
        self.servicePort = servicePort
        
        
        
        manager.session.onDisconnect { (error) -> Void in
                disconnect(error)
            }
            .onValidate { (fingerptint, handler) in
                handler(allow: true)
            }
            .onAuthenticate{ (methods, handler) in
                handler(authenticate: .password(password))
            }
            .onConnect {
                connect(nil)
            }
            .connect()
    }
    
    
    func request(_ data: Data, response: (Data?, ErrorProtocol?) -> Void) {
        manager.request(host: serviceHost, port: servicePort, send: data, receive: response)
    }
}
