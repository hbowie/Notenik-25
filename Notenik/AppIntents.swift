//
//  AppIntents.swift
//  Notenik
//
//  Created by Herb Bowie on 11/7/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import AppIntents

import NotenikLib

struct GetNoteTitle: AppIntent {
    static let intentClassName = "GetNoteTitleIntent"
    static let title: LocalizedStringResource = "Get Note Title"
    static let description = IntentDescription("Retrieve the Title of the currently selected Note")
    @available(anyAppleOS 26.0, *)
    static let supportedModes: IntentModes = .foreground

    static var parameterSummary: some ParameterSummary {
        Summary("Retrieve the Title of the currently selected Note")
    }

    func perform() async throws -> some IntentResult {
        let title = CollectionJuggler.shared.getLastSelectedNoteTitle()
        return .result(value: title,
                       dialog: IntentDialog("The note title is \(title)") )
    }
}

struct GetNoteSharingLink: AppIntent {
    static let intentClassName = "GetNoteSharingLinkIntent"
    static var title: LocalizedStringResource = "Get Note Sharing Link"
    static var description = IntentDescription("Return the Custom URL pointing to the current Note")
    @available(anyAppleOS 26.0, *)
    static let supportedModes: IntentModes = .foreground

    static var parameterSummary: some ParameterSummary {
        Summary("Return the Notenik Custom URL pointing to the currently selected Note")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<URL> {
        let urlStr = CollectionJuggler.shared.getLastSelectedNoteCustomURL()
        let url = URL(string: urlStr)
        return .result(value: url!,
                       dialog: IntentDialog("The Notenik Custom URL for the currently selected note is \(urlStr)"))
    }
}

struct GetNoteFilePath: AppIntent {
    static let intentClassName = "GetNoteFilePathIntent"
    static var title: LocalizedStringResource = "Get Note File Path"
    static var description = IntentDescription("Return the file path to the currently selected Note")
    @available(anyAppleOS 26.0, *)
    static let supportedModes: IntentModes = .foreground
    
    static var parameterSummary: some ParameterSummary {
        Summary("Return the file path to the currently selected Note")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let path = CollectionJuggler.shared.getLastSelectedNoteFilePath()
        return .result(value: path, dialog: IntentDialog("The Notenik file path for the currently selected Note is \(path)"))
    }
}

struct AddNoteFromText: AppIntent {
    static let intentClassName = "AddNoteFromTextIntent"
    static var title: LocalizedStringResource = "Add Note From Text"
    static var description = IntentDescription("Add a new Note given Note Text")
    @available(anyAppleOS 26.0, *)
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Note Text")
    var noteText: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add a Note from a Block of Text") {
            \.$noteText
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {

        var errMsg = ""
        var collWC: CollectionWindowController?
        var collection: NoteCollection?
        var addedNote: Note?
        
        if let cwc = CollectionJuggler.shared.getLastUsedWindowController() {
            collWC = cwc
        } else {
            errMsg = "Could not get current Collection"
        }
        
        if errMsg.isEmpty {
            if let coll = collWC?.notenikIO?.collection {
                collection = coll
            } else {
                errMsg = "Could not get current Collection"
            }
        }
        
        if errMsg.isEmpty {
            if noteText != nil && !noteText!.isEmpty {
                errMsg = ""
            } else {
                errMsg = "Input Note Text Missing"
            }
        }
        
        if errMsg.isEmpty {
            let newNote = Note(collection: collection!)
            _ = collWC!.strToNote(str: noteText!, note: newNote, defaultTitle: nil)
            if let added = collWC!.addPastedNote(newNote) {
                addedNote = added
            } else {
                errMsg = "Add of new Note was unsuccessful"
            }
        }
        
        var value = ""
        var dialogStr = ""
        if errMsg.isEmpty {
            value = addedNote!.getNotenikLink()
            dialogStr = "Note added successfully at link \(value)"
        } else {
            value = errMsg
            dialogStr = errMsg
        }
        let dialog = IntentDialog(stringLiteral: dialogStr)
        return .result(value: value,
                       dialog: dialog)
    }
}

struct RunScript: AppIntent {
    static let intentClassName = "RunScriptIntent"
    static var title: LocalizedStringResource = "Run Script"
    static var description = IntentDescription("Run the Specified Notenik Script File")

    @Parameter(title: "Script File Path")
    var scriptFilePath: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Runs the Specified Notenik Script File") {
            \.$scriptFilePath
        }
    }

    func perform() async throws -> some IntentResult {
        
        var msg = "Script Execution Complete"
        if scriptFilePath != nil && !scriptFilePath!.isEmpty {
            let player = ScriptPlayer()
            player.playScript(fileName: scriptFilePath!)
        } else {
            msg = "No usable script file path provided"
        }

        return .result(value: msg)
    }
}

struct OpenQuickAction: AppIntent {
    static let intentClassName = "OpenQuickActionIntent"
    static var title: LocalizedStringResource = "Open Quick Action Window"
    static var description = IntentDescription("Open Notenik's Quick Action Window")

    static var parameterSummary: some ParameterSummary {
        Summary("Open Notenik's Quick Action Window")
    }

    func perform() async throws -> some IntentResult {
        CollectionJuggler.shared.quickAction()
        return .result()
    }
}

struct NotenikShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetNoteTitle(),
            phrases: [
                "What's the note title in \(.applicationName)?",
                "How is the \(.applicationName) note titled?",
                "Get the note title from \(.applicationName)",
                "Get \(.applicationName) Item Title"
            ],
            shortTitle: "Get Note Title",
            systemImageName: "inset.filled.topthird.rectangle"
        )
        AppShortcut(
            intent: GetNoteSharingLink(),
            phrases: [
                "What's the current \(.applicationName) custom URL?",
            ],
            shortTitle: "Get Custom URL",
            systemImageName: "link"
        )
        AppShortcut(
            intent: GetNoteFilePath(),
            phrases: [
                "What's the current \(.applicationName) file path?",
            ],
            shortTitle: "Get file path",
            systemImageName: "document"
        )
        AppShortcut(
            intent: AddNoteFromText(),
            phrases: [
                "Add a Note to \(.applicationName)",
            ],
            shortTitle: "Add Note from Text",
            systemImageName: "text.document"
        )
        AppShortcut(
            intent: RunScript(),
            phrases: [
                "Run a \(.applicationName) script",
            ],
            shortTitle: "Run a Script",
            systemImageName: "book.pages"
        )
        AppShortcut(
            intent: OpenQuickAction(),
            phrases: [
                "Open \(.applicationName) Quick Action window",
            ],
            shortTitle: "Quick Action",
            systemImageName: "book.pages"
        )
    }
    
}


