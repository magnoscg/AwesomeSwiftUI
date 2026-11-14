// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct SelectAllChecklistTests {
    private let ids = [1, 2, 3]

    @Test func nothingSelectedIsNone() {
        #expect(SelectAllChecklistState(selection: [], among: ids) == .none)
    }

    @Test func partOfTheListIsSome() {
        #expect(SelectAllChecklistState(selection: [2], among: ids) == .some)
    }

    @Test func theWholeListIsAll() {
        #expect(SelectAllChecklistState(selection: [1, 2, 3], among: ids) == .all)
    }

    @Test func anEmptyListIsNoneEvenWithASelection() {
        #expect(SelectAllChecklistState(selection: [7], among: [Int]()) == .none)
    }

    @Test func idsOutsideTheListDoNotCount() {
        #expect(SelectAllChecklistState(selection: [8, 9, 10], among: ids) == .none)
        #expect(SelectAllChecklistState(selection: [1, 2, 9], among: ids) == .some)
    }

    @Test func selectAllFromSomeSelectsEveryItem() {
        #expect(SelectAllChecklistState.toggledAll([2], among: ids) == [1, 2, 3])
    }

    @Test func selectAllFromAllDeselectsEveryItem() {
        #expect(SelectAllChecklistState.toggledAll([1, 2, 3], among: ids).isEmpty)
    }

    @Test func selectAllKeepsIdsOutsideTheList() {
        #expect(SelectAllChecklistState.toggledAll([9], among: ids) == [1, 2, 3, 9])
        #expect(SelectAllChecklistState.toggledAll([1, 2, 3, 9], among: ids) == [9])
    }
}
