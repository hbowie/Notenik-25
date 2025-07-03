//
//  FirstUseWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/25/25.
//  Copyright © 2025 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class FirstUseWindowController: NSWindowController {
    
    var juggler: CollectionJuggler?
    
    var firstUseVC: FirstUseViewController?
    
    var firstUseInfo: FirstUseInfo {
        get {
            if let fui = firstUseVC?.firstUseInfo {
                return fui
            } else {
                return FirstUseInfo()
            }
        }
        set {
            if let vc = firstUseVC {
                vc.firstUseInfo = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is FirstUseViewController {
            firstUseVC = contentViewController as? FirstUseViewController
            firstUseVC!.firstUseWC = self
        }
    }

}
