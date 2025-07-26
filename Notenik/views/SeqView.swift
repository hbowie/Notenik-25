//
//  SeqView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/24/25.

//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

/// Custom Edit View for a Seq field.
class SeqView: MacEditView {
    
    var formatter: SeqFormatter?
    
    var seqParms = SeqParms()
    
    let appPrefs = AppPrefs.shared
    let appPrefsCocoa = AppPrefsCocoa.shared
    
    var stack: NSStackView!
    var textField: NSTextField!
    var label2: NSTextField?
    var formattedField: NSTextField?
    
    var originalSeqDelegate: SeqViewDelegate?
    var formattedSeqDelegate: SeqViewDelegate?
    
    let originalFieldID  = "original"
    let formattedFieldID = "formatted"
    
    var view: NSView {
        return stack
    }
    
    var text: String {
        get {
            return textField.stringValue
        }
        set {
            if formatter != nil && formattedField != nil {
                let seqValue = SeqValue(newValue, seqParms: seqParms)
                let (formatted, _) = formatter!.format(seq: seqValue.firstSeq, full: true)
                let backToOriginal = formatter!.unformat(formatted)
                if backToOriginal != newValue {
                    formatter = nil
                    formattedField!.stringValue = "<error>"
                }
                formattedField!.stringValue = formatted
            }
            textField.stringValue = newValue
        }
    }
    
    init(formatter: SeqFormatter?, parms: SeqParms) {
        self.formatter = formatter
        self.seqParms = parms
        buildView()
    }
    
    func buildView() {
        
        // var controls = [NSView]()
        stack = NSStackView()
        stack.orientation = .horizontal
        
        textField = NSTextField()
        AppPrefsCocoa.shared.setTextEditingFont(object: textField)
        
        if formatter != nil && !formatter!.isEmpty {
            originalSeqDelegate = SeqViewDelegate(seqView: self, fieldID: originalFieldID)
            textField.delegate = originalSeqDelegate
            stack.addView(textField, in: NSStackView.Gravity.leading)
            let label2 = NSTextField(labelWithString: " Formatted: ")
            AppPrefsCocoa.shared.setTextEditingFont(object: label2)
            stack.addView(label2, in: NSStackView.Gravity.center)
            formattedField = NSTextField()
            AppPrefsCocoa.shared.setTextEditingFont(object: formattedField!)
            formattedSeqDelegate = SeqViewDelegate(seqView: self, fieldID: formattedFieldID)
            formattedField!.delegate = formattedSeqDelegate
            stack.addView(formattedField!, in: NSStackView.Gravity.trailing)
        } else {
            stack.addView(textField, in: NSStackView.Gravity.leading)
        }
    }
    
    var textChanging = false
    
    func textDidChange(id: String) {
        guard !textChanging else { return }
        textChanging = true
        if id == originalFieldID {
            let seqValue = SeqValue(textField.stringValue, seqParms: seqParms)
            let (formatted, _) = formatter!.format(seq: seqValue.firstSeq, full: true)
            formattedField!.stringValue = formatted
        } else {
            let unformatted = formatter!.unformat(formattedField!.stringValue)
            textField.stringValue = unformatted
        }
        textChanging = false
    }
    
}
