// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SwipeActionCardsTests {
    private struct Item: Identifiable, Equatable {
        let id: Int
    }

    private let items = [Item(id: 1), Item(id: 2), Item(id: 3)]

    @Test func removingAnItemKeepsTheOrderOfTheRest() {
        #expect(SwipeActionCardsLogic.removing(2, from: items) == [Item(id: 1), Item(id: 3)])
    }

    @Test func removingAnUnknownItemChangesNothing() {
        #expect(SwipeActionCardsLogic.removing(9, from: items) == items)
    }

    @Test func pinningMovesAnItemToTheFront() {
        #expect(SwipeActionCardsLogic.pinning(3, in: items) == [Item(id: 3), Item(id: 1), Item(id: 2)])
    }

    @Test func pinningTheFirstItemLeavesItThere() {
        #expect(SwipeActionCardsLogic.pinning(1, in: items) == items)
    }

    @Test func pinningAnUnknownItemChangesNothing() {
        #expect(SwipeActionCardsLogic.pinning(9, in: items) == items)
    }
}
