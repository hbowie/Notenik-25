//
//  PresentViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/11/26.
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

class PresentViewController: NSViewController,
                             CollectionView,
                             WKUIDelegate,
                             WKNavigationDelegate {

    var collectionController:   CollectionWindowController?
    var wc:                     PresentWindowController!
    var io:                     NotenikIO!
    
    var windowPosSet:           Bool = false
    
    var stackView:              NSStackView!

    var webView:                WKWebView!
    var webConfig:              WKWebViewConfiguration!
    var userContentController:  WKUserContentController!
    var dataStore:              WKWebsiteDataStore?
    
    var boostFactor:            Float = 1.2
    
    let noteDisplay = NoteDisplay()
    
    // var sortedNote:             SortedNote?
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
            collectionController!.closingPresentWindow()
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Compliance with CollectionView.
    //
    // -----------------------------------------------------------
    
    var viewID = "present-display"
    
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
        // self.sortedNote = sortedNote
        note = sortedNote!.note
        
        if !windowPosSet {
            if let windowStr = io.collection?.presentWindowPosStr {
                setNumbers(windowStr)
            }
            windowPosSet = true
        }
        
        display(note: note!)
    }
    

    
    // -----------------------------------------------------------
    //
    // MARK: Display a Note.
    //
    // -----------------------------------------------------------
    
    /// Generate the display from the last note provided
    func display(note: Note) {
        
        self.note = note
        
        display()
    }
    
    func display() {
        guard note != nil else { return }
        guard io != nil else {
            communicateError("I/O module not available!")
            return
        }
        guard isViewLoaded else {
            communicateError("View not loaded!")
            return
        }
        guard let collection = io!.collection else { return }
        guard collection.displayMode == .presentation else {
            communicateError("Collection not in presentation mode", alert: true)
            return
        }
        

        
        // From NoteDisplayViewController
        webLinkFollowed(false)
        
        if collection.imgLocal {
            parms.imagesPath = NotenikConstants.filesFolderName
        }
            
        parms.setFrom(note: note!)
        parms.checkBoxMessageHandlerName = NotenikConstants.checkBoxMessageHandlerName
        parms.displayBoost = true
        parms.boostFactor = boostFactor
        parms.genPresentation = true
        
        mdResults = TransformMdResults()
        
        var imagePref: ImagePref = .light
        let appearance = view.effectiveAppearance
        if appearance.name.rawValue.lowercased().contains("dark") {
            imagePref = .dark
        } else {
            imagePref = .light
        }
        let html = noteDisplay.display(note!, io: io!, parms: parms, mdResults: mdResults, imagePref: imagePref)
        
        var base: URL? = Bundle.main.bundleURL
        var nav: WKNavigation?
        var tempHTML = false
        if collection.imgLocal {
            if let lib = io?.collection?.lib {
                let imgFolder = lib.getResource(type: .notes)
                let tempURL = imgFolder.url!.appendingPathComponent(NotenikConstants.tempDisplayBase).appendingPathExtension(NotenikConstants.tempDisplayExt)
                do {
                    try html.write(to: tempURL, atomically: true, encoding: .utf8)
                    tempHTML = true
                    base = imgFolder.url!
                    nav = webView.loadFileURL(tempURL, allowingReadAccessTo: imgFolder.url!)
                } catch {
                    communicateError("Could not write html to temporary file")
                }
            }
        }
        
        if !tempHTML {
            nav = webView.loadHTMLString(html, baseURL: base)
        }
        if nav == nil {
            communicateError("load html String returned nil")
        }
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
            logInfo("Window width adjusted from \(priorWidth) to \(width)")
        }
        
        if x < minX || x > maxX || x + width > maxX {
            let priorX = x
            x = minX
            logInfo("Window x coordinate adjusted from \(priorX) to \(x)")
        }
        
        if height > maxY - minY {
            let priorHeight = height
            height = maxY - minY
            logInfo("Window height adjusted from \(priorHeight) to \(height)")
        }
        
        var y = maxY - flippedY - height
        if y < minY || y > maxY || y + height > maxY {
            let priorY = y
            y = maxY - height
            logInfo("Window y coordinate adjusted from \(priorY) to \(y)")
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
        collection.presentWindowPosStr = windowPosition
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
        if chars == " " || chars == "]" {
            collectionController!.goToNextNote(self)
            return
        } else if chars == "[" {
            collectionController!.goToPriorNote(self)
            return
        } else if chars == "+" || chars == "=" {
            boostFactor += 0.1
            display()
            return
        } else if chars == "-" || chars == "_" {
            boostFactor -= 0.1
            display()
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
    
    func webLinkFollowed(_ followed: Bool) {
        guard let controller = collectionController else { return }
        controller.webLinkFollowed = followed
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Web View stuff.
    //
    // -----------------------------------------------------------
    
    /// This method gets called when the user requests to open a link in a new window.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            return nil
        }
        
        guard collectionController != nil else {
            return nil
        }
        
        collectionController!.launchLink(url: url)
        
        return nil
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            webLinkFollowed(true)
            decisionHandler(.allow)
            return
        }
        
        guard collectionController != nil else {
            webLinkFollowed(true)
            decisionHandler(.allow)
            return
        }
        
        guard navigationAction.targetFrame != nil else {
            collectionController!.launchLink(url: url)
            webLinkFollowed(false)
            decisionHandler(.cancel)
            return
        }
        
        /// Figure out how to handle this sort of URL.
        let link = NotenikLink(url: url)
        
        switch link.type {
        case .weblink, .aboutlink:
            if String(describing: url) == "about:blank" {
                webLinkFollowed(false)
            } else {
                webLinkFollowed(true)
            }
            decisionHandler(.allow)
        case .notenikApp, .xcodeDev, .tempFile:
            webLinkFollowed(false)
            decisionHandler(.allow)
        case .wikiLink:
            var linkText = link.noteID
            if link.linkPart4 != nil {
                linkText = String(link.linkPart4!)
            }
            let resolution = NoteLinkResolution(io: collectionController?.notenikIO, linkText: linkText)
            NoteLinkResolver.resolve(resolution: resolution)
            if resolution.result == .resolved {
                webLinkFollowed(false)
                decisionHandler(.cancel)
                if !link.indexTermKey.isEmpty && link.indexedPageIndex >= 0 {
                    if let collection = io?.collection {
                        collection.lastIndexTermKey = link.indexTermKey
                        collection.lastIndexTermPageIx = link.indexedPageIndex
                        collection.lastIndexTermPageCount = link.indexedPageCount
                        collection.lastIndexedPageID = link.noteID
                    }
                }
                _ = NoteLinkResolverCocoa.link(wc: collectionController!, resolution: resolution)
            } else {
                webLinkFollowed(true)
                decisionHandler(.allow)
                return
            }
        default:
            collectionController!.launchLink(url: url)
            webLinkFollowed(false)
            decisionHandler(.cancel)
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utilities
    //
    // -----------------------------------------------------------
    
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "PresentViewController",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "PresentViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
    
}
