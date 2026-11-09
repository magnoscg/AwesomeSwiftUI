// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct GlassTagCloudTests {
    private let wide = CGSize(width: 40, height: 20)
    private let narrow = CGSize(width: 30, height: 20)

    @available(iOS 26, *)
    @Test func itemsThatFitShareARow() {
        let result = GlassTagCloudFlow.arrange([wide, narrow], width: 100, spacing: 10)

        #expect(result.origins == [.zero, CGPoint(x: 50, y: 0)])
        #expect(result.size == CGSize(width: 80, height: 20))
    }

    @available(iOS 26, *)
    @Test func anItemThatDoesNotFitStartsANewRow() {
        let result = GlassTagCloudFlow.arrange([wide, narrow], width: 60, spacing: 10)

        #expect(result.origins == [.zero, CGPoint(x: 0, y: 30)])
        #expect(result.size == CGSize(width: 40, height: 50))
    }

    @available(iOS 26, *)
    @Test func theTallestItemSetsTheRowHeight() {
        let tall = CGSize(width: 30, height: 50)

        let result = GlassTagCloudFlow.arrange([wide, tall, narrow], width: 80, spacing: 10)

        #expect(result.origins[2] == CGPoint(x: 0, y: 60))
    }

    @available(iOS 26, *)
    @Test func anOversizedFirstItemDoesNotLeaveAnEmptyRow() {
        let huge = CGSize(width: 200, height: 20)

        let result = GlassTagCloudFlow.arrange([huge], width: 100, spacing: 10)

        #expect(result.origins == [.zero])
        #expect(result.size == huge)
    }

    @available(iOS 26, *)
    @Test func noItemsTakeNoSpace() {
        let result = GlassTagCloudFlow.arrange([], width: 100, spacing: 10)

        #expect(result.origins.isEmpty)
        #expect(result.size == .zero)
    }
}
