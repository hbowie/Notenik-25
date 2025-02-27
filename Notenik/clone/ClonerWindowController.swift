//
//  ClonerWindowController.swift
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

class ClonerWindowController: NSWindowController {
    
    var juggler: CollectionJuggler?
    
    var collectionWC: CollectionWindowController?
    
    var clonerVC: ClonerViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is ClonerViewController {
            clonerVC = contentViewController as? ClonerViewController
            clonerVC!.clonerWC = self
        }
    }
    
}
