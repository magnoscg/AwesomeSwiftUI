// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

/// Every component that draws over a color it is given carries its own copy of
/// the style, because a component is one file. This runs the same cases on each.
struct ContrastingForegroundTests {
    private static let styles: [(String, @Sendable (Color) -> Color)] = [
        ("ElasticDragButton", { ElasticDragButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("FloatingActionMenu", { FloatingActionMenuContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("HoldToConfirmButton", { HoldToConfirmButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("MorphingSubmitButton", { MorphingSubmitButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("PulseRingButton", { PulseRingButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ShrinkingExtendedButton", { ShrinkingExtendedButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
    ]

    @Test(arguments: styles.indices)
    func aLightColorGetsBlack(index: Int) {
        let foreground = Self.styles[index].1

        #expect(foreground(.white) == .black)
        #expect(foreground(.yellow) == .black)
        #expect(foreground(Color(red: 0.8, green: 0.9, blue: 1)) == .black)
    }

    @Test(arguments: styles.indices)
    func aDarkOrSaturatedColorKeepsWhite(index: Int) {
        let foreground = Self.styles[index].1

        #expect(foreground(.black) == .white)
        #expect(foreground(.blue) == .white)
        #expect(foreground(.indigo) == .white)
        #expect(foreground(.red) == .white)
        #expect(foreground(.green) == .white)
        #expect(foreground(.orange) == .white)
    }
}
