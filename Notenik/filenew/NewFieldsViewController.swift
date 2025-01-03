//
//  NewFieldsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/8/21.
//
//  Copyright © 2021 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

/// Third tab: let the user select a type of collection.
class NewFieldsViewController: NSViewController {
    
    let modelsPath = "/models"
    var fullPath = ""
    
    var tabsVC: NewCollectionViewController?

    @IBOutlet var listOfModels: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listOfModels.removeAllItems()
        fullPath = Bundle.main.resourcePath! + modelsPath
        do {
            var models = try FileManager.default.contentsOfDirectory(atPath: fullPath)
            models.sort()
            for model in models {
                listOfModels.addItem(withTitle: model)
                let menuItem = listOfModels.item(withTitle: model)
                if menuItem != nil {
                    switch model {
                    case "01 - Basic Notes":
                        menuItem!.toolTip = "Each Note will have a Title, Tags & Body"
                    case "02 - Notenik Intro":
                        menuItem!.toolTip = "A Brief Introduction to Notenik"
                    case "03 - Web Links":
                        menuItem!.toolTip = "Each Note will have a Link field, as well as Title, Tags & Body"
                    case "04 - To Do":
                        menuItem!.toolTip = "Each Note will represent a task, with a Date, a Status, and optional Recurs rule, in addition to the more common fields."
                    case "05 - Sequenced List":
                        menuItem!.toolTip = "Each Note gets a sequence number, and you can sort the entire list by those numbers."
                    case "06 - Zettelkasten":
                        menuItem!.toolTip = "Zettelkasten is a fancy term for a collection of thoughts that can link to one another."
                    case "07 - Blog":
                        menuItem!.toolTip = "Each Note becomes a Blog Post"
                    case "08 - Commonplace book":
                        menuItem!.toolTip = "Each Note contains a notable quotation"
                    case "09 - Outline":
                        menuItem!.toolTip = "Each Note has a Seq field and a Level field"
                    case "10 - Web Book":
                        menuItem!.toolTip = "Your entire Collection can be published as a Web Book"
                    case "11 - Commonplace with Lookups":
                        menuItem!.toolTip = "Lookup authors and their works in nested Collection folders"
                    case "12 - Website":
                        menuItem!.toolTip = "A Prototype for a Website generated by Notenik"
                    case "13 - Contacts":
                        menuItem!.toolTip = "Contact Info for People"
                    case "14 - Travel Planner":
                        menuItem!.toolTip = "Record Your Plans for a Trip"
                    case "15 - Code Snippets":
                        menuItem!.toolTip = "Code Snippets for use with Notenik"
                    case "16 - HTML for People demo":
                        menuItem!.toolTip = "Web Building Tutorial"
                    default:
                        break
                    }
                }
            }
        } catch {
            tabsVC!.communicateError("Could not read the contents of the models directory", alert: true)
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
        let modelPath = FileUtils.joinPaths(path1: fullPath, path2: selection)
        let modelURL = URL(fileURLWithPath: modelPath)
        
        tabsVC!.setFields(selection, modelURL: modelURL)
        
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
    
}
