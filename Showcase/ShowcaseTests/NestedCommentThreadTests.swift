// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct NestedCommentThreadTests {
    private typealias Comment = NestedCommentThreadComment

    private let thread = [
        Comment(id: "a", author: "A", text: "", replies: [
            Comment(id: "b", author: "B", text: "", replies: [
                Comment(id: "c", author: "C", text: ""),
            ]),
            Comment(id: "d", author: "D", text: ""),
        ]),
        Comment(id: "e", author: "E", text: ""),
    ]

    @Test func rowsAreInReadingOrder() {
        let rows = NestedCommentThreadLogic.rows(for: thread, collapsed: [])

        #expect(rows.map(\.id) == ["a", "b", "c", "d", "e"])
    }

    @Test func guidesSayWhichLinesContinue() {
        let rows = NestedCommentThreadLogic.rows(for: thread, collapsed: [])

        #expect(rows.map(\.guides) == [[], [true], [true, false], [false], []])
    }

    @Test func collapsingHidesEveryDescendant() {
        let rows = NestedCommentThreadLogic.rows(for: thread, collapsed: ["a"])

        #expect(rows.map(\.id) == ["a", "e"])
    }

    @Test func collapsingAnUnknownIDChangesNothing() {
        #expect(NestedCommentThreadLogic.rows(for: thread, collapsed: ["zzz"]).count == 5)
    }

    @Test func anEmptyThreadHasNoRows() {
        #expect(NestedCommentThreadLogic.rows(for: [], collapsed: []).isEmpty)
    }

    @Test func replyCountsIncludeDeepReplies() throws {
        let root = try #require(thread.first)

        #expect(NestedCommentThreadLogic.replyCount(of: root) == 3)
    }
}
