// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct HamburgerMenuButtonTests {
    private let rect = CGRect(x: 0, y: 0, width: 24, height: 24)

    @Test func closedIsThreeHorizontalBars() {
        let bars = HamburgerMenuButtonShape(progress: 0).bars(in: rect)

        #expect(bars.count == 3)
        #expect(bars.allSatisfy { abs($0.start.y - $0.end.y) < 0.001 })
        #expect(Set(bars.map(\.start.y)).count == 3)
    }

    @Test func openIsTwoBarsCrossingAtTheCenter() {
        let bars = HamburgerMenuButtonShape(progress: 1).bars(in: rect)

        #expect(bars.count == 2)
        for bar in bars {
            #expect(abs((bar.start.x + bar.end.x) / 2 - rect.midX) < 0.001)
            #expect(abs((bar.start.y + bar.end.y) / 2 - rect.midY) < 0.001)
            #expect(abs(abs(bar.start.x - bar.end.x) - abs(bar.start.y - bar.end.y)) < 0.001)
        }
    }

    @Test func aSpringOvershootStaysAtTheCross() {
        #expect(HamburgerMenuButtonShape(progress: 1.2).bars(in: rect) == HamburgerMenuButtonShape(progress: 1).bars(in: rect))
    }

    @Test func anEmptyRectDoesNotBreak() {
        #expect(HamburgerMenuButtonShape(progress: 0.5).bars(in: .zero).count == 3)
    }

    @Test func openBarsLeanOppositeWays() throws {
        let bars = HamburgerMenuButtonShape(progress: 1).bars(in: rect)
        let first = try #require(bars.first)
        let last = try #require(bars.last)

        let firstSlope = (first.end.y - first.start.y) / (first.end.x - first.start.x)
        let lastSlope = (last.end.y - last.start.y) / (last.end.x - last.start.x)

        #expect(firstSlope * lastSlope < 0)
    }
}
