//
//  SpokenViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/23/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
@preconcurrency import WebKit

import NotenikUtils
import NotenikLib
import NotenikMkdown

class SpokenViewController: NSViewController,
                            CollectionView,
                            WKUIDelegate,
                            WKNavigationDelegate {
    
    var collectionController:   CollectionWindowController?
    var wc:                     SpokenWindowController!
    var io:                     NotenikIO!
    
    var windowPosSet:           Bool = false
    
    var stackView:              NSStackView!

    var webView:                WKWebView!
    var webConfig:              WKWebViewConfiguration!
    var userContentController:  WKUserContentController!
    var dataStore:              WKWebsiteDataStore?
    
    var sortedNote:             SortedNote?
    var note:                   Note?
    
    var parms =                 DisplayParms()
    
    var mdResults =             TransformMdResults()
    
    /// Set up the view for this controller.
    override func loadView() {
        
        super.loadView()
        
        stackView = NSStackView()
        stackView.orientation = .vertical
        
        // Initialize WebKit stuff
        webConfig = WKWebViewConfiguration()
        let webPrefs = WKPreferences()
        if #available(macOS 11.0, *) {
            webConfig.limitsNavigationsToAppBoundDomains = false
        }
        webConfig.preferences = webPrefs
        
        dataStore = WKWebsiteDataStore.nonPersistent()
        webConfig.websiteDataStore = dataStore!
        
        webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        stackView.addArrangedSubview(webView)
        view = stackView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// Save any important info prior to the view's disappearance.
    override func viewWillDisappear() {
        saveNumbers()
        super.viewWillDisappear()
        if collectionController != nil {
            collectionController!.removeAuxWindow(wc.window!)
            collectionController!.closingSpokenWindow()
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Compliance with CollectionView.
    //
    // -----------------------------------------------------------
    
    var viewID = "spoken-display"
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    func focusOn(initViewID: String,
                 sortedNote: SortedNote?,
                 position: NotePosition?,
                 io: NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        self.io = io
        self.sortedNote = sortedNote
        note = sortedNote!.note
        
        if !windowPosSet {
            if let windowStr = io.collection?.scriptWindowPosStr {
                setNumbers(windowStr)
            }
            windowPosSet = true
        }
        
        display(note: note!)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Control window size and position.
    //
    // -----------------------------------------------------------
    
    /// Set position of window, given a string of formatted doubles.
    func setNumbers(_ windowStr: String) {
    
        guard !windowStr.isEmpty else { return }
        let numbers = windowStr.components(separatedBy: ";")
        guard numbers.count >= 4 else { return }
        
        guard let x2 = Double(numbers[0]) else { return }
        guard let y2 = Double(numbers[1]) else { return }
        guard let w = Double(numbers[2]) else { return }
        guard let h = Double(numbers[3]) else { return }
        var x = x2
        let flippedY = y2
        var width = w
        var height = h
        
        guard let mainScreen = NSScreen.main else { return }
        let visibleFrame = mainScreen.visibleFrame
        let minX = visibleFrame.minX
        let maxX = visibleFrame.maxX
        let minY = visibleFrame.minY
        let maxY = visibleFrame.maxY
        
        if width > maxX - minX {
            let priorWidth = width
            width = maxX - minX
            logInfo(msg: "Window width adjusted from \(priorWidth) to \(width)")
        }
        
        if x < minX || x > maxX || x + width > maxX {
            let priorX = x
            x = minX
            logInfo(msg: "Window x coordinate adjusted from \(priorX) to \(x)")
        }
        
        if height > maxY - minY {
            let priorHeight = height
            height = maxY - minY
            logInfo(msg: "Window height adjusted from \(priorHeight) to \(height)")
        }
        
        var y = maxY - flippedY - height
        if y < minY || y > maxY || y + height > maxY {
            let priorY = y
            y = maxY - height
            logInfo(msg: "Window y coordinate adjusted from \(priorY) to \(y)")
        }
        
        let frame = NSRect(x: x, y: y, width: width, height: height)
        wc.window!.setFrame(frame, display: true, animate: true)
    }
    /// Save position of window as a string by concatenating a series of formatted doubles.
    func saveNumbers() {
        guard let collection = io.collection else { return }
        var windowPosition = ""
        if let frame = wc.window?.frame {
            if let mainScreen = NSScreen.main {
                let visibleFrame = mainScreen.visibleFrame
                let maxY = visibleFrame.maxY
                let origin = frame.origin
                let size   = frame.size
                windowPosition.append("\(origin.x);")
                let originFlippedY = maxY - size.height - origin.y
                windowPosition.append("\(originFlippedY);")
                windowPosition.append("\(size.width);")
                windowPosition.append("\(size.height);")
            }
        }
        collection.scriptWindowPosStr = windowPosition
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Display a Note.
    //
    // -----------------------------------------------------------
    
    /// Generate the display from the last note provided
    func display(note: Note) {
        guard io != nil else { return }
        guard isViewLoaded else { return }
        // guard let window = wc.window else { return }
        // guard let collection = io!.collection else { return }
        // window.title = "Spoken Script for: \(sortedNote!.note.title.value)"
            
        parms.setFrom(note: note)
        
        let code = Markedup(format: parms.format)
        
        let mkdownOptions = MkdownOptions()
        parms.setMkdownOptions(mkdownOptions)
        
        let headInfo = MarkedupHeadInfo(withTitle: "Spoken Script for: \(note.title.value)",
                                        withAuthor: nil,
                                        withJS: nil,
                                        addins: [])
        parms.setCSS(headInfo: headInfo,
                     note: note)
        code.startDoc(headInfo: headInfo,
                      epub3: parms.epub3)
        
        code.startMain(klass: "pitch")
        
        let titleToDisplay = parms.compoundTitle(note: note, titleFormat: .html)
        
        var style = "clear:both;"
        var depth = note.depth
        if note.klass.title {
            style.append("margin-top:2em;margin-bottom:3em;")
        } else {
            if note.collection.slideDepth > 0 {
                depth = note.collection.slideDepth
            }
        }
        
        code.displayLine(opt: note.collection.titleDisplayOption,
                        text: titleToDisplay,
                         depth: depth,
                         addID: false,
                         idText: note.title.value,
                         style: style)
        
        mdResults = TransformMdResults()
        
        /*
        TransformMarkdown.mdToHtml(parserID: NotenikConstants.notenikParser,
                                   fieldType: NotenikConstants.bodyCommon,
                                   markdown: note.body.value,
                                   io: io,
                                   parms: parms,
                                   results: mdResults,
                                   noteID: note.noteID.commonID,
                                   noteText: note.noteID.text,
                                   noteFileName: note.noteID.commonFileName,
                                   note: note)
        code.append(mdResults.html)
         */
         
        
        if note.hasSpokenScript {
            // code.horizontalRule()
            // code.heading(level: 2, text: "Spoken Script")
            TransformMarkdown.mdToHtml(parserID: NotenikConstants.notenikParser,
                                       fieldType: NotenikConstants.spokenCommon,
                                       markdown: note.spokenScript,
                                       io: io,
                                       parms: parms,
                                       results: mdResults,
                                       noteID: note.noteID.commonID,
                                       noteText: note.noteID.text,
                                       noteFileName: note.noteID.commonFileName,
                                       note: note)
            code.append(mdResults.html)
        } else {
            code.paragraph(text: "No Spoken script for this slide")
        }
        
        code.finishMain()
        code.finishDoc()
        
        let base: URL? = Bundle.main.bundleURL
        var nav: WKNavigation?
        nav = webView.loadHTMLString(code.code, baseURL: base)
        if nav == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "NoteDisplayViewController",
                              level: .error,
                              message: "load html String returned nil")
        }
        
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Navigation. 
    //
    // -----------------------------------------------------------
    
    /// Override method from NSResponder.
    override func keyDown(with event: NSEvent) {
        
        guard collectionController != nil else {
            super.keyDown(with: event)
            return
        }
        
        let chars = event.charactersIgnoringModifiers
        if chars == " " || chars == "]"{
            collectionController!.goToNextNote(self)
            return
        } else if chars == "[" {
            collectionController!.goToPriorNote(self)
            return
        }
        
        let s   =   event.charactersIgnoringModifiers!
        let s1  =   s.unicodeScalars
        let s2  =   s1[s1.startIndex].value
        let s3  =   Int(s2)
        switch s3 {
        case NSUpArrowFunctionKey, NSLeftArrowFunctionKey:
            collectionController!.goToPriorNote(self)
            return
        case NSDownArrowFunctionKey, NSRightArrowFunctionKey:
            collectionController!.goToNextNote(self)
            return
        default:
            super.keyDown(with: event)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utilities
    //
    // -----------------------------------------------------------
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "SpokenViewController",
                          level: .info,
                          message: msg)
    }
    
}
