//
//  NoteLinkDataSource.swift
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

class NoteLinkDataSource: NSObject, NSComboBoxDataSource {
    
    var noteTitles: [String] = []
    
    func loadFromIO(io: NotenikIO, fieldType: NoteLinkType) {
        noteTitles = []
        var i = 0
        while i < io.notesCount {
            let note = io.getNote(at: i)
            if fieldType.hasKlassSelector() && fieldType.getKlassSelector() != note!.klass.value {
                // skip this note
            } else if let title = note?.title {
                noteTitles.append(title.value)
            }
            i += 1
        }
        noteTitles.sort()
    }
    
    // Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return noteTitles.count
    }
    
    // Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        for title in noteTitles {
            if title.hasPrefix(string) {
                return title
            }
        }
        return nil
    }
    
    // Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if index < 0 || index >= noteTitles.count {
            return nil
        } else {
            return noteTitles[index]
        }
    }
    
    // Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var index: Int = 0
        for title in noteTitles {
            if title == string {
                return index
            }
            index += 1
        }
        return NSNotFound
    }

}
