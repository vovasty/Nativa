//
//  AppDelegate.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

enum NotificationActions: Int {
    case Reconnect = 0
}

struct DownloadFilesAddedNotification: Notification {
    let downloads: [(path: NSURL, download: Download)]
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate{
    private var refreshTimer: Timer!

    
    var reconnectCounter = 0
    var maxReconnectCounter = 4
    var reconnectTimeout = 1
    var refreshTimeout = 5
    
    func reconnect() {
        reconnectCounter = 0
        connect()
    }
    
    private func connect() {
        refreshTimer.stop()
        self.reconnectCounter++

        guard reconnectCounter <= maxReconnectCounter else {
            let center = NSUserNotificationCenter.defaultUserNotificationCenter()
            center.removeAllDeliveredNotifications()
            let note = NSUserNotification()
            note.title = "Error"
            note.informativeText = "Unable to connect"
            note.hasActionButton = true
            note.actionButtonTitle = "Try again"
            note.userInfo = ["action": NotificationActions.Reconnect.rawValue]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                center.scheduleNotification(note)
            })
            return
        }
        
        guard let processes = NSUserDefaults.standardUserDefaults()["processes"] as? [[String: AnyObject]] else {
            logger.error("no settings")
            return
        }
        
        let connectHandler: (NSError?) -> Void = {(error) -> Void in
            guard error == nil else {
                logger.debug("unable to connect \(error)")
                return
            }
            
            self.reconnectCounter = 0
            self.refreshTimer.start()
        }
        
        for process in processes {
            guard let scgi = (process["scgiPort"] as? String)?.hosAndPort(5000), let name = process["name"] as? String else {
                logger.error("invalid process entry \(process)")
                continue
            }
            guard let useSSH = process["useSSH"] as? Bool where useSSH else {
                Datasource.instance.addConnection(name, host: scgi.host, port: scgi.port, connect: connectHandler)
                continue
            }
            
            guard let sshHost = (process["sshHost"] as? String)?.hosAndPort(22),
                  let sshUser = process["sshUser"] as? String,
                  let sshPassword = process["sshPassword"] as? String else {
                    logger.error("invalid process entry \(process)")
                    continue
            }
            
            Datasource.instance.addConnection(name, user: sshUser, host: sshHost.host, port: sshHost.port, password: sshPassword, serviceHost: scgi.host, servicePort: scgi.port, connect: connectHandler)
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        
        notificationCenter.add(self){ (state: DatasourceConnectionStateDidChange) -> Void in
            
            switch state.state {
            case .Disconnected(_):
                //reconnect after a delay
                dispatch_after(dispatch_time (DISPATCH_TIME_NOW , Int64(UInt64(self.reconnectTimeout) * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () in
                    self.connect()
                }
            default:
                break
            }
        }
        
        refreshTimer = Timer(timeout: refreshTimeout) { (Void) -> Void in
                Datasource.instance.update()
        }

        
        connect()
    }
    
    private func addDownloadsFromUrls(urls: [NSURL]) {
        Datasource.instance.parseTorrents(urls) { (parsed, error) -> Void in
            guard let parsed = parsed where error == nil else {
                logger.error("unable to open files: \(error)")
                return
            }
            
            notificationCenter.postOnMain(DownloadFilesAddedNotification(downloads: parsed))
        }

    }
    
    func application(sender: NSApplication,
        openFiles filenames: [String]) {
            
            let filenames = filenames.map { (s) -> NSURL in return NSURL(fileURLWithPath: s) }
            addDownloadsFromUrls(filenames)
            sender.replyToOpenOrPrint(.Success)
    }

    
    //hide window instead of close
    //http://iswwwup.com/t/4904b499b7a1/osx-how-to-handle-applicationshouldhandlereopen-in-a-non-document-based-st.html
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag{
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        
        return true
    }
    
    @IBAction func openDocument(sender: AnyObject) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["org.bittorrent.torrent", "torrent"]
        panel.beginSheetModalForWindow(NSApp.mainWindow!) { (flag) -> Void in
            self.addDownloadsFromUrls(panel.URLs)
        }
    }
    
    //MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(center: NSUserNotificationCenter,
        didActivateNotification notification: NSUserNotification) {
            center.removeDeliveredNotification(notification)
            guard let actionRaw = notification.userInfo?["action"] as? Int, let action = NotificationActions(rawValue: actionRaw) else {
                return
            }
            
            switch action {
            case .Reconnect:
                reconnect()
            }
    }
}

