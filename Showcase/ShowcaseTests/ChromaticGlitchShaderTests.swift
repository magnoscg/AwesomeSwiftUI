// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

struct ChromaticGlitchShaderTests {
    private typealias Math = ChromaticGlitchShaderMath

    @Test func theAmountStaysBetweenZeroAndOne() {
        #expect(Math.clamped(0.4) == 0.4)
        #expect(Math.clamped(-2) == 0)
        #expect(Math.clamped(7) == 1)
        #expect(Math.clamped(.nan) == 0)
    }

    @Test func theShaderReadsNoFartherThanItMoves() {
        #expect(Math.reach(amount: 0) == 0)
        #expect(Math.reach(amount: 1) == Math.split + Math.shift)
        #expect(Math.reach(amount: 0.5) == (Math.split + Math.shift) / 2)
    }

    @Test func theShaderCompilesAsALayerEffect() async throws {
        try await Math.shader(amount: 1, time: 3, bounds: CGSize(width: 300, height: 200)).compile(as: .layerEffect)
    }
}
