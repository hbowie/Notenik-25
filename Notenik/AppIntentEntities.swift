//
//  AppIntentEntities.swift
//  Notenik
//
//  Created by Herb Bowie on 11/11/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

@preconcurrency import AppIntents

import NotenikLib

@available(macOS 27, *)
struct TextNoteEntity: AppEntity {
    
    static var defaultQuery: TextNoteQuery = TextNoteQuery()
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Text Note",
                                                                     numericFormat: "2 Text Notes",
                                                                     synonyms: ["Notenik Note",
                                                                               "Markdown Note",
                                                                               "Plain Text Note",
                                                                               "Note"])
    
    var id: String = ""
    
    @Property(title: "Title") var title: String 
    
    /**
    Information on how to display the entity to people — for example, a string like the trail name. Include the optional subtitle
    and image for a visually rich display.
    */
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    init(note: Note) {
        title = note.title.value
        id = note.noteID.id
    }
    
    struct TextNoteQuery: EntityQuery {
        
        func entities(for: [String]) async throws -> [TextNoteEntity] {
            return []
        }
    }
    
}
