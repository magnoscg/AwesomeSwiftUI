// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct SearchScopesAndSuggestionsTests {
    private let suggestions = ["Apple", "Apricot", "Grape", "Papaya"]

    @Test func emptyTextShowsTheFirstSuggestions() {
        let matches = SearchScopesAndSuggestionsMath.matches(in: suggestions, for: "  ", limit: 2)

        #expect(matches == ["Apple", "Apricot"])
    }

    @Test func textNarrowsTheSuggestionsIgnoringCase() {
        let matches = SearchScopesAndSuggestionsMath.matches(in: suggestions, for: "GR")

        #expect(matches == ["Grape"])
    }

    @Test func aSuggestionAlreadyTypedIsHidden() {
        let matches = SearchScopesAndSuggestionsMath.matches(in: suggestions, for: "apple")

        #expect(matches.isEmpty)
    }

    @Test func duplicatesAreRemoved() {
        let matches = SearchScopesAndSuggestionsMath.matches(in: ["Kiwi", "Kiwi", "Lime"], for: "")

        #expect(matches == ["Kiwi", "Lime"])
    }

    @Test(arguments: [0, -4]) func aLimitOfNothingShowsNothing(limit: Int) {
        #expect(SearchScopesAndSuggestionsMath.matches(in: suggestions, for: "", limit: limit).isEmpty)
    }
}
