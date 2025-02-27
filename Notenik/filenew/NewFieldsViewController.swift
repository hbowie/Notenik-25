//
//  NewFieldsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/8/21.
//
//  Copyright © 2021 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

/// Third tab: let the user select a type of collection.
class NewFieldsViewController: NSViewController {
    
    let modelsPath = "/models"
    var fullPath = ""
    
    var starterPacks: StarterPackMgr?
    
    var tabsVC: NewCollectionViewController?

    @IBOutlet var listOfModels: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        starterPacks = StarterPackMgr()
        fullPath = Bundle.main.resourcePath! + modelsPath
        let resourceURL = Bundle.main.resourceURL
        let modelsURL = resourceURL!.appendingPathComponent(modelsPath)
        starterPacks!.load(fromFolder: modelsURL)
        if NotenikFolderList.shared.starterPacksUserFolder != nil {
            starterPacks!.load(fromFolder: NotenikFolderList.shared.starterPacksUserFolder!)
        }
        listOfModels.removeAllItems()
        for pack in starterPacks!.starterPacks {
            listOfModels.addItem(withTitle: pack.description)
            let menuItem = listOfModels.item(withTitle: pack.description)
            if menuItem != nil {
                menuItem!.toolTip = pack.teaser
            }
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.selectTab(index: 1)
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        
        let selectedItem = listOfModels.selectedItem
        guard selectedItem != nil else {
            tabsVC!.communicateError("You must first make a selection from the list of Collection types", alert: true)
            return
        }
        let selection = selectedItem!.title
        if let selPack = starterPacks!.get(description: selection) {
            tabsVC!.setFields(starterPack: selPack)
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
    
}
