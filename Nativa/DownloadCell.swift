//
//  DownloadCell.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class DownloadCell: NSTableCellView
{
    @IBOutlet weak var controlButton: NSButton!
    @IBOutlet weak var statusText: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    internal var progressIndicatorConstraints: [NSLayoutConstraint]?
    @IBOutlet weak var verticalSpaceConstraint: NSLayoutConstraint!
    private var tracking = false
    private var statusString: String = ""
    private var initialVerticalSpace: CGFloat = 0
    private var initialized = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard !initialized else { return }
        
        initialVerticalSpace = verticalSpaceConstraint.constant
        
        controlButton.image = NSImage(named:NSImageNameStopProgressFreestandingTemplate)
        controlButton.alternateImage = NSImage(named:NSImageNameRefreshFreestandingTemplate)
        
        initialized = true
    }
    
    var download: Download! { didSet {
        update()
        }
    }
    
    var groupName: String?
    
    class var height: CGFloat{
        return 63
    }
    
    var progressIndicatorHidden: Bool {
        get {
            return progressIndicator.hidden
        }
        
        set {
            guard newValue != progressIndicatorHidden else { return }

            progressIndicator.hidden = newValue
            verticalSpaceConstraint.constant = newValue ? 0 : initialVerticalSpace
            progressIndicator.hidden = newValue
            layoutSubtreeIfNeeded()
        }
    }
    
    override func updateTrackingAreas(){
        super.updateTrackingAreas()
        
        for area in self.trackingAreas as [NSTrackingArea]
        {
            if area.owner === self
            {
                self.removeTrackingArea(area)
            }
        }
        
        self.addTrackingAreaForView(controlButton)
    }
    
    
    override func mouseEntered(theEvent: NSEvent){
        tracking = true
        
        switch download.state
        {
        case .Stopped, .Paused, .Unknown:
            setHint( NSLocalizedString("Resume", comment: "") )
        case .Seeding, .Downloading, .Checking:
            setHint( NSLocalizedString("Stop", comment: "") )
        }
    }
    
    override func mouseExited(theEvent: NSEvent){
        unsetHint()
        tracking = false
    }
    
    func setHint(hint: String){
        statusText.stringValue = hint
    }
    
    func unsetHint(){
        statusText.stringValue = statusString
    }
    
    func addTrackingAreaForView(view: NSView, userInfo:[NSObject : AnyObject]? = nil) {
        
        let options: NSTrackingAreaOptions = [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveAlways];
        
        let rect: NSRect = view.frame
        
        let area: NSTrackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: userInfo)
        
        self.addTrackingArea(area)
    }
    
    
    private func update() {
        
        textField?.stringValue = download.title;
        
        imageView?.image = download.icon
        
        groupName = download.group?.title
        
        switch download.state
        {
        case .Seeding:
            progressIndicator.indeterminate = true
            progressIndicatorHidden = true
            controlButton.state = NSOffState
        case .Stopped, .Paused, .Unknown:
            controlButton.state = NSOnState
            progressIndicator.indeterminate = true
            progressIndicatorHidden = true
        case .Downloading, .Checking:
            controlButton.state = NSOffState
            progressIndicator.indeterminate = false
            progressIndicatorHidden = false
            let progress = 100 * (download.complete/download.size)
            progressIndicator.doubleValue = progress
        }
        
        progressIndicator.stopAnimation(nil)
        
        var speedPart: String?
        switch download.state
        {
        case .Downloading(let dl, _):
            speedPart = dl > 0 ? "\(Formatter.stringForSpeed(dl)), \(Formatter.stringForTimeInterval((download.size - download.complete)/(dl)))" : nil
        case .Seeding(let ul):
            speedPart = ul > 0 ? "\(Formatter.stringForSpeed(ul))" : nil
        case .Checking:
            let progress = 100 * (download.complete/download.size)
            statusString = String(format: "%.2f", progress)
        default:
            speedPart = nil
        }

        
        if let message = download.message where message.utf8.count > 0 {
            statusString = message
        }
        else {
            var peersPart: String!
            switch download.state
            {
            case .Stopped:
                peersPart = NSLocalizedString("stopped", comment: "download.-> status string")
            case .Paused:
                peersPart = NSLocalizedString("paused", comment:"download.-> status string")
            case .Downloading:
                peersPart = NSLocalizedString("downloading", comment:"download.-> status string")
            case .Seeding:
                peersPart = NSLocalizedString("seeding", comment:"download.-> status string")
            case .Checking:
                peersPart = NSLocalizedString("checking", comment: "download.-> status string")
            case .Unknown:
                peersPart = NSLocalizedString("unknown", comment: "download.-> status string")
            }
            
            if download.complete == download.size {
                statusString = String.localizedStringWithFormat("%@ — %@", Formatter.stringForSize(download.size), peersPart) + (speedPart == nil ? "" : " (\(speedPart!))")
            }
            else {
                statusString = String.localizedStringWithFormat("%@ of %@ — %@", Formatter.stringForSize(download.complete), Formatter.stringForSize(download.size), peersPart) + (speedPart == nil ? "" : " (\(speedPart!))")
            }
        }
        
        
        if !tracking {
            statusText.stringValue = statusString
        }
    }
    
    //draw delimiter
    override func drawRect(dirtyRect: NSRect) {
        
        if let textField = self.textField {
            
            let color: NSColor = NSColor(SRGBRed:0.80, green:0.80, blue:0.80, alpha:1)
            
            var rect = self.bounds
            rect.origin = NSPoint(x:NSMinX(textField.frame), y:0)
            rect.size.height = 1.0
            
            color.drawSwatchInRect(rect)
        }
        
        update()
    }
}