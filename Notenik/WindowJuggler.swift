//
//  JuggledItems.swift
//  Notenik
//
//  Created by Herb Bowie on 2/24/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class WindowJuggler: NSObject, Sequence {
    
    var items: [JuggledWindow] = []
    
    var highestWindowNumber = -1
    
    var lastWindow: CollectionWindowController? = nil
    
    override init() {
        super.init()
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var count: Int {
        return items.count
    }
    
    func getItem(at index: Int) -> JuggledWindow? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
    
    // Keep track of open collection windows. 
    func registerWindow(window: CollectionWindowController) {
        
        // If it's already registered, then we need go no further.
        for item in self {
            if let cwc = item.cwc {
                if cwc as AnyObject === window as AnyObject {
                    return
                }
            }
        }
        
        highestWindowNumber += 1
        window.windowNumber = highestWindowNumber
        
        let newItem = JuggledWindow(controller: window)
        if !newItem.path.isEmpty {
            if let item = findItem(withPath: newItem.path) {
                item.cwc = window
                return
            }
        }
        
        items.append(newItem)
        
        if let oldWindow = lastWindow {
            let oldWindowPosition = oldWindow.window?.frame
            let newWindowPosition = oldWindowPosition?.offsetBy(dx: 50, dy: -50)
            if (newWindowPosition != nil) {
                window.window?.setFrame(newWindowPosition!, display: true)
            }
        }
        
        lastWindow = window
    }
    
    /// Take appropriate actions when a Collection window is closing.
    /// - Parameter wc: The window controller for the window that is closing.
    /// - Returns: The number of remaining open, visible collection windows.
    func windowClosing(withController: CollectionWindowController) -> Int {

        var windowCount = 0
        for item in self {
            if let nextWC = item.cwc {
                if nextWC.window == nil {
                    // Don't count it
                } else {
                    if nextWC as AnyObject === withController as AnyObject {
                        item.cwc = nil
                        // This is the closing window -- don't count it
                    } else if !nextWC.window!.isVisible {
                        // Don't count it if it is not visible
                    } else if nextWC.io == nil {
                        // Don't count it if no i/o module
                    } else if nextWC.io!.collectionOpen {
                        // Count it if collection is open
                        windowCount += 1
                    }
                }
            }

        }
        return windowCount
    }
    
    func findWindow(withTitle: String) -> JuggledWindow? {
        for item in self {
            guard let window = item.cwc?.window else { continue }
            if window.title == withTitle {
                return item
            }
        }
        return nil
    }
    
    func findWindow(withController: CollectionWindowController) -> JuggledWindow? {
        for item in self {
            if item.cwc as AnyObject === withController as AnyObject {
                return item
            }
        }
        return nil
    }
    
    func findWindow(withURL desiredURL: URL) -> JuggledWindow? {
        if let item = findItem(withURL: desiredURL) {
            if item.cwc == nil {
                return nil
            } else {
                return item
            }
        }
        return nil
    }
    
    func findItem(withURL desiredURL: URL) -> JuggledWindow? {
        return findItem(withPath: desiredURL.path)
    }
    
    func findItem(withPath desiredPath: String) -> JuggledWindow? {
        
        let targetItem = JuggledWindow(path: desiredPath)
        for item in self {
            if item == targetItem {
                return item
            }
        }
        return nil
    }
    
    /// Create an iterator. Note that no more than one iterator should be in operation at a time. 
    /// - Returns: An Iterator.
    func makeIterator() -> JuggledIterator {
        return JuggledIterator(items: self)
    }
    
    /// Define the iteration process.
    public class JuggledIterator: IteratorProtocol {
        
        public typealias Element = JuggledWindow
        
        private var index = -1
        
        var juggledItems: WindowJuggler!
        
        public init(items: WindowJuggler) {
            self.juggledItems = items
        }
        
        public func next() -> JuggledWindow? {
            
            index += 1
            return juggledItems.getItem(at: index)
        }
    }

}
