//
//  AppIntents.swift
//  Notenik
//
//  Created by Herb Bowie on 11/10/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import AppIntents

import NotenikLib

@available(macOS 27, *)
@AppIntent(schema: .system.searchInApp)
struct SystemSearchInAppIntent: ShowInAppSearchResultsIntent {
    
    static var supportedModes: IntentModes {
        .foreground
    }
    
    static var allowedExecutionTargets: IntentExecutionTargets {
        .main
    }
    
    static var searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria
    
    static func normalizedTerm(_ term: String) -> String? {
        let trimmed = term.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    func perform() async throws -> some IntentResult {
        
        guard let searchTerm = Self.normalizedTerm(criteria.term) else {
            throw $criteria.needsValueError(
                "What do you want to search for?"
            )
        }
        CollectionJuggler.shared.showInAppSearchResults(searchTerm: searchTerm)
        
        return .result()
    }
}
