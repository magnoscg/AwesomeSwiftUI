// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct AdaptiveColumnsGridTests {
    @Test(arguments: [(170.0, 2), (270.0, 3), (360.0, 4)])
    func columnsFollowTheWidth(width: CGFloat, expected: Int) {
        #expect(AdaptiveColumnsGridMath.columnCount(width: width, minColumnWidth: 80, spacing: 10, maxColumns: 6) == expected)
    }

    @Test func maxColumnsCapsTheCount() {
        #expect(AdaptiveColumnsGridMath.columnCount(width: 1_000, minColumnWidth: 80, spacing: 10, maxColumns: 3) == 3)
    }

    @Test(arguments: [
        (CGFloat(0), CGFloat(80)), (-10, 80), (.infinity, 80), (.nan, 80), (300, 0), (300, -5), (300, .nan),
    ])
    func hostileSizesGiveOneColumn(width: CGFloat, minColumnWidth: CGFloat) {
        #expect(AdaptiveColumnsGridMath.columnCount(width: width, minColumnWidth: minColumnWidth, spacing: 10, maxColumns: 6) == 1)
    }

    @Test func nonPositiveMaxColumnsStillGivesOneColumn() {
        #expect(AdaptiveColumnsGridMath.columnCount(width: 500, minColumnWidth: 80, spacing: 10, maxColumns: 0) == 1)
    }

    @Test func negativeSpacingCountsAsZero() {
        #expect(AdaptiveColumnsGridMath.columnCount(width: 320, minColumnWidth: 80, spacing: -20, maxColumns: 6) == 4)
    }
}
