//
//  Statistics.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/7/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Foundation

class Statistics {
    let id: String
    var downloadSpeed: Double = 0
    var maxDownloadSpeed: Double = 0
    var uploadSpeed: Double = 0
    var maxUploadSpeed: Double = 0
    
    var uploadLimited: Bool {
        return maxUploadSpeed > 0
    }
    
    var downloadLimited: Bool {
        return maxDownloadSpeed > 0
    }

    
    init (id: String) {
        self.id = id
    }
}