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
    private var timer: dispatch_source_t!
    private let block: (Void)->Void
    private let timeout: UInt64
    var running: Bool { get { return timer == nil } }
    
    init(timeout:UInt64, block:(Void)->Void) {
        self.block = block
        self.timeout = timeout
    }
    
    deinit {
        if let timer = timer {
            dispatch_source_cancel(timer)
        }
    }
    
    func start(){
        if timer == nil {
            let queue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            
            // create our timer source
            timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
            
            // set the time to fire (we're only going to fire once,
            // so just fill in the initial time).
            
            let interval = timeout * NSEC_PER_SEC
            dispatch_source_set_timer(timer, dispatch_walltime(nil, 0), interval, 0);
            
            // Hey, let's actually do something when the timer fires!
            dispatch_source_set_event_handler(timer, {
                self.block()
            })
            dispatch_resume(timer)
        }
    }

    func stop() {
        if let t = timer {
            dispatch_source_cancel(t)
            timer = nil
        }
    }
}
