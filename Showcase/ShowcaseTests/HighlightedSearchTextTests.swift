// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import SwiftUI
import Testing
@testable import Showcase

struct HighlightedSearchTextTests {
    private func matched(_ query: String, in text: String) -> [String] {
        HighlightedSearchTextMatcher.matches(of: query, in: text).map { String(text[$0]) }
    }

    private func highlightedRuns(_ query: String, in text: String) -> [String] {
        let result = HighlightedSearchTextMatcher.highlighted(text, query: query, background: .yellow, foreground: .black)
        return result.runs
            .filter { $0.backgroundColor != nil }
            .map { String(result[$0.range].characters) }
    }

    @Test func ignoresCase() {
        #expect(matched("hello", in: "HeLLo world") == ["HeLLo"])
    }

    @Test func ignoresAccentsInTheText() {
        #expect(matched("cafe", in: "un café") == ["café"])
    }

    @Test func ignoresAccentsInTheQuery() {
        #expect(matched("café", in: "un cafe") == ["cafe"])
    }

    @Test func ignoresCaseAndAccentsTogether() {
        #expect(matched("MANANA", in: "la mañana") == ["mañana"])
    }

    @Test func findsEveryMatch() {
        #expect(matched("cafe", in: "Café, CAFE y cafetería") == ["Café", "CAFE", "cafe"])
    }

    @Test func matchesDoNotOverlap() {
        #expect(matched("ana", in: "banana") == ["ana"])
        #expect(matched("aa", in: "aaaaa") == ["aa", "aa"])
    }

    @Test func noMatchGivesNothing() {
        #expect(matched("zebra", in: "café").isEmpty)
    }

    @Test(arguments: ["", "   ", "\n"])
    func aBlankQueryMatchesNothing(query: String) {
        #expect(matched(query, in: "some text").isEmpty)
    }

    @Test func surroundingSpacesInTheQueryAreIgnored() {
        #expect(matched("  cafe ", in: "un café") == ["café"])
    }

    @Test func aQueryOfOnlyACombiningAccentFinishes() {
        #expect(matched("\u{0301}", in: "café").isEmpty)
    }

    @Test func worksInEmptyText() {
        #expect(matched("a", in: "").isEmpty)
    }

    @Test func worksAfterEmoji() {
        #expect(matched("cafe", in: "👩‍💻 café 🇪🇸 cafe") == ["café", "cafe"])
    }

    @Test func highlightsExactlyTheMatches() {
        #expect(highlightedRuns("cafe", in: "un café y un CAFE") == ["café", "CAFE"])
    }

    @Test func aBlankQueryHighlightsNothing() {
        #expect(highlightedRuns("", in: "un café").isEmpty)
    }

    @Test func highlightingKeepsTheWholeText() {
        let text = "👩‍💻 un café"

        let result = HighlightedSearchTextMatcher.highlighted(text, query: "cafe", background: .yellow, foreground: .black)

        #expect(String(result.characters) == text)
    }
}
