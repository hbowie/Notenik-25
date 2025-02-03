//
//  NoteLinkResolverCocoa.swift
//  Notenik
//
//  Created by Herb Bowie on 9/7/22.
//
//  Copyright © 2022 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class NoteLinkResolverCocoa {
    
    static func link(wc: CollectionWindowController?, resolution: NoteLinkResolution) -> CollectionWindowController? {

        if resolution.resolvedPath.isEmpty && wc != nil {
            _ = wc!.viewCoordinator.focusOn(initViewID: "note-link-resolver",
                                            note: resolution.resolvedNote,
                                            position: nil, row: -1, searchPhrase: nil)
            return wc
        } else {
            let folders = NotenikFolderList.shared
            let juggler = CollectionJuggler.shared
            let multi   = MultiFileIO.shared
            let shortcut = resolution.resolvedPath
            var link: NotenikLink?
            let multiEntry = multi.getEntry(shortcut: shortcut)
            if multiEntry == nil {
                link = folders.getFolderFor(shortcut: shortcut)
            } else {
                link = multiEntry!.link
            }
            guard let collectionLink = link else {
                // print("  - collection link is nil")
                return nil
            }
            guard let controller = juggler.open(link: collectionLink) else {
                // print("  - could not get a window controller from the juggler")
                return nil
            }
            _ = controller.viewCoordinator.focusOn(initViewID: "note-link-resolver",
                                            note: resolution.resolvedNote,
                                            position: nil, row: -1, searchPhrase: nil)
            return controller
        }
    }
}
