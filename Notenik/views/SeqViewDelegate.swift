//
//  SeqViewDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 4/24/25.
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
import Cocoa

class SeqViewDelegate: NSObject, NSTextFieldDelegate {
    
    var seqView: SeqView!
    
    var fieldID = ""
    
    init(seqView: SeqView, fieldID: String) {
        super.init()
        self.seqView = seqView
        self.fieldID = fieldID
    }
    
    func controlTextDidChange(_ notification: Notification) {
        seqView.textDidChange(id: fieldID)
    }
    
}
