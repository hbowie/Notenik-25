//
//  ClonerViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/26/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class ClonerViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var clonerWC: ClonerWindowController?
    
    var sourceURL: URL?

    @IBOutlet var sourceText: NSTextField!
    
    @IBOutlet var destinationText: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceText.stringValue = ""
        destinationText.stringValue = ""
    }
    
    @IBAction func pickSource(_ sender: Any) {
        
        let openPanel = NSOpenPanel();
        if let parentURL = clonerWC?.collectionWC?.io?.collection?.lib.getURL(type: .parent) {
            openPanel.directoryURL = parentURL
        }
        openPanel.title = "Identify Folder to Clone"
        openPanel.prompt = "Choose Input Folder"
        openPanel.message = "Identify Folder to Clone"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let result = openPanel.runModal()
        guard result == .OK else { return }
        guard let source = openPanel.url else { return }
        sourceURL = source
        sourceText.stringValue = source.path
    }
    
    @IBAction func pickDestination(_ sender: Any) {
        
        let openPanel2 = NSOpenPanel();
        openPanel2.title = "Identify Destination Folder"
        openPanel2.prompt = "Choose Output Folder"
        openPanel2.message = "Identify Output Folder"
        openPanel2.showsResizeIndicator = true
        openPanel2.showsHiddenFiles = false
        openPanel2.canChooseDirectories = true
        openPanel2.canCreateDirectories = true
        openPanel2.canChooseFiles = false
        openPanel2.allowsMultipleSelection = false
        let result2 = openPanel2.runModal()
        guard result2 == .OK else { return }
        guard let destination = openPanel2.url else { return }
        destinationText.stringValue = destination.path
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        clonerWC!.close()
    }
    
    @IBAction func clone(_ sender: Any) {
        
        guard sourceURL != nil else {
            communicateError("Source URL has not been specified", alert: true)
            return
        }
        
        let destinationURL = NSURL.fileURL(withPath: destinationText.stringValue)
        
        let parms = CloneParms()
        
        let creator = CloneCreator()
        
        let (msg, fileCount) = creator.clone(source: sourceURL!,
                                             destination: destinationURL,
                                             parms: parms)
        
        if !msg.isEmpty {
            communicateError(msg, alert: true)
        }
        
        if fileCount > 0 {
            let dialog = NSAlert()
            dialog.alertStyle = .informational
            dialog.messageText = "\(fileCount) files copied to output clone"
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
        
        clonerWC!.close()
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ClonerViewController",
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
