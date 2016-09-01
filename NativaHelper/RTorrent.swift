//
//  RTorrentCommand.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/6/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

class RTorrent {
    let connection: Connection
    
    init(connection: Connection){
        self.connection = connection
    }
    
    func send(_ method: String, parameters: [Any]?, response: @escaping (Result<Any>) -> Void) {
        let sMethod: String
        do {
            sMethod = try XMLRPCEncode(method, parameters: parameters)
        }
        catch {
            response(.failure(error as NSError))
            return
        }
        
//        logger.debug("sending: \(sMethod)")
        
        let data = encodeSCGI(sMethod)
        
        connection.request(data) { (result) -> Void in
            switch result {
            case .failure(let error):
                response(.failure(error))
            case .success(let data):
                do {
                    let result = try XMLRPCDecode(data)
                    //                logger.debug("received: \(result)")
                    response(.success(result))
                }
                catch {
                    response(.failure(error as NSError))
                }
            }
        }
    }
}

protocol Command {
    var command: String { get }
    var parameters: [Any]? { get }
}

protocol CommandWithResult: Command {
    var transform: (Any)->Any? { get }
    var field: String { get }
}

struct ResultCommand: CommandWithResult {
    let command: String
    let parameters: [Any]?
    let field: String
    let transform: (Any)->Any?
    

    init(_ command: String, parameters: [Any]? = nil, field: String, transform: @escaping (Any)->Any?) {
        self.command = command
        self.parameters = parameters
        self.transform = transform
        self.field = field
    }
}

struct DMultiCommand: CommandWithResult {
    let command: String
    let parameters: [Any]?
    let field: String
    let transform: (Any) -> Any?
    
    init (_ view: String, field: String, commands: [ResultCommand]){
        let parameters = commands.map { (command) -> String in
            return command.command
        }
        self.parameters = [view] + parameters
        
        
        transform = { (data) in
            guard let data = data as? [[Any]], commands.count > 0 else { return [[:]] }
                //process each command result
            return data.map({(row) -> [String: Any] in
                let simpleDict = row.enumerated().reduce([String:Any]()) {
                    (d, field) in
                    
                    var dict = d
                    
                    let command = commands[field.offset]
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

struct FMultiCommand: CommandWithResult {
    let command: String
    let parameters: [Any]?
    let field: String
    let transform: (Any) -> Any?
    
    init (_ id: String, index: Int?, field: String, commands: [ResultCommand]){
        let parameters = commands.map { (command) -> String in
            return command.command
        }
        self.parameters = [id] + (index == nil ? [""] : [String(index!)]) + parameters
        
        
        transform = { (data) in
            guard let data = data as? [[Any]], commands.count > 0 else { return [[:]] }
            //process each command result
            return data.map({(row) -> [String: Any] in
                let simpleDict = row.enumerated().reduce([String:Any]()) {
                    (d, field) in
                    
                    var dict = d
                    
                    let command = commands[field.offset]
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
    func send<T>(_ commands: [CommandWithResult], response: @escaping (Result<T>)  -> Void) {
        let parameters = commands.map { (command) -> [String: Any] in
            return ["methodName": command.command as Any, "params": command.parameters as Any? ?? []]
        }
        
        self.send("system.multicall", parameters: [parameters] ) { (result) -> Void in
            guard case .success(_) = result else {
                response(.failure(result.error!))
                return
            }
            
            guard let result = result.value as? [Any] else {
                response(.failure(RTorrentError.unknown(message: "invalid response") as NSError))
                return
            }
            
            do {
                let transformedResult = try result.enumerated().map{ (i, commandResult) throws -> [String: Any] in
                    if let errorDict = commandResult as? [String: Any] {
                        guard let code = errorDict["faultCode"] as? Int, let message = errorDict["faultString"] as? String else {
                            throw XMLRPCDecoderError.unknown
                        }
                        throw XMLRPCDecoderError.fault(code: code, message: message)
                    }
                    
                    let command = commands[i]
                    if let v  = command.transform((commandResult as! [Any]).first!) {
                        return [command.field: v]
                    }
                    
                    return [:]
                }
                .flatMap { $0 }
                .reduce([String: Any]()) { (d, tuple) in
                    var dict = d
                    dict.updateValue(tuple.1, forKey: tuple.0)
                    return dict
                }
                
                if let res = transformedResult as? T {
                    response(.success(res))
                }
                else {
                    response(.failure(RTorrentError.unknown(message: "invalid response type") as NSError))
                }
            }
            catch {
                response(.failure(error as NSError))
            }
        }
    }
    
    func send<T>(_ command: CommandWithResult, response: @escaping (Result<T>) -> Void) {
        self.send(command.command, parameters: command.parameters, response: { (result) -> Void in
            switch result {
            case .failure(let error):
                response(.failure(error))
            case .success(let data):
                    if let res = command.transform(data) as? T {
                        response(.success(res))
                    }
                    else {
                        response(.failure(RTorrentError.unknown(message: "invalid response type") as NSError))
                    }
            }
        })
    }
}
