// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct BreadcrumbTrailTests {
    @Test(arguments: [0, 1, 2]) func shortTrailsNeverCollapse(count: Int) {
        #expect(BreadcrumbTrailMath.collapsedTails(count: count).isEmpty)
    }

    @Test func theTailShrinksFromWidestToNarrowest() {
        #expect(BreadcrumbTrailMath.collapsedTails(count: 3) == [1])
        #expect(BreadcrumbTrailMath.collapsedTails(count: 4) == [2, 1])
        #expect(BreadcrumbTrailMath.collapsedTails(count: 50) == [3, 2, 1])
    }

    @Test func splitKeepsTheEndsAndHidesTheMiddle() {
        let parts = BreadcrumbTrailMath.split([1, 2, 3, 4, 5], tail: 2)

        #expect(Array(parts.head) == [1])
        #expect(Array(parts.hidden) == [2, 3])
        #expect(Array(parts.tail) == [4, 5])
    }

    @Test func splitOfNothingIsEmpty() {
        let parts = BreadcrumbTrailMath.split([Int](), tail: 2)

        #expect(parts.head.isEmpty)
        #expect(parts.hidden.isEmpty)
        #expect(parts.tail.isEmpty)
    }

    @Test func anOversizedTailNeverCoversTheFirstCrumb() {
        let parts = BreadcrumbTrailMath.split([1, 2, 3], tail: 10)

        #expect(Array(parts.head) == [1])
        #expect(parts.hidden.isEmpty)
        #expect(Array(parts.tail) == [2, 3])
    }

    @Test func aNegativeTailHidesEverythingAfterTheFirst() {
        let parts = BreadcrumbTrailMath.split([1, 2, 3], tail: -1)

        #expect(Array(parts.hidden) == [2, 3])
        #expect(parts.tail.isEmpty)
    }
}
