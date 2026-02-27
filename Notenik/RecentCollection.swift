//
//  RecentCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 2/26/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikLib

class RecentCollection: Comparable, CustomStringConvertible {

    var url: URL!
    var fullPath = ""
    var title = ""
    
    init(url: URL) {
        self.url = url
        self.fullPath = url.path
        if fullPath.hasSuffix("/") {
            fullPath.removeLast()
        }
        title = AppPrefs.shared.idFolderFrom(url: url)
    }
    
    var description: String {
        return "\(title)"
    }
    
    static func < (lhs: RecentCollection, rhs: RecentCollection) -> Bool {
        return lhs.fullPath < rhs.fullPath
    }
    
    static func == (lhs: RecentCollection, rhs: RecentCollection) -> Bool {
        return lhs.fullPath == rhs.fullPath
    }

}
