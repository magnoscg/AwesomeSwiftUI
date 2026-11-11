// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct ReorderableGridTests {
    private struct Tile: Identifiable, Equatable {
        let id: String
    }

    private let tiles = ["a", "b", "c", "d"].map(Tile.init)

    @available(iOS 27, *)
    private func ids(moving sources: [String], before destination: String?) -> [String] {
        ReorderableGridReordering.moving(sources, before: destination, in: tiles).map(\.id)
    }

    @available(iOS 27, *)
    @Test func movesATileEarlier() {
        #expect(ids(moving: ["c"], before: "a") == ["c", "a", "b", "d"])
    }

    @available(iOS 27, *)
    @Test func movesATileLater() {
        #expect(ids(moving: ["a"], before: "d") == ["b", "c", "a", "d"])
    }

    @available(iOS 27, *)
    @Test func nilDestinationMovesToTheEnd() {
        #expect(ids(moving: ["a"], before: nil) == ["b", "c", "d", "a"])
    }

    @available(iOS 27, *)
    @Test func movesSeveralTilesInTheOrderGiven() {
        #expect(ids(moving: ["d", "b"], before: "a") == ["d", "b", "a", "c"])
    }

    @available(iOS 27, *)
    @Test func aMovedDestinationAnchorsOnTheNextUnmovedTile() {
        #expect(ids(moving: ["a", "c"], before: "c") == ["b", "a", "c", "d"])
    }

    @available(iOS 27, *)
    @Test func aMovedDestinationWithNothingAfterItGoesToTheEnd() {
        #expect(ids(moving: ["d", "a"], before: "d") == ["b", "c", "d", "a"])
    }

    @available(iOS 27, *)
    @Test func movingBeforeItselfChangesNothing() {
        #expect(ids(moving: ["b"], before: "b") == ["a", "b", "c", "d"])
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
