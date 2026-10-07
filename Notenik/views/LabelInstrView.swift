//
//  LabelInstrView.swift
//  Notenik
//
//  Created by Herb Bowie on 9/25/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import Cocoa

import NotenikLib
import NotenikUtils

public class LabelInstrView: MacEditView {
    
    var stack:      NSStackView!
    var textField:  NSTextField!
    var infoButton: NSButton!
    
    var view: NSView {
        return stack
    }
    
    public var text: String {
        get {
            return textField.stringValue
        }
        set {
            textField.stringValue = newValue
        }
    }
    
    public init() {
        buildView()
    }
    
    func buildView() {
        var controls = [NSView]()
        
        textField = NSTextField(labelWithString: "")
        AppPrefsCocoa.shared.setTextEditingFont(object: textField)
        textField.isSelectable = true
        controls.append(textField)
        
        let infoButton = NSButton(title: "ℹ️", target: self, action: #selector(infoButtonClicked))
        controls.append(infoButton)
        
        stack = NSStackView(views: controls)
        stack.orientation = .horizontal
    }
    
    @objc func infoButtonClicked() {
        print("Info Button Clicked!")
    }
    
}
