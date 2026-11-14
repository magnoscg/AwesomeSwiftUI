// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ShowcaseSearchTests {
    private let entries = [
        makeEntry(id: "glow", title: "Glow Button", category: "Buttons", keywords: ["botón", "brillo"]),
        makeEntry(id: "press", title: "Press Style", category: "Buttons", keywords: ["tap"]),
        makeEntry(id: "aurora", title: "Aurora", category: "Backgrounds", summary: "A moving gradient.", keywords: ["mesh"]),
    ]

    @Test func emptyQueryReturnsEveryEntrySortedByCategory() {
        let sections = ShowcaseSearch.sections(in: entries, matching: "")

        #expect(sections.map(\.category) == ["Backgrounds", "Buttons"])
        #expect(sections[1].entries.map(\.id) == ["glow", "press"])
    }

    @Test func blankQueryCountsAsEmpty() {
        let sections = ShowcaseSearch.sections(in: entries, matching: "   ")

        #expect(sections.flatMap(\.entries).count == 3)
    }

    @Test(arguments: [
        ("glow", "glow"),
        ("GLOW BUTTON", "glow"),
        ("boton", "glow"),
        ("botón", "glow"),
        ("gradient", "aurora"),
        ("backgrounds", "aurora"),
        ("  tap  ", "press"),
    ])
    func findsEntryByAnySearchableField(query: String, expectedID: String) {
        let sections = ShowcaseSearch.sections(in: entries, matching: query)

        #expect(sections.flatMap(\.entries).map(\.id) == [expectedID])
    }

    @Test func noMatchReturnsNoSections() {
        #expect(ShowcaseSearch.sections(in: entries, matching: "zzz").isEmpty)
    }

    @Test func emptyCatalogReturnsNoSections() {
        #expect(ShowcaseSearch.sections(in: [], matching: "").isEmpty)
    }
}

private func makeEntry(
    id: String,
    title: String,
    category: String,
    summary: String = "Summary.",
    keywords: [String]
) -> ShowcaseEntry {
    ShowcaseEntry(
        id: id,
        title: title,
        category: category,
        summary: summary,
        keywords: keywords,
        minIOS: "18.0",
        demo: { nil }
    )
}
