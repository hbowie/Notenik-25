//
//  SeqOutlineViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 8/6/24.
//  Copyright © 2024 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import UniformTypeIdentifiers

import NotenikLib
import NotenikUtils

/// This is the view controller for the optional Outline tab.
class SeqOutlineViewController: NSViewController,
                                NSOutlineViewDataSource,
                                NSOutlineViewDelegate,
                                CollectionView {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet var outlineView: NSOutlineView!
    
    var collectionWindowController: CollectionWindowController?
    
    var notenikIO: NotenikIO?
    
    var outlneTabSetting: OutlineTabSetting = .withSeq
    
    var focusNote: SortedNote?
    
    var shortcutMenu: NSMenu!
    
    var newChildIndex = -1
    var newWithOptionsIndex = -1
    var seqModIndex = -1
    
    /// Get or Set the Window Controller
    var window: CollectionWindowController? {
        get {
            return collectionWindowController
        }
        set {
            collectionWindowController = newValue
        }
    }
    
    /// Getter and setter for the Notenik I/O module.
    var io: NotenikIO? {
        get {
            return notenikIO
        }
        set {
            notenikIO = newValue
            guard notenikIO != nil && notenikIO!.collection != nil else {
                return
            }
            if shortcutMenu != nil {
                modShortcutMenuForCollection()
            }
            if outlineView != nil {
                outlineView.reloadData()
            }
        }
    }
    
    /// Now that we have a view, let's make some adjustments.
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustFonts()
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.stronglyReferencesItems = false
        
        // Setup for drag and drop.
        outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(UTType.bookmark.identifier),
                                             NSPasteboard.PasteboardType(UTType.url.identifier),
                                             NSPasteboard.PasteboardType(UTType.vCard.identifier),
                                             NSPasteboard.PasteboardType.string])
        
        if focusNote != nil {
            focusOnNote()
        }
        
        // Setup the popup menu for rows in the list.
        shortcutMenu = NSMenu()
        addToShortcutMenu(actionType: .showInFinder)
        addToShortcutMenu(actionType: .launchLink)
        addToShortcutMenu(actionType: .share)
        addToShortcutMenu(actionType: .copyNotenikURL)
        addToShortcutMenu(actionType: .copyTitle)
        addToShortcutMenu(actionType: .copyTimestamp)
        addToShortcutMenu(actionType: .bulkEdit)
 
        shortcutMenu.addItem(NSMenuItem.separator())
        
        addToShortcutMenu(actionType: .duplicate)
        addToShortcutMenu(actionType: .deleteRange)
        addToShortcutMenu(actionType: .continuousDisplay)
        
        outlineView.menu = shortcutMenu
        
        if notenikIO != nil {
            modShortcutMenuForCollection()
        }
    }
    
    /// Retain knowledge of user's requested setting for the Seq Outline.
    func setSeqOption(outlineTabSetting: OutlineTabSetting) {
        self.outlneTabSetting = outlineTabSetting
    }
    
    /// Reload the fornts and the data.
    func reload() {
        adjustFonts()
        outlineView.reloadData()
    }
    
    var monoDigitFont: NSFont?
    var userFont: NSFont?
    var userFontName = ""
    var fontToUse: NSFont?
    
    /// Adjust fonts and appearance.
    func adjustFonts() {

        monoDigitFont = NSFont.monospacedDigitSystemFont(ofSize: 13.0,
                                                         weight: NSFont.Weight.regular)
        fontToUse = monoDigitFont
        userFont = nil
        var rowHeight: CGFloat = 17.0
        if let userFontName = defaults.string(forKey: NotenikConstants.listDisplayFont) {
            if !userFontName.isEmpty && !userFontName.lowercased().contains("system font") {
                if let userFontSize = defaults.string(forKey: NotenikConstants.listDisplaySize) {
                    if let doubleValue = Double(userFontSize) {
                        let cgFloat = CGFloat(doubleValue)
                        rowHeight = cgFloat * 1.3
                        userFont = NSFont(name: userFontName, size: cgFloat)
                        fontToUse = userFont
                    }
                }
            }
        }
        if userFont == nil {
            outlineView.rowHeight = CGFloat(17.0)
            outlineView.rowSizeStyle = .custom
        } else {
            outlineView.rowHeight = rowHeight
            outlineView.rowSizeStyle = .custom
        }
    }
    
    /// Make modification sto the shortcut menu that are dependent on the nature of the collection.
    func modShortcutMenuForCollection() {
        
        if newWithOptionsIndex >= 0 {
            if shortcutMenu.numberOfItems > newWithOptionsIndex {
                shortcutMenu.removeItem(at: newWithOptionsIndex)
            }
            newWithOptionsIndex = -1
        }
        
        if newChildIndex >= 0 {
            if shortcutMenu.numberOfItems > newChildIndex {
                shortcutMenu.removeItem(at: newChildIndex)
            }
            newChildIndex = -1
        }
        
        if seqModIndex >= 0 {
            if shortcutMenu.numberOfItems > seqModIndex {
                shortcutMenu.removeItem(at: seqModIndex)
            }
            seqModIndex = -1
        }
        
        guard let collection = notenikIO?.collection else { return }
        
        if collection.seqFieldDef != nil
            && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) {
            seqModIndex = shortcutMenu.numberOfItems
            addToShortcutMenu(actionType: .modifySeqRange)
        }
        
        if collection.seqFieldDef != nil && collection.levelFieldDef != nil {
            newChildIndex = shortcutMenu.numberOfItems
            addToShortcutMenu(actionType: .newChild)
        }
        
        if (collection.klassFieldDef != nil
               && collection.klassDefs.count > 0)
                || collection.levelFieldDef != nil
                || collection.seqFieldDef != nil {
            newWithOptionsIndex = shortcutMenu.numberOfItems
            addToShortcutMenu(actionType: .newWithOptions)
        }
    }
    
    /// Add an item to the shortcuts menu.
    func addToShortcutMenu(actionType: NoteActionType) {
        let item = NSMenuItem(title: actionType.rawValue,
                              action: #selector(takeShortcutAction(_:)),
                              keyEquivalent: "")
        shortcutMenu.addItem(item)
    }
    
    /// Expand all the nodes in the outline so that all rows are visible.
    func expandOutline() {
        var i = -1
        while (i + 1) < outlineView.numberOfRows {
            i += 1
            guard let item = outlineView.item(atRow: i) else { continue }
            guard let node = item as? OutlineNode2 else { continue }
            guard node.children.count > 0 else { continue }
            guard node.type == .note else { continue }
            if !outlineView.isItemExpanded(item) {
                outlineView.expandItem(item, expandChildren: true)
            }
        }
    }
    
    /// Collapse the outline show that only the uppermost nodes are visible.
    func collapseOutline() {
        var i = -1
        while (i + 1) < outlineView.numberOfRows {
            i += 1
            guard let item = outlineView.item(atRow: i) else { continue }
            guard let node = item as? OutlineNode2 else { continue }
            guard node.children.count > 0 else { continue }
            guard node.type == .note else { continue }
            guard let sortedNote = node.sortedNote else { continue }
            if sortedNote.seqSingleValue.isEmpty { continue }
            if outlineView.isItemExpanded(item) {
                outlineView.collapseItem(item, collapseChildren: true)
            }
        }
    }
    
    /// Take whatever action the user has requested from the shortcuts menu.
    @IBAction func takeShortcutAction(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let actionType = NoteActionType(rawValue: menuItem.title) else { return }
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        guard let wc = collectionWindowController else { return }
        let row = outlineView.clickedRow
        guard row >= 0 else { return }
        guard let node = outlineView.item(atRow: row) as? OutlineNode2 else { return }
        guard node.type == .note else { return }
        let clickedNote = node.sortedNote!
        notesAction(actionType: actionType, io: io, collection: collection, clickedNote: clickedNote, wc: wc)
    }
    
    /// Once prereqs are satisfied, take the requested action.
    public func notesAction(actionType: NoteActionType, io: NotenikIO, collection: NoteCollection, clickedNote: SortedNote?, wc: CollectionWindowController) {
        guard outlineView.numberOfSelectedRows > 0 else { return }
        var selSortedNotes: [SortedNote] = []
        var selNotes: [Note] = []
        var primaryNote: SortedNote? = clickedNote
        for index in outlineView.selectedRowIndexes {
            guard let node = outlineView.item(atRow: index) as? OutlineNode2 else { continue }
            guard node.type == .note else { continue }
            selSortedNotes.append(node.sortedNote!)
            selNotes.append(node.sortedNote!.note)
        }
        if primaryNote == nil {
            primaryNote = selSortedNotes.first
        }
        switch actionType {
        case .showInFinder:
            let folderPath = io.collection!.lib.getPath(type: .collection)
            let filePath = primaryNote!.noteID.getFullPath(note: primaryNote!.note)
            NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: folderPath)
        case .launchLink:
            wc.launchLink(for: primaryNote!.note)
        case .share:
            wc.shareNote(notes: selNotes)
        case .copyNotenikURL:
            let str = primaryNote!.note.getNotenikLink(preferringTimestamp: false)
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .copyTitle:
            let str = primaryNote!.noteID.getBasis()
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .copyTimestamp:
            var str = "No timestamp available!"
            if collection.hasTimestamp {
                str = primaryNote!.note.timestampAsString
            }
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .bulkEdit:
            wc.bulkEdit(notes: selNotes)
        case .newWithOptions:
            wc.newWithOptions(currentNote: primaryNote!.note)
        case .duplicate:
            wc.duplicateNote(startingNote: primaryNote!.note)
        case .deleteRange:
            let (lo, hi) = getRangeOfSelectedNotes(io: io)
            guard lo >= 0 && hi >= lo else { return }
            wc.deleteRangeOfNotes(startingRow: lo, endingRow: hi)
        case .newChild:
            wc.newChild(parent: primaryNote!.note)
        case .modifySeqRange:
            guard collection.seqFieldDef != nil
                    && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) else {
                return
            }
            let (lo, hi) = getRangeOfSelectedNotes(io: io)
            guard lo >= 0 && hi >= lo else { return }
            wc.seqModify(startingRow: lo, endingRow: hi)
        case .continuousDisplay:
            collection.setPartialDisplay()
            collection.displayedNotes = SelectedNotes(io:io)
            for index in outlineView.selectedRowIndexes {
                guard let node = outlineView.item(atRow: index) as? OutlineNode2 else { continue }
                guard node.type == .note else { continue }
                collection.displayedNotes.append(node.sortedNote!)
            }
            wc.reloadDisplayView(self)
        }
    }
    
    /// Get a contiguous range of selected notes. 
    func getRangeOfSelectedNotes(io: NotenikIO, withClick: Bool = true) -> (Int, Int) {
        
        guard outlineView.numberOfSelectedRows > 0 else { return (-1, -2) }

        // Get the full range of selected notes.
        let (lowIndex, highIndex) = getRangeOfSelectedRows()
        guard lowIndex >= 0 else { return (-1, -2) }
        // Make sure the user clicked somewhere within this range.
        if withClick && (outlineView.clickedRow > highIndex || outlineView.clickedRow < lowIndex) {
            return (-1, -2)
        }
        
        guard let node1 = outlineView.item(atRow: lowIndex) as? OutlineNode2 else { return  (-1, -2) }
        guard node1.type == .note else { return  (-1, -2) }
        let lowNote = node1.sortedNote!
        let lowPosition = io.positionOfNote(lowNote)
        let lo = lowPosition.index
        
        guard let node2 = outlineView.item(atRow: highIndex) as? OutlineNode2 else { return (-1, -2) }
        guard node2.type == .note else { return (-1, -2) }
        let highNote = node2.sortedNote!
        let highPosition = io.positionOfNote(highNote)
        let hi = highPosition.index
        
        return (lo, hi)
    }
    
    /// Get a possible range of selected rows from the table view.
    /// - Returns: The first (lowest) row selected, and the highest row selected,
    /// or a pair of negative values is no valid selection.
    func getRangeOfSelectedRows() -> (Int, Int) {

        let selectedRow = outlineView.selectedRow
        if selectedRow < 0 { return (-1, -1) }
        
        var lowIndex = selectedRow
        var highIndex = selectedRow
        
        var rowToTest = selectedRow - 1
        var stillSelected = true
        while rowToTest >= 0 && stillSelected {
            if outlineView.isRowSelected(rowToTest) {
                lowIndex = rowToTest
                rowToTest -= 1
            } else {
                stillSelected = false
            }
        }
        
        rowToTest = outlineView.selectedRow + 1
        stillSelected = true
        while rowToTest < outlineView.numberOfRows && stillSelected {
            if outlineView.isRowSelected(rowToTest) {
                highIndex = rowToTest
                rowToTest += 1
            } else {
                stillSelected = false
            }
        }
        
        return (lowIndex, highIndex)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement NSOutlineViewDataSource
    //
    // -----------------------------------------------------------
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? OutlineNode2 {
            return node.children.count
        }
        guard notenikIO != nil else { return 0 }
        guard notenikIO!.getOutlineNodeRoot() != nil else { return 0 }
        return notenikIO!.getOutlineNodeRoot()!.children.count
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? OutlineNode2 {
            return node.children[index]
        }
        return notenikIO!.getOutlineNodeRoot()!.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? OutlineNode2 {
            return node.children.count > 0
        }
        return notenikIO!.getOutlineNodeRoot()!.children.count > 0
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement Drag and Drop logic.
    //
    // -----------------------------------------------------------
    
    /// Write a selected item to the pasteboard.
    func outlineView(_ outlineView: NSOutlineView,
                     pasteboardWriterForItem item: Any)
                        -> NSPasteboardWriting? {
        if let node = item as? OutlineNode2 {
            if let selectedNote = node.sortedNote {
                let maker = NoteLineMaker()
                let _ = maker.putNote(selectedNote.note, includeAttachments: true)
                var str = ""
                if let writer = maker.writer as? BigStringWriter {
                    str = writer.bigString
                }
                return str as NSString
            }
        }
        return nil
    }
    
    /// Validate a proposed drop operation.
    func outlineView(_ outlineView: NSOutlineView,
                     validateDrop info: NSDraggingInfo,
                     proposedItem item: Any?,
                     proposedChildIndex index: Int)
                    -> NSDragOperation {
        return .copy
    }
    
    /// Process one or more dropped items.
    func outlineView(_ outlineView: NSOutlineView,
                     acceptDrop info: NSDraggingInfo,
                     item: Any?,
                     childIndex index: Int) -> Bool {
        
        guard let wc = collectionWindowController else { return false }
        guard let io = notenikIO else { return false }
        guard let parentNode = item as? OutlineNode2 else { return false }
        guard let parentNote = parentNode.sortedNote else { return false }
        
        var noteAbove: SortedNote?
        if parentNode.children.count == 0 || index == 0 {
            noteAbove = parentNote
        } else if index < 0 || index >= parentNode.children.count {
            noteAbove = parentNode.children[parentNode.children.count - 1].sortedNote
        } else {
            noteAbove = parentNode.children[index - 1].sortedNote
        }
        guard noteAbove != nil else { return false }
        let abovePosition = io.positionOfNote(noteAbove!.note)
        guard abovePosition.valid else { return false }
        let row = abovePosition.index + 1
        
        let pasteboard = info.draggingPasteboard
        
        let items = pasteboard.pasteboardItems
                        
        var notesPasted = 0
        
        if items != nil && items!.count > 0 {
            notesPasted = wc.pasteItems(items!,
                                        row: row,
                                        dropOperation: .above)
        }
        
        guard notesPasted == 0 else { return true }
        
        let filePromises = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil)
        if filePromises != nil {
            collectionWindowController!.pastePromises(filePromises!)
            return true
        }
        
        return true
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement NSOutlineViewDelegate
    //
    // -----------------------------------------------------------
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var cellView: NSTableCellView?
        
        if let node = item as? OutlineNode2 {
            let cellID = NSUserInterfaceItemIdentifier("seqTableCell")
            cellView = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = cellView?.textField {
                if fontToUse != nil {
                    textField.font = fontToUse!
                }
                switch node.type {
                case .root:
                    textField.stringValue = notenikIO!.collection!.path
                case .note:
                    if let sortedNote = node.sortedNote {
                        if outlneTabSetting == .withSeq {
                            if sortedNote.note.collection.seqFormatter.isEmpty {
                                textField.stringValue = sortedNote.getTitle(withSeq: true, formattedSeq: false, sep: " - ")
                            } else {
                                textField.stringValue = sortedNote.getTitle(withSeq: true, formattedSeq: true, sep: " ")
                            }
                        } else {
                            textField.stringValue = sortedNote.getTitle(withSeq: false, sep: "")
                        }
                    } else {
                        textField.stringValue = "???"
                    }
                }
                textField.sizeToFit()
            }
        }
        return cellView
    }
    
    /// Show the user the details for the row s/he selected
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        guard let outlineView = notification.object as? NSOutlineView else { return }
        guard let io = notenikIO else { return }
        guard collectionWindowController != nil else { return }
        let selectedIndex = outlineView.selectedRow
        guard let node = outlineView.item(atRow: selectedIndex) as? OutlineNode2 else { return }
        switch node.type {
        case .note:
            let notePosition = io.positionOfNote(node.sortedNote!)
            if notePosition.valid {
                _ = io.selectNote(at: notePosition.index)
            }
            focusNote = node.sortedNote!
            _ = coordinator!.focusOn(initViewID: viewID,
                                     sortedNote: node.sortedNote,
                                     position: nil,
                                     row: -1,
                                     searchPhrase: nil)
        case .root:
            break
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        
        guard collectionWindowController != nil else { return }
        
        let item = sender.item(atRow: sender.clickedRow)
        guard let node = item as? OutlineNode2 else { return }
        
        if node.type == .note {
            let clickedNote = node.sortedNote
            if clickedNote != nil {
                collectionWindowController!.launchLink(for: clickedNote!.note)
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement CollectionView
    //
    // -----------------------------------------------------------
    
    public static let staticViewID = "seq-outline"
    var viewID = staticViewID
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    /// Select the specified Note, by specifying either the Note itself or its position in the list.
    /// - Parameters:
    ///   - note: The note to be selected.
    ///   - position: The position of the selection.
    ///   - searchPhrase: Any search phrase currently in effect.
    func focusOn(initViewID: String,
                 sortedNote: SortedNote?,
                 position: NotePosition?,
                 io: NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        
        guard viewID != initViewID || withUpdates else { return }
        guard sortedNote != nil else { return }
        focusNote = sortedNote
        guard outlineView != nil else {
            return
        }
        if withUpdates {
            reload()
        }
        focusOnNote()
    }
    
    func focusOnNote() {
        guard notenikIO != nil else {
            return
        }
        let iterator = notenikIO!.makeOutlineNodeIterator()
        var nextNode = iterator.next()
        var found = false
        while nextNode != nil && !found {
            if nextNode!.type == .note {
                if nextNode!.sortedNote!.note.id == focusNote!.note.id {
                    found = true
                }
            }
            if !found {
                nextNode = iterator.next()
            }
        }
        if found {
            
            // Expand parents so child will be visible
            var parentStack: [OutlineNode2] = []
            var stackComplete = false
            var childNode: OutlineNode2 = nextNode!
            while !stackComplete {
                if childNode.hasParent {
                    parentStack.insert(childNode.parent!, at: 0)
                    childNode = parentStack[0]
                } else {
                    stackComplete = true
                }
            }
            for parent in parentStack {
                outlineView.expandItem(parent)
            }
            
            // Select the row containing the note.
            let row = outlineView.row(forItem: nextNode)
            if row >= 0 {
                let iSet = IndexSet(integer: row)
                outlineView.selectRowIndexes(iSet, byExtendingSelection: false)
            }
        } else {
            print("  - Note ID of \(focusNote!.note.id) could not be found")
        }
        return
    }
    
}
