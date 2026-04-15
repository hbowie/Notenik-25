//
//  ImageLayoutView.swift
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

class ImageLayoutView: MacEditView {
    
    var imageLayoutField: NSComboBox!
    let dataSource = ImageLayoutDataSource()
    
    var view: NSView {
        return imageLayoutField
    }
    
    var text: String {
        get {
            if imageLayoutField.indexOfSelectedItem >= 0 {
                let selectedItem = dataSource.layouts.itemAt(index: imageLayoutField.indexOfSelectedItem)
                return selectedItem!
            } else {
                return imageLayoutField.stringValue
            }
        }
        set {
            var found = false
            var i = 0
            let newLower = newValue
            while !found && i < dataSource.count {
                if newLower == dataSource.layouts.itemAt(index: i) {
                    imageLayoutField.selectItem(at: i)
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                imageLayoutField.stringValue = newValue
            }
        }
    }
    
    init() {
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {

        imageLayoutField = NSComboBox(string: "")
        imageLayoutField.usesDataSource = true
        imageLayoutField.dataSource = dataSource
        imageLayoutField.delegate = dataSource
        imageLayoutField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: imageLayoutField)
    }

}
