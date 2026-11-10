// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI
import Testing
@testable import Showcase

struct PixelateShaderEffectTests {
    @Test func noPixelationLeavesBlocksOfOnePoint() {
        #expect(PixelateShaderEffectMath.blockSize(amount: 0, maximum: 22) == 1)
    }

    @Test func fullPixelationUsesTheBiggestBlocks() {
        #expect(PixelateShaderEffectMath.blockSize(amount: 1, maximum: 22) == 22)
    }

    @Test func blocksGrowWithTheAmount() {
        #expect(PixelateShaderEffectMath.blockSize(amount: 0.5, maximum: 21) == 11)
        #expect(PixelateShaderEffectMath.blockSize(amount: 0.8, maximum: 22) > PixelateShaderEffectMath.blockSize(amount: 0.3, maximum: 22))
    }

    @Test func anAmountOutsideItsRangeIsClamped() {
        #expect(PixelateShaderEffectMath.blockSize(amount: 3, maximum: 22) == 22)
        #expect(PixelateShaderEffectMath.blockSize(amount: -1, maximum: 22) == 1)
        #expect(PixelateShaderEffectMath.blockSize(amount: .nan, maximum: 22) == 1)
        #expect(PixelateShaderEffectMath.blockSize(amount: 1, maximum: 0) == 1)
    }

    @Test func everyPointOfABlockTakesItsCenter() {
        let center = CGPoint(x: 30, y: 50)

        #expect(PixelateShaderEffectMath.blockCenter(of: CGPoint(x: 20, y: 40), size: 20) == center)
        #expect(PixelateShaderEffectMath.blockCenter(of: CGPoint(x: 39.9, y: 59.9), size: 20) == center)
        #expect(PixelateShaderEffectMath.blockCenter(of: CGPoint(x: 31, y: 44), size: 20) == center)
    }

    @Test func theNextBlockHasAnotherCenter() {
        #expect(PixelateShaderEffectMath.blockCenter(of: CGPoint(x: 40, y: 40), size: 20) == CGPoint(x: 50, y: 50))
    }

    @Test func blocksOfOnePointChangeNothing() {
        let point = CGPoint(x: 12.3, y: 45.6)

        #expect(PixelateShaderEffectMath.blockCenter(of: point, size: 1) == point)
    }

    @Test func theShaderCompilesAsALayerEffect() async throws {
        try await PixelateShaderEffectMath.shader(size: 22, bounds: CGSize(width: 300, height: 200)).compile(as: .layerEffect)
    }
}
