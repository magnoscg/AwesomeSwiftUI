// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct MasonryLayoutTests {
    @Test func itemsGoToTheShortestColumn() {
        let result = MasonryLayoutMath.place(heights: [100, 50, 70], columns: 2, spacing: 10)

        #expect(result.placements == [
            .init(column: 0, y: 0),
            .init(column: 1, y: 0),
            .init(column: 1, y: 60),
        ])
        #expect(result.totalHeight == 130)
    }

    @Test func noItemsHaveNoHeight() {
        let result = MasonryLayoutMath.place(heights: [], columns: 3, spacing: 10)

        #expect(result.placements.isEmpty)
        #expect(result.totalHeight == 0)
    }

    @Test(arguments: [0, -4])
    func nonPositiveColumnsUseOneColumn(columns: Int) {
        let result = MasonryLayoutMath.place(heights: [10, 20], columns: columns, spacing: 5)

        #expect(result.placements.map(\.column) == [0, 0])
        #expect(result.totalHeight == 35)
    }

    @Test func negativeHeightsCountAsZero() {
        let result = MasonryLayoutMath.place(heights: [-50], columns: 1, spacing: 8)

        #expect(result.totalHeight == 0)
    }

    @Test func columnWidthSharesTheSpace() {
        #expect(MasonryLayoutMath.columnWidth(totalWidth: 100, columns: 2, spacing: 10) == 45)
    }

    @Test(arguments: [
        (CGFloat(100), 0), (.infinity, 2), (.nan, 2), (5, 4),
    ])
    func hostileWidthsGiveNoNegativeColumn(totalWidth: CGFloat, columns: Int) {
        #expect(MasonryLayoutMath.columnWidth(totalWidth: totalWidth, columns: columns, spacing: 10) == 0)
    }
}
