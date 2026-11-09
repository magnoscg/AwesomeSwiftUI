// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct EmojiReactionPickerTests {
    @Test(arguments: [(0.0, 0), (45.0, 0), (50.0, 1), (110.0, 2)] as [(CGFloat, Int)])
    func findsTheCellUnderTheFinger(x: CGFloat, expected: Int) {
        #expect(EmojiReactionPickerMath.index(atX: x, cellWidth: 44, spacing: 6, count: 5) == expected)
    }

    @Test func positionsOutsideTheRowClampToItsEnds() {
        #expect(EmojiReactionPickerMath.index(atX: -80, cellWidth: 44, spacing: 6, count: 5) == 0)
        #expect(EmojiReactionPickerMath.index(atX: 9_000, cellWidth: 44, spacing: 6, count: 5) == 4)
        #expect(EmojiReactionPickerMath.index(atX: .greatestFiniteMagnitude, cellWidth: 44, spacing: 6, count: 5) == 4)
    }

    @Test func negativeSpacingCountsAsZero() {
        #expect(EmojiReactionPickerMath.index(atX: 50, cellWidth: 44, spacing: -20, count: 5) == 1)
    }

    @Test(arguments: [(10.0, 44.0, 0), (10.0, 0.0, 5), (10.0, -4.0, 5), (.nan, 44.0, 5), (.infinity, 44.0, 5)] as [(CGFloat, CGFloat, Int)])
    func nothingToHitGivesNil(x: CGFloat, cellWidth: CGFloat, count: Int) {
        #expect(EmojiReactionPickerMath.index(atX: x, cellWidth: cellWidth, spacing: 6, count: count) == nil)
    }
}
