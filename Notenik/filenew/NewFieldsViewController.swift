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
    
    var packToUse: StarterPack?
    
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
    
    @IBAction func initFromClone(_ sender: Any) {
        
        packToUse = nil
        let openPanel = NSOpenPanel();
        openPanel.title = "Identify Clone to Use"
        openPanel.prompt = "Choose Starter Clone"
        openPanel.message = "Identify Starter Clone"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let result = openPanel.runModal()
        guard result == .OK else { return }
        guard let source = openPanel.url else { return }
        packToUse = StarterPack(location: source)
        packToUse!.loadInfo()
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        
        if packToUse == nil {
            let selectedItem = listOfModels.selectedItem
            guard selectedItem != nil else {
                tabsVC!.communicateError("You must first make a selection from the list of Collection types", alert: true)
                return
            }
            let selection = selectedItem!.title
            if let selPack = starterPacks!.get(description: selection) {
                packToUse = selPack
            }
            if packToUse != nil {
                tabsVC!.setFields(starterPack: packToUse!)
            }
        } else {
            tabsVC!.setFields(starterPack: packToUse!)
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
    
}
