// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct DragSelectGridTests {
    private func index(at point: CGPoint, count: Int = 20) -> Int? {
        DragSelectGridMath.index(at: point, width: 400, columns: 4, spacing: 0, count: count)
    }

    @Test func aPointMapsToItsTile() {
        #expect(index(at: CGPoint(x: 50, y: 50)) == 0)
        #expect(index(at: CGPoint(x: 350, y: 50)) == 3)
        #expect(index(at: CGPoint(x: 50, y: 150)) == 4)
        #expect(index(at: CGPoint(x: 250, y: 250)) == 10)
    }

    @Test func spacingShrinksTheTiles() {
        let result = DragSelectGridMath.index(at: CGPoint(x: 105, y: 10), width: 410, columns: 4, spacing: 10, count: 20)

        #expect(result == 1)
    }

    @Test func aPointOutsideTheGridUsesTheNearestTile() {
        #expect(index(at: CGPoint(x: -50, y: -50)) == 0)
        #expect(index(at: CGPoint(x: 9_000, y: 50)) == 3)
        #expect(index(at: CGPoint(x: 50, y: 9_000)) == 16)
    }

    @Test func anIncompleteLastRowNeverPassesTheLastTile() {
        #expect(index(at: CGPoint(x: 350, y: 150), count: 6) == 5)
    }

    @Test func nothingToHitReturnsNil() {
        #expect(index(at: .zero, count: 0) == nil)
        #expect(DragSelectGridMath.index(at: .zero, width: 0, columns: 4, spacing: 0, count: 4) == nil)
        #expect(DragSelectGridMath.index(at: .zero, width: -10, columns: 4, spacing: 0, count: 4) == nil)
        #expect(DragSelectGridMath.index(at: CGPoint(x: CGFloat.nan, y: 0), width: 100, columns: 4, spacing: 0, count: 4) == nil)
    }

    @Test func spacingThatLeavesNoRoomReturnsNil() {
        #expect(DragSelectGridMath.index(at: .zero, width: 10, columns: 4, spacing: 100, count: 4) == nil)
    }

    @Test(arguments: [0, -3])
    func nonsenseColumnsBecomeOneColumn(columns: Int) {
        #expect(DragSelectGridMath.clampedColumns(columns) == 1)
        #expect(DragSelectGridMath.index(at: CGPoint(x: 50, y: 250), width: 100, columns: columns, spacing: 0, count: 8) == 2)
    }

    @Test func aHugeColumnCountIsCapped() {
        #expect(DragSelectGridMath.clampedColumns(Int.max) == 24)
    }

    @Test func aStrokeAddsTheRangeToWhatWasSelected() {
        let result = DragSelectGridMath.selection(base: [9], ids: Array(0..<10), from: 1, to: 3, selecting: true)

        #expect(result == [1, 2, 3, 9])
    }

    @Test func aBackwardStrokeCoversTheSameRange() {
        let result = DragSelectGridMath.selection(base: [], ids: Array(0..<10), from: 3, to: 1, selecting: true)

        #expect(result == [1, 2, 3])
    }

    @Test func aDeselectingStrokeRemovesTheRange() {
        let result = DragSelectGridMath.selection(base: [1, 2, 3, 4], ids: Array(0..<10), from: 2, to: 3, selecting: false)

        #expect(result == [1, 4])
    }

    @Test func aStrokeOnAShrunkenCollectionStaysInRange() {
        let result = DragSelectGridMath.selection(base: [], ids: [7, 8], from: 5, to: 40, selecting: true)

        #expect(result == [8])
    }

    @Test func noItemsKeepTheSelection() {
        let result = DragSelectGridMath.selection(base: [1], ids: [Int](), from: 0, to: 3, selecting: true)

        #expect(result == [1])
    }
}
