// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct ImageDerivedGradientBackgroundTests {
    @Test func averagesEachBandFromTopToBottom() throws {
        let pixels: [UInt8] = [255, 0, 0, 255, 0, 0, 255, 255]

        let bands = ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: 1, height: 2, count: 2)

        #expect(bands.count == 2)
        #expect(try #require(bands.first).red == 1)
        #expect(try #require(bands.last).blue == 1)
    }

    @Test func undoesPremultipliedAlpha() throws {
        let pixels: [UInt8] = [128, 0, 0, 128]

        let bands = ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: 1, height: 1, count: 1)

        #expect(try #require(bands.first).red == 1)
    }

    @Test func saturatedPixelsWeighMoreThanGrey() throws {
        let pixels: [UInt8] = [255, 0, 0, 255, 128, 128, 128, 255]

        let bands = ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: 2, height: 1, count: 1)

        #expect(try #require(bands.first).red > 0.85)
    }

    @Test func transparentBandsAreLeftOut() {
        let pixels: [UInt8] = [0, 0, 0, 0, 10, 20, 30, 255]

        #expect(ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: 1, height: 2, count: 2).count == 1)
    }

    @Test func moreBandsThanRowsAreCapped() {
        let pixels: [UInt8] = [255, 0, 0, 255]

        #expect(ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: 1, height: 1, count: 9).count == 1)
    }

    @Test(arguments: [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1), (2, 1, 1), (Int.max, Int.max, 1)] as [(Int, Int, Int)])
    func invalidInputGivesNothing(width: Int, height: Int, count: Int) {
        let pixels: [UInt8] = [255, 0, 0, 255]

        #expect(ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: width, height: height, count: count).isEmpty)
    }
}
