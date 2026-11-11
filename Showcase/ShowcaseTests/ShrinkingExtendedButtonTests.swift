// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ShrinkingExtendedButtonTests {
    @Test(arguments: [(-60.0, true), (0.0, true), (40.0, true), (41.0, false), (900.0, false)] as [(CGFloat, Bool)])
    func extendsOnlyNearTheTop(offset: CGFloat, expected: Bool) {
        #expect(ShrinkingExtendedButtonMath.shouldExtend(offset: offset, threshold: 40) == expected)
    }

    @Test func aNegativeThresholdCountsAsZero() {
        #expect(ShrinkingExtendedButtonMath.shouldExtend(offset: 0, threshold: -30))
        #expect(!ShrinkingExtendedButtonMath.shouldExtend(offset: 1, threshold: -30))
    }
}
