//
//  Preferences.swift
//  SwiftySSH
//
//  Created by Solomenchuk, Vlad on 8/17/15.
//  Copyright © 2015 Vladimir Solomenchuk. All rights reserved.
//

import Cocoa

class RTorrentPreferences: NSViewController {
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet var settings: NSUserDefaultsController!
    var notificationHandler: NSObjectProtocol?
    @IBOutlet weak var checkResult: NSButton!
    
    @IBAction func check(sender: AnyObject) {
        let defaults = settings.defaults
        let scgi = defaults["rtorrent.scgi"] as? String ?? "localhost:5000"
        self.checkResult.hidden = true
        
        if let ssh_hp = defaults["ssh.host"] as? String,
            let user = defaults["ssh.user"] as? String,
            let useSSH = defaults["rtorrent.useSSH"] as? Bool where useSSH && password.stringValue.utf8.count > 0 {
                
                let scgi = scgi.hosAndPort(5000)
                let ssh = ssh_hp.hosAndPort(5000)
            
                Datasource.instance.connect(user, host: ssh.host, port: ssh.port, password: password.stringValue, serviceHost: scgi.host, servicePort: scgi.port, connect: { (error) -> Void in
                    
                    guard error == nil else {
                        self.showError(error!)
                        return
                    }
                    
                    Datasource.instance.version({ (version, error) -> Void in
                        guard let version = version where error == nil else {
                            self.checkResult.title = error!.localizedDescription
                            self.checkResult.state = NSOffState
                            self.checkResult.hidden = false
                            return
                        }

                        self.checkResult.title = "api v\(version)"
                        self.checkResult.state = NSOnState
                        self.checkResult.hidden = false
                    })
                    
                })
        }
        
    }
    
    private func showError(error: NSError) {
        checkResult.title = error.localizedDescription
        checkResult.state = NSOffState
        checkResult.hidden = false
    }
    
    override func viewDidLoad() {
        notificationHandler = NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: self, queue: nil) { (note) -> Void in
            print("changed")
        }
    }
    
    deinit {
        if let notificationHandler = notificationHandler {
            NSNotificationCenter.defaultCenter().removeObserver(notificationHandler)
        }
    }
}