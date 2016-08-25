//
//  Timer.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/27/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

class Timer
{
    private var timer: DispatchSourceTimer!
    private let block: (Void)->Void
    private let timeout: Int
    private let queue: DispatchQueue
    var running: Bool { get { return timer == nil } }
    
    init(timeout: Int, queue: DispatchQueue = DispatchQueue.main, block:@escaping (Void)->Void) {
        self.block = block
        self.timeout = timeout
        self.queue = queue
    }
    
    deinit {
        if let timer = timer {
            timer.cancel()
        }
    }
    
    func start(immediately: Bool = false, repeatable: Bool = true){
        if timer == nil {
            // create our timer source
            timer = DispatchSource.makeTimerSource(queue: queue)
            
            let startTime = DispatchTime.now() + (immediately ? 0.0 : Double(timeout))
            
            if repeatable {
                timer.scheduleRepeating(deadline: startTime, interval: DispatchTimeInterval.seconds(timeout))
            }
            else {
                timer.scheduleOneshot(deadline: startTime)
            }
            
            timer.setEventHandler(handler: block)
            
            timer.resume()
        }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
