//
//  InstructionsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 10/2/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
@preconcurrency import WebKit

import NotenikLib
import NotenikUtils

class InstructionsViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    let format: MarkedupFormat = .htmlDoc
    let displayPrefs = DisplayPrefs.shared
    let docTitle = "Edit Instructions"
    
    var collectionController: CollectionWindowController?
    var wc: InstructionsWindowController?

    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        // loadHTML()
    }
    
    /// Load the HTML to be displayed in the web view.
    func loadHTML(instr: String) {
        let code = Markedup(format: format)
        var css = displayPrefs.displayCSS()!
        if let bodySizeStr = displayPrefs.bodySpecs.size {
            if let bodySize = Int(bodySizeStr) {
                css.append("\nh1 { font-weight: 600; font-size: \(bodySize+4)pt }")
                css.append("\nh2 { font-weight: 600; font-size: \(bodySize+2)pt }")
                css.append("\nh3 { font-weight: 600; font-size: \(bodySize+2)pt }")
                css.append("\nh4 { font-weight: 600; font-size: \(bodySize)pt }")
            }
        }
        let headInfo = MarkedupHeadInfo(withTitle: docTitle, cssCode: css)
        code.startDoc(headInfo: headInfo)
        // code.heading(level: 1, text: docTitle)
        
        code.append(instr)
        
        code.finishDoc()
        let html = String(describing: code)
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
    
}
