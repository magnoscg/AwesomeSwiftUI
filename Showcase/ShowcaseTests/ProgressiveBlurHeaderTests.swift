// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct ProgressiveBlurHeaderTests {
    @Test func theTopEdgeGetsAllTheBlur() {
        #expect(ProgressiveBlurHeaderMath.strength(at: 0, height: 130) == 1)
        #expect(ProgressiveBlurHeaderMath.strength(at: -40, height: 130) == 1)
    }

    @Test func theBlurIsGoneBelowTheHeader() {
        #expect(ProgressiveBlurHeaderMath.strength(at: 130, height: 130) == 0)
        #expect(ProgressiveBlurHeaderMath.strength(at: 600, height: 130) == 0)
    }

    @Test func halfwayDownGetsHalfTheBlur() {
        #expect(ProgressiveBlurHeaderMath.strength(at: 65, height: 130) == 0.5)
    }

    @Test func theBlurOnlyFadesOnTheWayDown() {
        let strengths = stride(from: 0.0, through: 130, by: 5).map { ProgressiveBlurHeaderMath.strength(at: $0, height: 130) }

        #expect(strengths == strengths.sorted(by: >))
    }

    @Test func aHeaderWithNoHeightBlursNothing() {
        #expect(ProgressiveBlurHeaderMath.strength(at: 10, height: 0) == 0)
        #expect(ProgressiveBlurHeaderMath.strength(at: .nan, height: 130) == 0)
    }

    @Test(arguments: [true, false])
    func theShaderCompilesAsALayerEffect(isHorizontal: Bool) async throws {
        let shader = ProgressiveBlurHeaderMath.shader(top: 40, height: 130, radius: 14, isHorizontal: isHorizontal)

        try await shader.compile(as: .layerEffect)
    }
}
