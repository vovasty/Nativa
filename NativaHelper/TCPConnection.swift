//
//  TCPConnection.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Foundation

class TCPConnection: NSObject, Connection, StreamDelegate {
    private var iStream: InputStream?
    private var oStream: NSOutputStream?
    private var requestData: Data?
    private var responseData: NSMutableData?
    private var responseBuffer: [UInt8]?
    private var sentBytes: Int = 0
    private var requestSent: Bool = false
    var maxPacket = 4096
    var maxResponseSize = 1048576
    private let disconnect: (ErrorProtocol?)->Void
    private var response: ((Data?, ErrorProtocol?) -> Void)?
    let host: String
    let port: UInt16
    let queue = DispatchQueue(label: "net.ararmzamzam.nativa.helper.TCPConnection", attributes: DispatchQueueAttributes.serial)
    let requestSemaphore = DispatchSemaphore(value: 1)
    var timeout: Double = 60
    var runLoopModes = [RunLoopMode.commonModes.rawValue]
    
    init(host: String,
        port: UInt16,
        connect: (ErrorProtocol?)->Void,
        disconnect: (ErrorProtocol?)->Void) {
            self.disconnect = disconnect
            self.host = host
            self.port = port
        
            super.init()
            
        connect(nil)
    }
    
    func request(_ data: Data, response: (Data?, ErrorProtocol?) -> Void) {
        queue.async { () -> Void in
            guard self.requestSemaphore.wait(timeout: DispatchTime.now() + self.timeout) == .Success else {
                response(nil, RTorrentError.unknown(message: "timeout"))
                return
            }
            
            self.requestData = data
            self.responseData = NSMutableData()
            self.response = response
            self.requestSent = false
            self.responseBuffer = Array(repeating: 0, count: self.maxPacket)
            
            if self.oStream?.streamStatus == .open {
                self.stream(self.oStream!, handle: Stream.Event.hasSpaceAvailable)
            }
            else {
                self.perform(#selector(self.open), on: TCPConnection.networkRequestThread, with: nil, waitUntilDone: false, modes: self.runLoopModes)
            }
        }
    }
    
    @objc
    private func open() {
        Stream.getStreamsToHost(withName: self.host, port: Int(self.port), inputStream: &self.iStream, outputStream: &self.oStream)
        iStream?.delegate = self
        oStream?.delegate = self
        
        let runLoop = RunLoop.current
        for runLoopMode in runLoopModes {
            oStream?.schedule(in: runLoop, forMode: RunLoopMode(rawValue: runLoopMode))
            iStream?.schedule(in: runLoop, forMode: RunLoopMode(rawValue: runLoopMode))
        }

        iStream?.open()
        oStream?.open()
    }
    
    private func requestDidSent() {
        logger.debug("requestDidSent")
        requestSent = true
    }
    
    private func errorOccured(_ error: ErrorProtocol) {
        logger.debug("stream error: \(error)")
        disconnect(error)
        cleanup()
    }
    
    private func responseDidReceived() {
        logger.debug("responseDidReceived")
        response?((responseData! as Data), nil)
        cleanup()
    }
    
    private func cleanup(){
        logger.debug("cleanup")

        iStream?.delegate = nil
        oStream?.delegate = nil

        let runLoop = RunLoop.current
        for runLoopMode in runLoopModes {
            oStream?.remove(from: runLoop, forMode: RunLoopMode(rawValue: runLoopMode))
            iStream?.remove(from: runLoop, forMode: RunLoopMode(rawValue: runLoopMode))
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
        requestSemaphore.signal()
    }
    
    //MARK: NSStreamDelegate
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch(eventCode) {
        case Stream.Event.hasSpaceAvailable:
            guard let stream = aStream as? NSOutputStream where stream == oStream else{
                assert(false, "unexpected stream")
                return
            }
            
            guard let requestData = requestData else {
                logger.debug("no data to send")
                return
            }
            
            guard !requestSent else {
                return
            }
            
            let buf = (requestData as NSData).bytes.advanced(by: sentBytes)
            let size = (requestData.count - sentBytes) > maxPacket ? maxPacket : (requestData.count - sentBytes)
            let actuallySent = oStream!.write(UnsafePointer<UInt8>(buf), maxLength: size)
            sentBytes += actuallySent
            
            if sentBytes == requestData.count {
                requestDidSent()
            }
        case Stream.Event.hasBytesAvailable:
            guard let stream = aStream as? InputStream where stream == iStream else{
                logger.debug("unexpected stream: aStream(\((aStream as? InputStream))) == iStream(\(iStream)) =\((aStream as? InputStream) == iStream)")
//                assert(false, "unexpected stream")
                return
            }
            
            guard let responseData = responseData else {
                logger.debug("no buffer to receive")
                return
            }
            
            guard responseData.length < maxResponseSize else {
                errorOccured(RTorrentError.unknown(message: "response is too big"))
                return
            }
            
            let actuallyRead = stream.read(&responseBuffer!, maxLength: maxPacket)
            
            guard actuallyRead > 0 else {
                return
            }
            
            responseData.append(responseBuffer!, length: actuallyRead)
        case Stream.Event.endEncountered:
            if aStream === oStream {
                if !requestSent {
                    errorOccured(RTorrentError.unknown(message: "stream closed before request did send"))
                }
                return
            }
            if aStream === iStream {
                responseDidReceived()
                return
            }
            assert(false, "unexpected stream")
        case Stream.Event.errorOccurred:
            guard let error = aStream.streamError?.localizedDescription else {
                errorOccured(RTorrentError.unknown(message: "unknown stream error"))
                return
            }
            
            errorOccured(RTorrentError.unknown(message: error))
        default:
            logger.debug("skipped event event \(eventCode)")
        }
    }
    
    //MARK: Thread
    @objc
    private class func networkRequestThreadEntryPoint(_ object: AnyObject) {
        autoreleasepool {
            Thread.current.name = "Nativa"
    
            let runLoop = RunLoop.current
            runLoop.add(NSMachPort(), forMode:RunLoopMode.defaultRunLoopMode)
            runLoop.run()
        }
    }

    private static var networkRequestThread: Thread = {
        let networkRequestThread = Thread(target: TCPConnection.self,
                                          selector: #selector(TCPConnection.networkRequestThreadEntryPoint(_:)),
                                          object: nil)
        
        networkRequestThread.start()
        return networkRequestThread
    }()
}
