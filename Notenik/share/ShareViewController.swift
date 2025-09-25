//
//  ShareViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/15/19.
//  Copyright © 2019 - 2025 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib
import NotenikMkdown

class ShareViewController: NSViewController {
    
    // Get the User Defaults Singleton
    let defaults = UserDefaults.standard
    let contentKey = "share-content"
    let formatKey  = "share-format"
    let destinationKey = "share-destination"
    
    let bodyOnlyValue = "body-only"
    let entireNoteValue = "entire-note"
    let teaserOnlyValue = "teaser-only"
    let titleOnlyValue = "title-only"
    let wikilinkValue = "wikilink-only"
    
    let htmlDocValue = "html-doc"
    let htmlFragmentValue = "html-fragment"
    let htmlBlockquoteValue = "html-blockquote"
    let markkdownValue = "markdown"
    let markdownQuoteValue = "mdquote"
    let markdownQuoteFromValue = "mdquotefrom"
    let notenikValue = "notenik"
    let jsonValue = "json"
    let microValue = "micro"
    let templateValue = "template"
    
    let clipboardValue = "clipboard"
    let fileValue = "file"
    let browserValue = "browser"
    
    let noTemplatesMsg = "No Share Templates found"
    let noTemplateSelMsg = "No Share Template selected"
    
    var window: ShareWindowController?
    
    var notes: [Note] = []
    var searchPhrase: String?
    // var stringToShare = "No data available"

    @IBOutlet var contentBodyOnlyButton: NSButton!
    @IBOutlet var contentEntireNoteButton: NSButton!
    @IBOutlet var contentTeaserOnlyButton: NSButton!
    @IBOutlet var contentTitleButton: NSButton!
    @IBOutlet var contentWikilinkButton: NSButton!
    
    @IBOutlet var formatHTMLDocButton: NSButton!
    @IBOutlet var formatHTMLFragmentButton: NSButton!
    @IBOutlet var formatHTMLBlockquoteButton: NSButton!
    @IBOutlet var formatMarkdownButton: NSButton!
    @IBOutlet var formatMarkdownQuoteButton: NSButton!
    @IBOutlet var formatMarkdownQuoteFrom: NSButton!
    @IBOutlet var formatNotenikButton: NSButton!
    @IBOutlet var formatJSONButton: NSButton!
    @IBOutlet var formatMicroButton: NSButton!
    @IBOutlet var formatTemplateButton: NSButton!
    
    @IBOutlet var destinationClipboardButton: NSButton!
    @IBOutlet var destinationFileButton: NSButton!
    @IBOutlet var destinationBrowserButton: NSButton!
    
    @IBOutlet var templateNamePopupButton: NSPopUpButton!
    
    var io: NotenikIO? {
        get {
            return _nio
        }
        set {
            _nio = newValue
            setCollectionValues()
        }
    }
    var _nio: NotenikIO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Let's set the default values to the last ones used
        let contentSelector = defaults.string(forKey: contentKey)
        switch contentSelector {
        case bodyOnlyValue:
            contentBodyOnlyButton.state = .on
        case entireNoteValue:
            contentEntireNoteButton.state = .on
        case teaserOnlyValue:
            contentTeaserOnlyButton.state = .on
        case titleOnlyValue:
            contentTitleButton.state = .on
        case wikilinkValue:
            contentWikilinkButton.state = .on
        default:
            contentEntireNoteButton.state = .on
        }
        
        let formatSelector = defaults.string(forKey: formatKey)
        if formatSelector == htmlDocValue {
            formatHTMLDocButton.state = .on
        } else if formatSelector == htmlFragmentValue {
            formatHTMLFragmentButton.state = .on
        } else if formatSelector == htmlBlockquoteValue {
            formatHTMLBlockquoteButton.state = .on
        } else if formatSelector == markkdownValue {
            formatMarkdownButton.state = .on
        } else if formatSelector == markdownQuoteValue {
            formatMarkdownQuoteButton.state = .on
        } else if formatSelector == markdownQuoteFromValue {
            formatMarkdownQuoteFrom.state = .on
        } else if formatSelector == jsonValue {
            formatJSONButton.state = .on
        } else if formatSelector == microValue {
            formatMicroButton.state = .on
        } else if formatSelector == templateValue {
            formatTemplateButton.state = .on
        } else {
            formatNotenikButton.state = .on
        }
        
        let destinationSelector = defaults.string(forKey: destinationKey)
        if destinationSelector == clipboardValue {
            destinationClipboardButton.state = .on
        } else if destinationSelector == fileValue {
            destinationFileButton.state = .on
        } else {
            destinationBrowserButton.state = .on
        }
    }
    
    func setCollectionValues() {
        templateNamePopupButton.removeAllItems()
        guard let collection = io?.collection else {
            templateNamePopupButton.addItem(withTitle: noTemplatesMsg)
            return
        }
        if collection.shareTemplates.isEmpty {
            templateNamePopupButton.addItem(withTitle: noTemplatesMsg)
        } else {
            templateNamePopupButton.addItem(withTitle: noTemplateSelMsg)
            for template in collection.shareTemplates {
                templateNamePopupButton.addItem(withTitle: template)
            }
            if collection.selShareTemplate.isEmpty {
                templateNamePopupButton.selectItem(at: 0)
            } else {
                templateNamePopupButton.selectItem(withTitle: collection.selShareTemplate)
            }
        }
    } 

    
    func contentSelection() {
        if contentTitleButton.state == .on || contentWikilinkButton.state == .on {
            formatMarkdownButton.state = .on
            destinationClipboardButton.state = .on
        }
        templateNamePopupButton.selectItem(at: 0)
    }
    
    func formatSelection() {
        templateNamePopupButton.selectItem(at: 0)
    }
    
    func destinationSelection() {
        if destinationBrowserButton.state == .on {
            formatHTMLDocButton.state = .on
        }
    }
    
    /// User said OK -- Let's do the Sharing now
    @IBAction func okButtonPressed(_ sender: Any) {
        
        guard !notes.isEmpty else {
            communicateError("No note to share", alert: true)
            window!.close()
            return
        }
        
        guard window != nil else {
            communicateError("No window available")
            return
        }
        
        guard io != nil else {
            communicateError("No i/o module available")
            return
        }
        
        let displayParms = DisplayParms()
        displayParms.setFrom(note: notes[0])
        let mkdownOptions = displayParms.genMkdownOptions()
        
        // Set desired output format
        var format: MarkedupFormat = .htmlDoc
        if formatHTMLFragmentButton.state == .on
            || formatHTMLBlockquoteButton.state == .on {
            format = .htmlFragment
        } else if formatMarkdownButton.state == .on {
            format = .markdown
        }
        
        var concatString = ""
        
        let (done, str) = formatUsingTemplate(notes: notes)
        if done {
            concatString = str
        } else {
            for note in notes {
                mkdownOptions.shortID = note.shortID.value
                let shr = shareNote(note,
                                    format: format,
                                    mkdownOptions: mkdownOptions,
                                    displayParms: displayParms)
                if !concatString.isEmpty && !shr.isEmpty {
                    concatString.append("\n")
                }
                concatString.append(shr)
            }
        }
        
        
        // Write the string to an output destination
        if destinationClipboardButton.state == .on {
            let pb = NSPasteboard.general
            pb.clearContents()
            _ = pb.setString(concatString, forType: .string)
        }
        
        if destinationFileButton.state == .on {
            let savePanel = NSSavePanel();
            savePanel.title = "Specify an output file"
            let parent = notes[0].collection.fullPathURL
            if parent != nil {
                savePanel.directoryURL = parent!
            }
            savePanel.showsResizeIndicator = true
            savePanel.showsHiddenFiles = false
            savePanel.canCreateDirectories = true
            let defaultFileName = StringUtils.toReadableFilename(notes[0].title.value,
                                                                 allowDots: AppPrefs.shared.allowDots)
            var defaultExt = ".md"
            if formatHTMLFragmentButton.state == .on || formatHTMLDocButton.state == .on {
                defaultExt = ".html"
            }
            savePanel.nameFieldStringValue = defaultFileName + defaultExt
            let userChoice = savePanel.runModal()
            if userChoice == .OK {
                let url = savePanel.url
                do {
                    try concatString.write(to: url!, atomically: true, encoding: .utf8)
                } catch {
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "ShareViewController",
                                      level: .fault,
                                      message: "Problems writing shared text to disk")
                }
            }
        }
        
        if destinationBrowserButton.state == .on {
            if let notesFolder = notes[0].collection.lib.getURL(type: .notes) {
                let browseFolder = notesFolder.appendingPathComponent("browse", isDirectory: true)
                _ = FileUtils.makeDirectory(at: browseFolder)
                let fn = StringUtils.toCommonFileName(notes[0].title.value)
                let url = browseFolder.appendingPathComponent(fn).appendingPathExtension("html")
                do {
                    try concatString.write(to: url, atomically: true, encoding: .utf8)
                    NSWorkspace.shared.open(url)
                } catch {
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "ShareViewController",
                                      level: .fault,
                                      message: "Problems writing shared text to disk")
                }
            }
        }
        
        /// Open Mastodon domain, when appropriate.
        if destinationClipboardButton.state == .on && formatMicroButton.state == .on {
            let domain = AppPrefs.shared.mastodonDomain
            if !domain.isEmpty {
                var urlStr = domain
                if !domain.starts(with: "http") {
                    urlStr = "https://\(domain)"
                }
                if let url = URL(string: urlStr) {
                    NSWorkspace.shared.open(url)
                }
            }
            
        }
        
        // Save the user's choices so we can default to them later
        var contentSelector = entireNoteValue
        if contentBodyOnlyButton.state == .on {
            contentSelector = bodyOnlyValue
        } else if contentEntireNoteButton.state == .on {
            contentSelector = entireNoteValue
        } else if contentTeaserOnlyButton.state == .on {
            contentSelector = teaserOnlyValue
        } else if contentTitleButton.state == .on {
            contentSelector = titleOnlyValue
        } else if contentWikilinkButton.state == .on {
            contentSelector = wikilinkValue
        }
        defaults.set(contentSelector, forKey: contentKey)
        
        var formatSelector = htmlDocValue
        if formatNotenikButton.state == .on {
            formatSelector = notenikValue
        } else if formatHTMLFragmentButton.state == .on {
            formatSelector = htmlFragmentValue
        } else if formatHTMLBlockquoteButton.state == .on {
            formatSelector = htmlBlockquoteValue
        } else if formatMarkdownButton.state == .on {
            formatSelector = markkdownValue
        } else if formatMarkdownQuoteButton.state == .on {
            formatSelector = markdownQuoteValue
        } else if formatMarkdownQuoteFrom.state == .on {
            formatSelector = markdownQuoteFromValue
        } else if formatJSONButton.state == .on {
            formatSelector = jsonValue
        } else if formatMicroButton.state == .on {
            formatSelector = microValue
        } else if formatTemplateButton.state == .on {
            formatSelector = templateValue
        }
        defaults.set(formatSelector, forKey: formatKey)
        
        var destinationSelector = clipboardValue
        if destinationFileButton.state == .on {
            destinationSelector = fileValue
        } else if destinationBrowserButton.state == .on {
            destinationSelector = browserValue
        }
        defaults.set(destinationSelector, forKey: destinationKey)
        
        window!.close()
    }
    
    /// Share a single note, returning formatted string for that note.
    func shareNote(_ note: Note,
                   format: MarkedupFormat,
                   mkdownOptions: MkdownOptions,
                   displayParms: DisplayParms) -> String {
        
        var formatted = false
        var result = ""
        var stringToShare = ""
        
        // Perform selected transformation
        
        if !formatted && contentTitleButton.state == .on {
            formatted = true
            stringToShare = note.title.value
        }
        
        if !formatted && contentWikilinkButton.state == .on {
            formatted = true
            stringToShare = "[[\(note.noteID.getBasis())]]"
        }
        
        if !formatted && formatMarkdownQuoteButton.state == .on {
            (formatted, result) = fomatMarkdownQuote(note: note)
            if formatted {
                stringToShare = result
            }
        }

        if !formatted && formatMarkdownQuoteFrom.state == .on {
            (formatted, result) = formatMarkdownQF(note: note)
            if formatted {
                stringToShare = result
            }
        }
            
        if !formatted && contentBodyOnlyButton.state == .on && formatMarkdownButton.state == .on {
            if note.hasBody() {
                stringToShare = note.body.value
            }
            formatted = true
        }
            
        if !formatted && contentTeaserOnlyButton.state == .on {
            (formatted, result) = formatTeaserOnly(note: note, format: format, options: mkdownOptions)
            if formatted {
                stringToShare = result
            }
        }
        
        if !formatted && (formatNotenikButton.state == .on || formatMarkdownButton.state == .on) {
            formatted = true
            let writer = BigStringWriter()
            let noteLineMaker = NoteLineMaker(writer)
            if contentBodyOnlyButton.state == .on {
                noteLineMaker.putField(note.getBodyAsField(),
                                       format: note.noteID.getNoteFileFormat())
            } else {
                _ = noteLineMaker.putNote(note)
            }
            if noteLineMaker.fieldsWritten > 0 {
                stringToShare = writer.bigString
            }
        }
            
        // Format as JSON.
        if !formatted && formatJSONButton.state == .on {
            formatted = true
            let jWriter = JSONWriter()
            jWriter.open()
            if contentBodyOnlyButton.state == .on {
                jWriter.writeBodyAsObject(note)
            } else {
                jWriter.writeNoteAsObject(note)
            }
            jWriter.close()
            stringToShare = jWriter.outputString
        }
            
        // Format Body to HTML.
        if !formatted && contentBodyOnlyButton.state == .on {
            formatted = true
            let markdown = Markdown()
            markdown.md = note.body.value
            let context = NotesMkdownContext(io: io!)
            let html = markdown.parse(markdown: note.body.value,
                                      options: mkdownOptions,
                                      context: context)
            if format == .htmlDoc {
                let markedup = Markedup(format: .htmlDoc)
                markedup.startDoc(withTitle: note.title.value, withCSS: nil)
                markedup.append(html)
                markedup.finishDoc()
                stringToShare = markedup.code
            } else if formatHTMLBlockquoteButton.state == .on {
                let markedup = Markedup(format: .htmlFragment)
                markedup.startBlockQuote()
                markedup.append(markdown.html)
                markedup.finishBlockQuote()
                stringToShare = markedup.code
            } else {
                stringToShare = markdown.html
            }
        }
            
        if !formatted && formatMicroButton.state == .on {
            formatted = true
            stringToShare = note.body.value
            stringToShare.append("\n")
            if note.hasLink() {
                stringToShare.append(" \n")
                stringToShare.append(note.link.value)
                stringToShare.append("\n")
            }
            if contentEntireNoteButton.state == .on {
                if note.hasTags() {
                    stringToShare.append(" \n")
                    let tagsField = note.getTagsAsField()
                    if let tagsValue = tagsField?.value as? TagsValue {
                        stringToShare.append(tagsValue.microTags)
                        stringToShare.append("\n")
                    }
                }
            }
        }
            
        // Format with Merge Template.
        if !formatted && formatTemplateButton.state == .on {
            let openPanel = NSOpenPanel()
            openPanel.title = "Select a Merge Template"
            openPanel.prompt = "Use This Template"
            var parent = note.collection.lib.getURL(type: .reports)
            if parent == nil {
                parent = note.collection.lib.getURL(type: .notes)
            }
            if parent != nil {
                openPanel.directoryURL = parent!
            }
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            let userChoice = openPanel.runModal()
            if userChoice == .OK {
                formatted = true
                let template = Template()
                var ok = template.openTemplate(templateURL: openPanel.url!)
                if ok {
                    let notesList = NotesList()
                    notesList.append(note)
                    template.supplyData(note,
                                        dataSource: note.collection.title,
                                        io: io)
                    ok = template.generateOutput()
                    if ok {
                        stringToShare = template.util.linesToOutput
                    }
                }
                if !ok {
                    stringToShare = "Template Generation Failed"
                    Logger.shared.log(subsystem: "NotenikLib",
                                      category: "ShareViewController",
                                      level: .error,
                                      message: "Template generation failed")
                }
            }
        }
        
        if !formatted {
            // Format the entire Note as HTML.
            let noteDisplay = NoteDisplay()
            displayParms.localMj = false
            displayParms.format = format
            displayParms.curlyApostrophes = note.collection.curlyApostrophes
            displayParms.extLinksOpenInNewWindows = note.collection.extLinksOpenInNewWindows
            displayParms.checkBoxMessageHandlerName = NotenikConstants.checkBoxMessageHandlerName
            let mdResults = TransformMdResults()
            let displayString = noteDisplay.display(SortedNote(note: note), io: io!, parms: displayParms, mdResults: mdResults)
            if format == .htmlDoc && searchPhrase != nil && searchPhrase!.count > 0 {
                stringToShare = StringUtils.highlightPhraseInHTML(phrase: searchPhrase!,
                                                                  html: displayString,
                                                                  klass: "search-results")
            } else {
                stringToShare = displayString
            }
        }
        return stringToShare
    }
    
    func formatUsingTemplate(notes: [Note]) -> (Bool, String) {
        if let collection = io?.collection {
            collection.selShareTemplate = ""
            if let selectedShareTemplate = templateNamePopupButton.titleOfSelectedItem {
                if selectedShareTemplate != noTemplatesMsg && selectedShareTemplate != noTemplateSelMsg {
                    collection.selShareTemplate = selectedShareTemplate
                    let folder = collection.lib.getResource(type: .shareTemplatesFolder)
                    let file = ResourceFileSys(folderPath: folder.actualPath, fileName: selectedShareTemplate)
                    let contents = file.getText()
                    let template = Template()
                    template.openTemplate(templateContents: contents)
                    let notesList = NotesList()
                    for note in notes {
                        notesList.append(note)
                    }
                    template.supplyData(notesList: notesList, dataSource: collection.title, io: io)
                    let ok = template.generateOutput()
                    if !ok {
                        Logger.shared.log(subsystem: "Notenik",
                                          category: "ShareViewController",
                                          level: .error,
                                          message: "Template generation failed")
                    }
                    return (true, template.util.linesToOutput)
                }
            }
        }
        return (false, "")
    }
    
    func fomatMarkdownQuote(note: Note) -> (Bool, String) {
        let markedUp = Markedup(format: .markdown)
        if note.hasBody() {
            markedUp.startBlockQuote()
            markedUp.writeBlockOfLines(note.body.value)
            markedUp.finishBlockQuote()
        }
        if contentEntireNoteButton.state == .on {
            let author = note.creatorValue
            if author.count > 0 {
                markedUp.newLine()
                var authorLine = "-- "
                authorLine.append(author)
                let date = note.date.value
                if date.count > 0 {
                    authorLine.append(", \(date)")
                }
                let workTypeField = FieldGrabber.getField(note: note,
                                                          label: note.collection.workTypeFieldDef.fieldLabel.commonForm)
                var workType = ""
                if workTypeField != nil {
                    workType = workTypeField!.value.value
                }
                if workType.lowercased() == "unknown" {
                    workType = ""
                }
                var theType = ""
                var delim = "*"
                if !workType.isEmpty {
                    if let typeValue = workTypeField?.value as? WorkTypeValue? {
                        theType = typeValue!.theType
                        if !typeValue!.isMajor {
                            delim = "\""
                        }
                    } else {
                        theType = "the \(workType)"
                    }
                }
                var workTitle = note.workTitle.value
                if workTitle.lowercased() == "unknown" {
                    workTitle = ""
                }
                if workType.count > 0 && workTitle.count > 0 {
                    authorLine.append(", from \(theType) titled \(delim)\(workTitle)\(delim)")
                }
                markedUp.writeLine(authorLine)
            }
        }
        return (true, markedUp.code)
    }
    
    func formatMarkdownQF(note: Note) -> (Bool, String) {
        let markedUp = Markedup(format: .markdown)
        if note.hasBody() {
            markedUp.startBlockQuote()
            markedUp.writeBlockOfLines(note.body.value)
            markedUp.finishBlockQuote()
        }
        if contentEntireNoteButton.state == .on {
            markedUp.newLine()
            let workTypeField = FieldGrabber.getField(note: note,
                                                      label: note.collection.workTypeFieldDef.fieldLabel.commonForm)
            var workType = ""
            if workTypeField != nil {
                workType = workTypeField!.value.value
            }
            if workType.lowercased() == "unknown" {
                workType = ""
            }
            var workTitle = note.workTitle.value
            if workTitle.lowercased() == "unknown" {
                workTitle = ""
            }
            let authorLinkField = FieldGrabber.getField(note: note, label: NotenikConstants.authorLinkCommon)
            var authorLink = ""
            if authorLinkField != nil {
                authorLink = authorLinkField!.value.value
            }
            let workLinkField = FieldGrabber.getField(note: note, label: note.collection.workLinkFieldDef.fieldLabel.commonForm)
            var workLink = ""
            if workLinkField != nil {
                workLink = workLinkField!.value.value
            }
            markedUp.writeLine("{:quote-from:\(note.creatorValue)|\(note.date.value)|\(workType)|\(workTitle)|\(authorLink)|\(workLink)}")
        }
        return (true, markedUp.code)
    }
    
    func formatTeaserOnly(note: Note, format: MarkedupFormat, options: MkdownOptions) -> (Bool, String) {
        if note.hasTeaser() {
            if format == .htmlDoc || format == .htmlFragment {
                let markdown = Markdown()
                markdown.md = note.teaser.value
                let context = NotesMkdownContext(io: io!)
                let html = markdown.parse(markdown: note.teaser.value,
                                          options: options,
                                          context: context)
                return (true, html)
            } else {
                return (true, note.teaser.value)
            }
        }
        return (false, "")
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        window!.close()
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ShareViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
}
