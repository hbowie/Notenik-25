//
//  SeqModViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/20/21.
//
//  Copyright © 2021 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class SeqModViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var collectionWC: CollectionWindowController?
    var window: SeqModWindowController?
    
    var io: NotenikIO?
    var collection: NoteCollection?
    var startingRow: Int = 0
    var endingRow: Int = 0
    var startingNote: SortedNote?
    
    @IBOutlet var rangeToRenumber: NSTextField!
    @IBOutlet var newStartingSeq: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var noteIO: NotenikIO? {
        get {
            return io
        }
        set {
            io = newValue
            collection = io?.collection
        }
    }
    
    func setRange(startingRow: Int, endingRow: Int) {
        self.startingRow = startingRow
        self.endingRow = endingRow
        startingNote = io!.getSortedNote(at: startingRow)
        let endingNote = io!.getSortedNote(at: endingRow)
        rangeToRenumber.stringValue = "\(startingNote!.seqSingleValue.value) -> \(endingNote!.seqSingleValue.value)"
        newStartingSeq.stringValue = startingNote!.seqSingleValue.value
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        window!.close()
    }
    
    @IBAction func ok(_ sender: Any) {

        if startingNote != nil {
            if let sequencer = Sequencer(io: io!) {
                let newSeqValue = startingNote!.note.seq.dupe()
                _ = newSeqValue.setSingleSeq(newStartingSeq.stringValue, seqIndex: startingNote!.seqIndex)
                let modStartingNote = sequencer.renumberRange(startingRow: startingRow, endingRow: endingRow, newSeqValue: newSeqValue.value)
                collectionWC!.seqModified(modStartingNote: modStartingNote, rowCount: 1)
            }
            application.stopModal(withCode: .OK)
            window!.close()
        }
    }
    
}
