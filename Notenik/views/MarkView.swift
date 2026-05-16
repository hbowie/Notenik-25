//
//  MarkView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/29/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class MarkView: MacEditView {
    
    var markField: NSButton!
    
    var view: NSView {
        return markField
    }
    
    var text: String {
        get {
            if markField.state == .on {
                return "true"
            } else {
                return "false"
            }
        }
        set {
            let mark = MarkValue(newValue)
            if mark.isMarked {
                markField.state = .on
            } else {
                markField.state = .off
            }
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        markField = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        AppPrefsCocoa.shared.setTextEditingFont(object: markField)
    }
    
}
