//
//  SyncViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/20/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import NotenikLib
import NotenikUtils

class SyncViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var syncWC: SyncWindowController?

    @IBOutlet var leftPathLabel: NSTextField!
    
    @IBOutlet var rightPathLabel: NSTextField!
    
    @IBOutlet var directionPopUp: NSPopUpButton!
    
    @IBOutlet var honorBlanksPopUp: NSPopUpButton!
    
    @IBOutlet var actionsPopUp: NSPopUpButton!
    
    var leftURL: URL?
    var rightURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leftPathLabel.stringValue = "Not Yet Selected"
        rightPathLabel.stringValue = "Not Yet Selected"
    }
    
    @IBAction func selectLeft(_ sender: Any) {
        let openPanel = prepCollectionOpenPanel()
        if let leftDir = AppPrefs.shared.leftSync {
            openPanel.directoryURL = leftDir
        }
        let result = openPanel.runModal()
        if result == .OK {
            leftURL = openPanel.url!
            AppPrefs.shared.leftSync = leftURL!.deletingLastPathComponent()
            leftPathLabel.stringValue = leftURL!.path()
        }
    }
    
    @IBAction func selectRight(_ sender: Any) {
        let openPanel = prepCollectionOpenPanel()
        if let rightDir = AppPrefs.shared.rightSync {
            openPanel.directoryURL = rightDir
        }
        let result = openPanel.runModal()
        if result == .OK {
            rightURL = openPanel.url!
            AppPrefs.shared.rightSync = rightURL!.deletingLastPathComponent()
            rightPathLabel.stringValue = rightURL!.path()
        }
    }
    
    /// Prep an Open Panel to use for selecting/creating a Collection folder
    func prepCollectionOpenPanel() -> NSOpenPanel {
        
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Notenik Folder to Sync"
        /* let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        } */
        // openPanel.directoryURL = home
        openPanel.showsResizeIndicator = true
        openPanel.prompt = "Select"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        return openPanel
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        syncWC!.close()
    }
    
    @IBAction func okToProceed(_ sender: Any) {
        
        guard leftURL != nil else {
            communicateError("Left-hand Collection Not Yet Specified", alert: true)
            return
        }
        
        guard rightURL != nil else {
            communicateError("Right-hand Collection Not Yet Specified", alert: true)
            return
        }
        
        guard leftURL != rightURL else {
            communicateError("Left and Right-hand collections are the same", alert: true)
            return
        }
        
        let syncEngine = CollectionSync()
        
        var direction: SyncDirection = .bidirectional
        switch directionPopUp.indexOfSelectedItem {
        case 0: direction = .bidirectional
        case 1: direction = .leftToRight
        case 2: direction = .rightToLeft
        default: break
        }
        
        var respectBlanks = true
        switch honorBlanksPopUp.indexOfSelectedItem {
        case 0: respectBlanks = true
        case 1: respectBlanks = false
        default: break
        }
        
        var syncActions: SyncActions = .logOnly
        switch actionsPopUp.indexOfSelectedItem {
        case 0: syncActions = .logOnly
        case 1: syncActions = .logDetails
        case 2: syncActions = .logSummary
        default: break
        }
        
        let syncTotals = SyncTotals()
        
        let synced = syncEngine.sync(leftURL: leftURL!,
                                     rightURL: rightURL!,
                                     syncTotals: syncTotals,
                                     direction: direction,
                                     syncActions: syncActions,
                                     respectBlanks: respectBlanks)
        
        
        
        if synced {
            let dialog = NSAlert()
            dialog.alertStyle = .informational
            dialog.messageText = "Sync was Completed"
            dialog.informativeText = syncTotals.totalsMsg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        } else {
            communicateError("Sync Could Not Be Completed", alert: true)
        }
        
        syncWC!.close()
    }
    
    func communicateInfo(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "SyncViewController",
                          level: .info,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .informational
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "SyncViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
}
