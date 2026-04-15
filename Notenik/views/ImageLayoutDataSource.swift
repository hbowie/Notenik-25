//
//  ImageLayoutDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 4/6/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ImageLayoutDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    let layouts = ImageLayoutList.shared
    
    /// Initialization.
    override init() {
        super.init()
    }
    
    public var count: Int {
        return layouts.count
    }
    
    /// Return number of Items to be displayed in the Combo Box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return layouts.allLayouts.count
    }
    
    /// Return the item at the specified index.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return layouts.itemAt(index: index)
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        return layouts.startsWith(prefix: string)
    }
    
    /// Returns the index of the combo box item
    /// matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return layouts.matches(value: string)
    }

}
