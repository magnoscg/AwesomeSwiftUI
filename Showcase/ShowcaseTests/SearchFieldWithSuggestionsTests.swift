// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SearchFieldWithSuggestionsTests {
    private let cities = ["Roma", "Madrid", "Málaga", "Marseille"]

    @Test func prefixMatchesComeFirst() {
        let matches = SearchFieldWithSuggestionsFilter.matches(for: "ma", in: cities)

        #expect(matches == ["Madrid", "Málaga", "Marseille", "Roma"])
    }

    @Test func accentsAndCaseAreIgnored() {
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "MALA", in: cities) == ["Málaga"])
    }

    @Test func emptyQueryShowsNothing() {
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "  ", in: cities).isEmpty)
    }

    @Test func fullSuggestionHidesTheList() {
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "madrid", in: cities).isEmpty)
    }

    @Test func limitIsRespected() {
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "ma", in: cities, limit: 2).count == 2)
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "ma", in: cities, limit: 0).isEmpty)
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "ma", in: cities, limit: -1).isEmpty)
    }

    @Test func duplicatesAreDropped() {
        #expect(SearchFieldWithSuggestionsFilter.matches(for: "par", in: ["Paris", "paris"]) == ["Paris"])
    }
}
