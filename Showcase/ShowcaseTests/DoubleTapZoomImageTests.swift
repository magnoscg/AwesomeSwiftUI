// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct DoubleTapZoomImageTests {
    private let size = CGSize(width: 300, height: 400)

    @Test func tappingTheCenterNeedsNoOffset() {
        #expect(DoubleTapZoomImageMath.offset(centering: CGPoint(x: 150, y: 200), zoom: 2, in: size) == .zero)
    }

    @Test func aPointNearTheCenterMovesToTheCenter() {
        let offset = DoubleTapZoomImageMath.offset(centering: CGPoint(x: 100, y: 250), zoom: 2, in: size)

        #expect(offset == CGSize(width: 100, height: -100))
    }

    @Test func aCornerIsLimitedByTheImageEdges() {
        let offset = DoubleTapZoomImageMath.offset(centering: .zero, zoom: 2, in: size)

        #expect(offset == CGSize(width: 150, height: 200))
    }

    @Test func atFitNothingCanMove() {
        #expect(DoubleTapZoomImageMath.clampedOffset(CGSize(width: 80, height: -80), zoom: 1, in: size) == .zero)
    }

    @Test func zoomsBelowOneAndEmptySizesDoNotCrash() {
        #expect(DoubleTapZoomImageMath.clampedOffset(CGSize(width: 80, height: 80), zoom: 0.2, in: size) == .zero)
        #expect(DoubleTapZoomImageMath.clampedOffset(CGSize(width: 80, height: 80), zoom: 3, in: .zero) == .zero)
    }
}
