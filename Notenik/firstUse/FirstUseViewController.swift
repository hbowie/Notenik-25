//
//  FirstUseViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/25/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class FirstUseViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var firstUseWC: FirstUseWindowController?
    
    var firstUseInfo: FirstUseInfo?

    @IBOutlet var folderName: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        firstUseWC!.close()
    }
    
    @IBAction func okeyDokey(_ sender: Any) {
        if firstUseInfo != nil {
            firstUseInfo!.folderName = folderName.stringValue
        }
        application.stopModal(withCode: .OK)
        firstUseWC!.close()
    }
    
}
