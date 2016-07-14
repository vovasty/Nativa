//
//  UInt.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/17/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Foundation

let TimeIntervalFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = DateComponentsFormatter.UnitsStyle.abbreviated
    formatter.includesApproximationPhrase = false
    formatter.includesTimeRemainingPhrase = true
    formatter.collapsesLargestUnit = true
    formatter.maximumUnitCount = 2
    formatter.allowedUnits = [Calendar.Unit.hour, Calendar.Unit.minute, Calendar.Unit.second]

    return formatter
}()

struct _Formatter {
    func string(fromSpeed speed: Double) -> String
    {
        return string(fromSpeed: speed,
            kb: NSLocalizedString("KB/s", comment: "Transfer speed (kilobytes per second)"),
            mb: NSLocalizedString("MB/s", comment: "Transfer speed (megabytes per second)"),
            gb: NSLocalizedString("GB/s", comment: "Transfer speed (gigabytes per second)")
        )
    }
    
    func string(fromInterval interval: Double) -> String {
        return TimeIntervalFormatter.string(from: interval)!
    }
    
    func string(fromSpeed speed: Double, kb: String, mb: String, gb: String) -> String
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
    
    func string(fromSize size: Double) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: ByteCountFormatter.CountStyle.file)
    }
}

let Formatter = _Formatter()
