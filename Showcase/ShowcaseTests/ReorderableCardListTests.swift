// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct ReorderableCardListTests {
    private struct Card: Identifiable, Equatable {
        let id: String
    }

    private let cards = ["a", "b", "c", "d"].map(Card.init)

    @available(iOS 27, *)
    private func ids(moving sources: [String], before destination: String?) -> [String] {
        CardReordering.moving(sources, before: destination, in: cards).map(\.id)
    }

    @available(iOS 27, *)
    @Test func movesAnItemUp() {
        #expect(ids(moving: ["c"], before: "a") == ["c", "a", "b", "d"])
    }

    @available(iOS 27, *)
    @Test func movesAnItemDown() {
        #expect(ids(moving: ["a"], before: "d") == ["b", "c", "a", "d"])
    }

    @available(iOS 27, *)
    @Test func nilDestinationMovesToTheEnd() {
        #expect(ids(moving: ["a"], before: nil) == ["b", "c", "d", "a"])
    }

    @available(iOS 27, *)
    @Test func movesSeveralItemsInTheOrderGiven() {
        #expect(ids(moving: ["d", "b"], before: "a") == ["d", "b", "a", "c"])
    }

    @available(iOS 27, *)
    @Test func destinationAmongTheSourcesChangesNothing() {
        #expect(ids(moving: ["b", "c"], before: "c") == ["a", "b", "c", "d"])
    }

    @available(iOS 27, *)
    @Test func unknownSourcesAreIgnored() {
        #expect(ids(moving: ["z"], before: "a") == ["a", "b", "c", "d"])
    }

    @available(iOS 27, *)
    @Test func unknownDestinationMovesToTheEnd() {
        #expect(ids(moving: ["a"], before: "z") == ["b", "c", "d", "a"])
    }
}
