//
//  TCPConnection.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

class TCPConnection: NSObject, Connection, NSStreamDelegate {
    private var iStream: NSInputStream?
    private var oStream: NSOutputStream?
    private var requestData: NSData?
    private var responseData: NSMutableData?
    private var responseBuffer: [UInt8]?
    private var sentBytes: Int = 0
    private var requestSent: Bool = false
    var maxPacket = 4096
    var maxResponseSize = 1048576
    private let disconnect: (ErrorType?)->Void
    private let connect: (ErrorType?)->Void
    private var response: ((NSData?, ErrorType?) -> Void)?
    let host: String
    let port: UInt16
    let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    let requestSemaphore = dispatch_semaphore_create(1)
    var timeout: Int = 60
    var runLoopModes = [NSRunLoopCommonModes]
    private var connected: Bool = false
    
    init(host: String,
        port: UInt16,
        connect: (ErrorType?)->Void,
        disconnect: (ErrorType?)->Void) {
            self.disconnect = disconnect
            self.host = host
            self.port = port
            self.connect = connect
            
            super.init()
            
            dispatch_async(queue) { () -> Void in
                self.performSelector("_open", onThread: TCPConnection.networkRequestThread(), withObject: nil, waitUntilDone: false, modes: self.runLoopModes)
            }
    }
    
    func request(data: NSData, response: (NSData?, ErrorType?) -> Void) {
        dispatch_async(queue) { () -> Void in
            guard dispatch_semaphore_wait(self.requestSemaphore, dispatch_time (DISPATCH_TIME_NOW , Int64(UInt64(self.timeout) * NSEC_PER_SEC))) == 0 else {
                response(nil, RTorrentError.Unknown(message: "timeout"))
                return
            }
            
            self.requestData = data
            self.responseData = NSMutableData()
            self.response = response
            self.requestSent = false
            self.responseBuffer = Array(count: self.maxPacket, repeatedValue: 0)
            
            if self.connected {
                self.performSelector("_open", onThread: TCPConnection.networkRequestThread(), withObject: nil, waitUntilDone: false, modes: self.runLoopModes)
            }
            else if self.oStream?.streamStatus == .Open {
                self.stream(self.oStream!, handleEvent: NSStreamEvent.HasSpaceAvailable)
            }
        }
    }
    
    func _open() {
        NSStream.getStreamsToHostWithName(self.host, port: Int(self.port), inputStream: &self.iStream, outputStream: &self.oStream)
        iStream?.delegate = self
        oStream?.delegate = self
        
        let runLoop = NSRunLoop.currentRunLoop()
        for runLoopMode in runLoopModes {
            oStream?.scheduleInRunLoop(runLoop, forMode: runLoopMode)
            iStream?.scheduleInRunLoop(runLoop, forMode: runLoopMode)
        }

        iStream?.open()
        oStream?.open()
    }
    
    private func streamOpened() {
        guard !connected else {
            return
        }
        
        connected = true
        connect(nil)
    }
    
    private func requestDidSent() {
        logger.debug("requestDidSent")
        requestSent = true
    }
    
    private func errorOccured(error: ErrorType) {
        logger.debug("stream error: \(error)")
        if connected {
            disconnect(error)
        }
        else {
            connect(error)
        }
        
        cleanup()
    }
    
    private func responseDidReceived() {
        logger.debug("responseDidReceived")
        response?(responseData, nil)
        cleanup()
    }
    
    private func cleanup(){
        logger.debug("cleanup")

        iStream?.delegate = nil
        oStream?.delegate = nil

        let runLoop = NSRunLoop.currentRunLoop()
        for runLoopMode in runLoopModes {
            oStream?.removeFromRunLoop(runLoop, forMode: runLoopMode)
            iStream?.removeFromRunLoop(runLoop, forMode: runLoopMode)
        }
        iStream?.close()
        oStream?.close()
        requestData = nil
        responseData = nil
        iStream = nil
        oStream = nil
        responseBuffer = nil
        sentBytes = 0
        requestSent = false
        dispatch_semaphore_signal(requestSemaphore)
    }
    
    //MARK: NSStreamDelegate
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch(eventCode) {
        case NSStreamEvent.OpenCompleted:
            streamOpened()
        case NSStreamEvent.HasSpaceAvailable:
            guard let stream = aStream as? NSOutputStream where stream == oStream else{
                assert(false, "unexpected stream")
                return
            }
            
            guard let requestData = requestData else {
                logger.debug("no data to send")
                return
            }
            
            let buf = requestData.bytes.advancedBy(sentBytes)
            let size = (requestData.length - sentBytes) > maxPacket ? maxPacket : (requestData.length - sentBytes)
            let actuallySent = oStream!.write(UnsafePointer<UInt8>(buf), maxLength: size)
            sentBytes += actuallySent
            
            if sentBytes == requestData.length {
                requestDidSent()
            }
        case NSStreamEvent.HasBytesAvailable:
            guard let stream = aStream as? NSInputStream where stream == iStream else{
                logger.debug("unexpected stream: aStream(\((aStream as? NSInputStream))) == iStream(\(iStream)) =\((aStream as? NSInputStream) == iStream)")
//                assert(false, "unexpected stream")
                return
            }
            
            guard let responseData = responseData else {
                logger.debug("no buffer to receive")
                return
            }
            
            guard responseData.length < maxResponseSize else {
                errorOccured(RTorrentError.Unknown(message: "response is too big"))
                return
            }
            
            let actuallyRead = stream.read(&responseBuffer!, maxLength: maxPacket)
            
            guard actuallyRead > 0 else {
                return
            }
            
            responseData.appendBytes(responseBuffer!, length: actuallyRead)
        case NSStreamEvent.EndEncountered:
            if (aStream as? NSOutputStream) == oStream{
                if !requestSent {
                    errorOccured(RTorrentError.Unknown(message: "stream closed before request did send"))
                }
                return
            }
            if (aStream as? NSInputStream) == iStream{
                responseDidReceived()
                return
            }
            assert(false, "unexpected stream")
        case NSStreamEvent.ErrorOccurred:
            guard let error = aStream.streamError?.localizedDescription else {
                errorOccured(RTorrentError.Unknown(message: "unknown stream error"))
                return
            }
            
            errorOccured(RTorrentError.Unknown(message: error))
        default:
            logger.debug("skipped event event \(eventCode)")
        }
    }
    
    //MARK: Thread
    class func networkRequestThreadEntryPoint(object: AnyObject) {
        autoreleasepool {
            NSThread.currentThread().name = "Nativa"
    
            let runLoop = NSRunLoop.currentRunLoop()
            runLoop.addPort(NSMachPort(), forMode:NSDefaultRunLoopMode)
            runLoop.run()
        }
    }

    private static var _networkRequestThread: NSThread!
    private static var _oncePredicate = dispatch_once_t()

    private class func networkRequestThread()->NSThread {
        dispatch_once(&_oncePredicate) { () -> Void in
            _networkRequestThread = NSThread(target: self, selector: "networkRequestThreadEntryPoint:", object: nil)
            _networkRequestThread.start()
        }
        return _networkRequestThread
    }
}