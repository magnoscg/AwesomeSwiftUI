// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct FilterChipGroupTests {
    @Test func chipsThatFitShareARow() {
        let rows = FilterChipGroupFlowLayout.rows(for: [40, 40, 40], maxWidth: 140, spacing: 10)

        #expect(rows == [[0, 1, 2]])
    }

    @Test func aChipThatDoesNotFitStartsANewRow() {
        let rows = FilterChipGroupFlowLayout.rows(for: [60, 60, 60], maxWidth: 140, spacing: 10)

        #expect(rows == [[0, 1], [2]])
    }

    @Test func theSpacingCountsTowardsTheWidth() {
        let rows = FilterChipGroupFlowLayout.rows(for: [70, 70], maxWidth: 140, spacing: 1)

        #expect(rows == [[0], [1]])
    }

    @Test func aChipWiderThanTheRowGetsARowOfItsOwn() {
        let rows = FilterChipGroupFlowLayout.rows(for: [30, 200, 30], maxWidth: 100, spacing: 8)

        #expect(rows == [[0], [1], [2]])
    }

    @Test func noChipsMakeNoRows() {
        #expect(FilterChipGroupFlowLayout.rows(for: [], maxWidth: 100, spacing: 8).isEmpty)
    }
}
