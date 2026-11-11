// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

struct DissolveShaderTransitionTests {
    @Test func aWholeViewHasNoPixelNearTheThreshold() {
        let threshold = DissolveShaderTransitionMath.threshold(progress: 0)

        #expect(threshold + DissolveShaderTransitionMath.edgeWidth <= 0)
    }

    @Test func aDissolvedViewHasEveryPixelUnderTheThreshold() {
        #expect(DissolveShaderTransitionMath.threshold(progress: 1) == 1)
    }

    @Test func theThresholdRisesWithTheProgress() {
        let thresholds = stride(from: 0.0, through: 1.0, by: 0.1).map(DissolveShaderTransitionMath.threshold)

        #expect(thresholds == thresholds.sorted())
        #expect(Set(thresholds).count == thresholds.count)
    }

    @Test(arguments: [(-0.4, 0.0), (1.3, 1.0)])
    func aSpringThatOvershootsStaysInRange(progress: Double, limit: Double) {
        let threshold = DissolveShaderTransitionMath.threshold(progress: progress)

        #expect(threshold == DissolveShaderTransitionMath.threshold(progress: limit))
    }

    @Test func theShaderCompilesAsAColorEffect() async throws {
        let shader = DissolveShaderTransitionMath.shader(progress: 0.5, grain: 44, edge: .orange)

        try await shader.compile(as: .colorEffect)
    }
}
