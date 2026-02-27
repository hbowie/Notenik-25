//
//  JuggledWindow.swift
//  Notenik
//
//  Created by Herb Bowie on 2/24/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object representing one collection window
class JuggledWindow: Comparable {
    
    var cwc:        CollectionWindowController?
    var _path:      String = ""
    
    init() {
 
    }
    
    convenience init(path: String) {
        self.init()
        self.path = path
    }
    
    convenience init(path: String, controller: CollectionWindowController) {
        self.init()
        self.path = path
        self.cwc = controller
    }
    
    convenience init(controller: CollectionWindowController) {
        self.init()
        self.cwc = controller
    }
    
    var path: String {
        get {
            if _path.isEmpty {
                checkControllerForPath()
            }
            return _path
        }
        set {
            _path = newValue
            if _path.hasSuffix("/") {
                _path.removeLast()
            }
        }
    }
    
    func checkControllerForPath() {
        guard let controller = cwc else { return }
        guard let io = controller.io else { return }
        guard io.collectionOpen else { return }
        guard let collection = io.collection else { return }
        _path = collection.fullPath
        if _path.hasSuffix("/") {
            _path.removeLast()
        }
    }
    
    func set(url: URL) {
        path = url.path
    }
    
    static func < (lhs: JuggledWindow, rhs: JuggledWindow) -> Bool {
        return lhs.path < rhs.path
    }
    
    static func == (lhs: JuggledWindow, rhs: JuggledWindow) -> Bool {
        return lhs.path == rhs.path
    }

}
