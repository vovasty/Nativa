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
    let serviceHost: String!
    let servicePort: UInt16!
    var session: Session?

    init(user: String,
        host: String,
        port: UInt16,
        password: String,
        serviceHost: String,
        servicePort: UInt16,
        connect: (ErrorProtocol?)->Void,
        disconnect:(ErrorProtocol?)->Void) {
        session = SwiftySSH.Session(user, host: host, port: port)
        self.serviceHost = serviceHost
        self.servicePort = servicePort
        
        session!.onDisconnect { (session, error) -> Void in
                disconnect(error)
            }
            .authenticate(.password(password: password))
            .onConnect({ (Session, error) -> Void in
                connect(error)
            })
            .connect()
    }
    
    
    func request(_ data: Data, response: (Data?, ErrorProtocol?) -> Void) {
        guard let session = session else{
            response(nil, RTorrentError.unknown(message: "not connected"))
            return
        }
        
        let tunnel = Channel(session, remoteHost: serviceHost, remotePort: servicePort)
        tunnel.send(data, response: response)
    }
}
