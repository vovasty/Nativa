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
    private var response: ((NSData?, ErrorType?) -> Void)?
    let host: String
    let port: UInt16
    let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    let semaphore = dispatch_semaphore_create(1)
    var timeout: Int = 60
    var runLoopModes = [NSRunLoopCommonModes]
    
    init(host: String,
        port: UInt16,
        connect: (ErrorType?)->Void,
        disconnect: (ErrorType?)->Void) {
            self.disconnect = disconnect
            self.host = host
            self.port = port
            connect(nil)
    }
    
    func request(data: NSData, response: (NSData?, ErrorType?) -> Void) {
        dispatch_async(queue) { () -> Void in
            guard dispatch_semaphore_wait(self.semaphore, dispatch_time (DISPATCH_TIME_NOW , Int64(UInt64(self.timeout) * NSEC_PER_SEC))) == 0 else {
                response(nil, RTorrentError.UnknownError(message: "timeout"))
                return
            }
            self.requestData = data
            self.responseData = NSMutableData()
            self.response = response
            self.requestSent = false
            self.responseBuffer = Array(count: self.maxPacket, repeatedValue: 0)

            self.performSelector("_start", onThread: TCPConnection.networkRequestThread(), withObject: nil, waitUntilDone: false, modes: self.runLoopModes)
        }
    }
    
    func _start() {
        NSStream.getStreamsToHostWithName(self.host, port: Int(self.port), inputStream: &self.iStream, outputStream: &self.oStream)
        self.iStream?.delegate = self
        self.oStream?.delegate = self
        
        let runLoop = NSRunLoop.currentRunLoop()
        for runLoopMode in runLoopModes {
            oStream?.scheduleInRunLoop(runLoop, forMode: runLoopMode)
            iStream?.scheduleInRunLoop(runLoop, forMode: runLoopMode)
        }

        self.iStream?.open()
        self.oStream?.open()
    }

    
    private func requestDidSent() {
        logger.debug("requestDidSent")
        requestSent = true
    }
    
    private func errorOccured(error: ErrorType) {
        logger.debug("strem error: \(error)")
        disconnect(error)
        cleanup()
    }
    
    private func responseDidReceived() {
        logger.debug("responseDidReceived")
        response?(responseData, nil)
        cleanup()
    }
    
    private func cleanup(){
        logger.debug("cleanup")
        iStream?.close()
        oStream?.close()
        requestData = nil
        responseData = nil
        iStream = nil
        oStream = nil
        responseBuffer = nil
        sentBytes = 0
        requestSent = false
        dispatch_semaphore_signal(semaphore)
    }
    
    //MARK: NSStreamDelegate
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch(eventCode) {
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
            let actuallySent = stream.write(UnsafePointer<UInt8>(buf), maxLength: size)
            sentBytes += actuallySent
            
            if sentBytes == requestData.length {
                requestDidSent()
            }
        case NSStreamEvent.HasBytesAvailable:
            guard let stream = aStream as? NSInputStream where stream == iStream else{
                assert(false, "unexpected stream")
                return
            }
            
            guard let responseData = responseData else {
                logger.debug("no buffer to receive")
                return
            }
            
            guard responseData.length < maxResponseSize else {
                errorOccured(RTorrentError.UnknownError(message: "response is too big"))
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
                    errorOccured(RTorrentError.UnknownError(message: "stream closed before request did send"))
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
                errorOccured(RTorrentError.UnknownError(message: "unknown stream error"))
                return
            }
            
            errorOccured(RTorrentError.UnknownError(message: error))
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