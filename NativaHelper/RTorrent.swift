//
//  RTorrentCommand.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/6/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation
import SwiftySSH

class RTorrent {
    let connection: Connection
    
    init(connection: Connection){
        self.connection = connection
    }
    
    func send(method: String, parameters:[AnyObject]?, response: (AnyObject?, ErrorType?) -> Void) {
        let sMethod: String
        do {
            sMethod = try XMLRPCEncode(method, parameters: parameters)
        }
        catch let e {
            response(nil, e)
            return
        }
        
//        logger.debug("sending: \(sMethod)")
        
        let data = encodeSCGI(sMethod)
        
        connection.request(data) { (responseData, error) -> Void in
            guard let responseData = responseData where error == nil else {
                response(nil, error)
                return
            }
            
            do {
                let result = try XMLRPCDecode(responseData)
//                logger.debug("received: \(result)")
                response(result, nil)
            }
            catch let error {
                response(nil, error)
            }

        }
    }
}

protocol Command {
    var command: String { get }
    var parameters: [AnyObject]? { get }
}

protocol CommandWithResult {
    var transform: (AnyObject)->AnyObject? { get }
    var field: String { get }
}

struct ResultCommand: Command, CommandWithResult {
    let command: String
    let parameters: [AnyObject]?
    let field: String
    let transform: (AnyObject)->AnyObject?
    

    init(_ command: String, parameters: [AnyObject]?, field: String, transform: (AnyObject)->AnyObject?) {
        self.command = command
        self.parameters = parameters
        self.transform = transform
        self.field = field
    }
}

struct DMultiCommand: Command, CommandWithResult {
    let command: String
    let parameters: [AnyObject]?
    let field: String
    let transform: (AnyObject) -> AnyObject?
    
    init (_ view: String, field: String, commands: [ResultCommand]){
        let parameters = commands.map { (command) -> String in
            return command.command
        }
        self.parameters = [view] + parameters
        
        
        transform = { (data) in
            guard let data = data as? [[AnyObject]] where commands.count > 0 else { return [[:]] }
                //process each command result
            return data.map({(row) -> [String: AnyObject] in
                let simpleDict = row.enumerate().reduce([String:AnyObject]()) {
                    (var dict, field) in
                    
                    let command = commands[field.index]
                    if let value  = command.transform(field.element) {
                        dict[command.field] = value
                    }
                    return dict
                }
                return simpleDict
            })
        }
        self.field = field
        command = "d.multicall"
    }
}

struct FMultiCommand: Command, CommandWithResult {
    let command: String
    let parameters: [AnyObject]?
    let field: String
    let transform: (AnyObject) -> AnyObject?
    
    init (_ id: String, index: Int?, field: String, commands: [ResultCommand]){
        let parameters = commands.map { (command) -> String in
            return command.command
        }
        self.parameters = [id] + (index == nil ? [""] : [String(index!)]) + parameters
        
        
        transform = { (data) in
            guard let data = data as? [[AnyObject]] where commands.count > 0 else { return [[:]] }
            //process each command result
            return data.map({(row) -> [String: AnyObject] in
                let simpleDict = row.enumerate().reduce([String:AnyObject]()) {
                    (var dict, field) in
                    
                    let command = commands[field.index]
                    if let value  = command.transform(field.element) {
                        dict[command.field] = value
                    }
                    return dict
                }
                return simpleDict
            })
        }
        self.field = field
        command = "f.multicall"
    }
}

extension RTorrent {
    func send(commands: [Command], response: ([[String: AnyObject]]?, ErrorType?)  -> Void) {
        let parameters = commands.map { (command) -> [String: AnyObject] in
            return ["methodName": command.command, "params": command.parameters ?? []]
        }
        
        self.send("system.multicall", parameters: [parameters] ) { (result, error) -> Void in
            guard error == nil else{
                response(nil, error)
                return
            }
            
            guard let result = result as? [AnyObject] else{
                response(nil, RTorrentError.Unknown(message: "invalid response"))
                return
            }
            
            let resultCommands = commands.filter({ (command) -> Bool in
                return command is CommandWithResult
            })
            
            if resultCommands.count  == 0 {
                response(nil, nil)
                return
            }
            
            do {
                let transformedResult = try result.enumerate().map({ (i, commandResult) throws -> [String: AnyObject] in
                    if let errorDict = commandResult as? [String: AnyObject] {
                        guard let code = errorDict["faultCode"] as? Int, let message = errorDict["faultString"] as? String else {
                            throw XMLRPCDecoderError.Unknown
                        }
                        throw XMLRPCDecoderError.Fault(code: code, message: message)
                    }
                    
                    let command = resultCommands[i] as! CommandWithResult
                    if let v  = command.transform((commandResult as! [AnyObject]).first!) {
                        return [command.field: v]
                    }
                    
                    return [:]
                })
                
                response(transformedResult, nil)
            }
            catch let e {
                response(nil, e)
            }
        }
    }
    
    func send(command: Command, response: (AnyObject?, ErrorType?) -> Void) {
        self.send(command.command, parameters: command.parameters, response: { (rsp, error) -> Void in
            guard let rsp = rsp where error == nil else {
                response(nil, error)
                return
            }
            
            if let command = command as? CommandWithResult {
                response(command.transform(rsp), nil)
            }
            else {
                response(rsp, nil)
            }
        })
    }
}
