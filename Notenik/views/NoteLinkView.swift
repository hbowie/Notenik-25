//
//  NoteLinkView.swift
//  Notenik
//
//  Created by Herb Bowie on 7/30/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class NoteLinkView: MacEditView {
    
    var comboField: NSComboBox!
    
    var dataSource: NoteLinkDataSource!
    
    var view: NSView {
        return comboField
    }

    var text: String {
        get {
            return comboField.stringValue
        }
        set {
            comboField.stringValue = newValue
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        comboField = NSComboBox(string: "")
        comboField.usesDataSource = true
        dataSource = NoteLinkDataSource()
        comboField.dataSource = dataSource
        // comboField.delegate = comboDataSource
        comboField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: comboField)
    }
    
    func loadFromIO(io: NotenikIO) {
        guard let nlDef = io.collection?.noteLinkDef else { return }
        guard let fieldType = nlDef.fieldType as? NoteLinkType else { return }
        dataSource.loadFromIO(io: io, fieldType: fieldType)
    }
}
