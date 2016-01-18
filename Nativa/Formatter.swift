//
//  UInt.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/17/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

let TimeIntervalFormatter: NSDateComponentsFormatter = {
    let formatter = NSDateComponentsFormatter()
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Abbreviated
    formatter.includesApproximationPhrase = false
    formatter.includesTimeRemainingPhrase = true
    formatter.collapsesLargestUnit = true
    formatter.maximumUnitCount = 2
    formatter.allowedUnits = [NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]

    return formatter
}()

struct _Formatter {
    func stringForSpeed(speed: Double) -> String
    {
        return stringForSpeed(speed,
            kb: NSLocalizedString("KB/s", comment: "Transfer speed (kilobytes per second)"),
            mb: NSLocalizedString("MB/s", comment: "Transfer speed (megabytes per second)"),
            gb: NSLocalizedString("GB/s", comment: "Transfer speed (gigabytes per second)")
        )
    }
    
    func stringForTimeInterval(interval: Double) -> String {
        return TimeIntervalFormatter.stringFromTimeInterval(interval)!
    }
    
    func stringForSpeed(speed: Double, kb: String, mb: String, gb: String) -> String
    {
        var speed = speed / 1000
        
        if speed < 999.95 { //0.0 KB/s to 999.9 KB/s
            return String.localizedStringWithFormat("%.1f %@", speed, kb)
        }
        
        speed /= 1000.0
        
        if speed <= 99.995 { //1.00 MB/s to 99.99 MB/s
            return String.localizedStringWithFormat("%.2f %@", speed, mb)
        }
        else if speed <= 999.95 { //100.0 MB/s to 999.9 MB/s
            return String.localizedStringWithFormat("%.1f %@", speed, mb)
        }
        else {//insane speeds
            return String.localizedStringWithFormat("%.2f %@", (speed / 1000.0), gb)
        }
    }
    
    func stringForSize(size: Double) -> String {
        return NSByteCountFormatter.stringFromByteCount(Int64(size), countStyle: NSByteCountFormatterCountStyle.File)
    }
}

let Formatter = _Formatter()