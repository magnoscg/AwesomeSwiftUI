// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct ShowcaseEntry: Identifiable {
    let id: String
    let title: String
    let category: String
    let summary: String
    let keywords: [String]
    let minIOS: String
    /// Returns nil when the running iOS is older than the component's minimum.
    let demo: @MainActor () -> AnyView?
}

struct ShowcaseSection: Identifiable {
    let category: String
    let entries: [ShowcaseEntry]

    var id: String { category }
}

enum ShowcaseSearch {
    /// Groups the matching entries by category, keeping their order inside each one.
    static func sections(in entries: [ShowcaseEntry], matching query: String) -> [ShowcaseSection] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = trimmedQuery.isEmpty ? entries : entries.filter { matchesQuery($0, trimmedQuery) }

        return Dictionary(grouping: matches, by: \.category)
            .map { ShowcaseSection(category: $0.key, entries: $0.value) }
            .sorted { $0.category < $1.category }
    }

    private static func matchesQuery(_ entry: ShowcaseEntry, _ query: String) -> Bool {
        ([entry.title, entry.category, entry.summary] + entry.keywords)
            .contains { $0.localizedStandardContains(query) }
    }
}
