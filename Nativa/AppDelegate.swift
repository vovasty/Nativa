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

struct DownloadFilesAddedNotification: NotificationProtocol {
    let downloads: [(path: URL, download: Download)]
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate{
    private var refreshTimer: Timer!

    
    func connect() {
        refreshTimer.stop()
        Datasource.instance.closeAllConnections()

        guard let processes = UserDefaults.standard[kAccountsKey] as? [[String: AnyObject]] else {
            logger.error("no settings")
            return
        }
        
        let connectHandler: (Error?) -> Void = {(error) -> Void in
            guard error == nil else {
                logger.debug("unable to connect \(error)")
                return
            }
            
            self.refreshTimer.start()
        }
        
        for process in processes {
            guard let scgi = (process["scgiPort"] as? String)?.host(port: 5000), let name = process["name"] as? String else {
                logger.error("invalid process entry \(process)")
                continue
            }
            guard let useSSH = process["useSSH"] as? Bool, useSSH else {
                Datasource.instance.addConnection(id: name, host: scgi.host, port: scgi.port, connect: connectHandler)
                continue
            }
            
            guard let sshHost = (process["sshHost"] as? String)?.host(port: 22),
                  let sshUser = process["sshUser"] as? String,
                  let sshPassword = process["sshPassword"] as? String else {
                    logger.error("invalid process entry \(process)")
                    continue
            }
            
            Datasource.instance.addConnection(id: name, user: sshUser, host: sshHost.host, port: sshHost.port, password: sshPassword, serviceHost: scgi.host, servicePort: scgi.port, connect: connectHandler)
        }
    }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.setValue(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        NSUserNotificationCenter.default.delegate = self
        
        notificationCenter.add(owner: self){ (state: DatasourceConnectionStateDidChange) -> Void in
            switch state.state {
            case .Disconnected(_):
                let center = NSUserNotificationCenter.default
                center.removeAllDeliveredNotifications()
                let note = NSUserNotification()
                note.title = "Error"
                note.informativeText = "Unable to connect"
                note.hasActionButton = true
                note.actionButtonTitle = "Try again"
                note.userInfo = ["action": NotificationActions.Reconnect.rawValue]
                
                dispatch_main { center.scheduleNotification(note) }
            default:
                break
            }
        }
        
        refreshTimer = Timer(timeout: Config.refreshTimeout) { (Void) -> Void in
                Datasource.instance.update()
        }

        connect()
    }
    
    private func addDownloads(fromURL: [URL]) {
        Datasource.instance.parse(urls: fromURL) { (parsed, error) -> Void in
            guard let parsed = parsed, error == nil else {
                logger.error("unable to open files: \(error)")
                return
            }
            
            notificationCenter.postOnMain(DownloadFilesAddedNotification(downloads: parsed))
        }

    }
    
    func application(_ sender: NSApplication,
        openFiles filenames: [String]) {
        
            let filenames = filenames.map { (s) -> URL in return URL(fileURLWithPath: s) }
            addDownloads(fromURL: filenames)
            sender.reply(toOpenOrPrint: .success)
    }

    
    //hide window instead of close
    //http://iswwwup.com/t/4904b499b7a1/osx-how-to-handle-applicationshouldhandlereopen-in-a-non-document-based-st.html
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }

        for window in sender.windows {
                window.makeKeyAndOrderFront(self)
        }
        
        return true
    }
    
    @objc
    @IBAction
    private func openDocument(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["org.bittorrent.torrent", "torrent"]
        panel.beginSheetModal(for: NSApp.mainWindow!) { (flag) -> Void in
            
            guard flag == NSFileHandlingPanelOKButton else { return }
            
            self.addDownloads(fromURL: panel.urls)
        }
    }
    
    //MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(_ center: NSUserNotificationCenter,
                                didActivate notification: NSUserNotification) {
            center.removeDeliveredNotification(notification)
            guard let actionRaw = notification.userInfo?["action"] as? Int, let action = NotificationActions(rawValue: actionRaw) else {
                return
            }
            
            switch action {
            case .Reconnect:
                connect()
            }
    }
}

