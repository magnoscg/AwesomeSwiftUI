// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct DisclosureTreeViewTests {
    private let tree = [
        DisclosureTreeViewNode(id: "a", title: "A", children: [
            DisclosureTreeViewNode(id: "a1", title: "A1", children: [
                DisclosureTreeViewNode(id: "a1x", title: "A1X"),
            ]),
        ]),
        DisclosureTreeViewNode(id: "b", title: "B"),
    ]

    @Test func collapsedTreeShowsOnlyTheRoots() {
        let rows = DisclosureTreeViewRows.visible(in: tree, expanded: [])

        #expect(rows.map(\.id) == ["a", "b"])
    }

    @Test func expandingAddsChildrenRightAfterTheirParent() {
        let rows = DisclosureTreeViewRows.visible(in: tree, expanded: ["a"])

        #expect(rows.map(\.id) == ["a", "a1", "b"])
        #expect(rows.map(\.depth) == [0, 1, 0])
    }

    @Test func aChildStaysHiddenWhileItsParentIsCollapsed() {
        let rows = DisclosureTreeViewRows.visible(in: tree, expanded: ["a1"])

        #expect(rows.map(\.id) == ["a", "b"])
    }

    @Test func deepExpansionTracksTheDepth() {
        let rows = DisclosureTreeViewRows.visible(in: tree, expanded: ["a", "a1"])

        #expect(rows.map(\.depth) == [0, 1, 2, 0])
    }

    @Test func emptyTreeHasNoRows() {
        #expect(DisclosureTreeViewRows.visible(in: [], expanded: ["a"]).isEmpty)
    }
}
