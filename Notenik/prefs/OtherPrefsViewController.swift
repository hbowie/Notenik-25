//
//  OtherPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/7/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class OtherPrefsViewController: NSViewController, PrefsTabVC {
    
    let appPrefs = AppPrefs.shared

    @IBOutlet var mastodonHandleTextField: NSTextField!
    
    @IBOutlet var mastodonDomainTextField: NSTextField!
    
    @IBOutlet var horizListScrollBarField: NSPopUpButton!
    
    @IBOutlet var openInNovaButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch appPrefs.horizontalListScrollBar {
            case "on": horizListScrollBarField.selectItem(at: 0)
            case "off":  horizListScrollBarField.selectItem(at: 1)
            default: break;
        }
        
        switch appPrefs.openInNova {
        case false:
            openInNovaButton.selectItem(at: 1)
        case true:
            openInNovaButton.selectItem(at: 0)
        }
        
        mastodonHandleTextField.stringValue = appPrefs.mastodonHandle
        mastodonDomainTextField.stringValue = appPrefs.mastodonDomain
    }
    
    @IBAction func mastodonHandleEdited(_ sender: Any) {
        appPrefs.mastodonHandle = mastodonHandleTextField.stringValue
    }
    
    @IBAction func mastodonDomainEdited(_ sender: Any) {
        appPrefs.mastodonDomain = mastodonDomainTextField.stringValue
    }
    
    @IBAction func horizListScrollBarUpdated(_ sender: Any) {
        switch horizListScrollBarField.indexOfSelectedItem {
        case 0:
            appPrefs.horizontalListScrollBar = "on"
        case 1:
            appPrefs.horizontalListScrollBar = "off"
        default:
            break
        }
        CollectionJuggler.shared.adjustListViews()
    }
    
    @IBAction func openInNovaUpdated(_ sender: Any) {
        switch openInNovaButton.indexOfSelectedItem {
        case 0:
            appPrefs.openInNova = true
        case 1:
            appPrefs.openInNova = false
        default:
            appPrefs.openInNova = false
        }
    }
    
    /// Called when the user is leaving this tab for another one.
    func leavingTab() {

    }
    
    @IBAction func okClicked(_ sender: Any) {
        appPrefs.mastodonHandle = mastodonHandleTextField.stringValue
        appPrefs.mastodonDomain = mastodonDomainTextField.stringValue
        self.view.window!.close()
    }
}
