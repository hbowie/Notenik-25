//
//  SyncWindowController.swift
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

class SyncWindowController: NSWindowController {
    
    var juggler: CollectionJuggler?
    
    var collectionWC: CollectionWindowController?
    
    var syncVC: SyncViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is SyncViewController {
            syncVC = contentViewController as? SyncViewController
            syncVC!.syncWC = self
        }
    }

}
