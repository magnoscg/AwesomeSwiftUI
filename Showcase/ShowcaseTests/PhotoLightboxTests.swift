// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Testing
@testable import Showcase

struct PhotoLightboxTests {
    @Test func aPageStaysInsideTheCollection() {
        #expect(PhotoLightboxMath.clampedPage(9, count: 3) == 2)
        #expect(PhotoLightboxMath.clampedPage(-4, count: 3) == 0)
        #expect(PhotoLightboxMath.clampedPage(1, count: 3) == 1)
    }

    @Test func anEmptyCollectionGivesThePageZero() {
        #expect(PhotoLightboxMath.clampedPage(5, count: 0) == 0)
    }

    @Test func zoomStaysInRange() {
        #expect(PhotoLightboxMath.clampedZoom(0.3, maxZoom: 4) == 1)
        #expect(PhotoLightboxMath.clampedZoom(9, maxZoom: 4) == 4)
        #expect(PhotoLightboxMath.clampedZoom(9, maxZoom: 0) == 1)
    }

    @Test func aPhotoAtFitCannotPan() {
        #expect(PhotoLightboxMath.clampedOffset(CGSize(width: 90, height: 90), zoom: 1, in: CGSize(width: 300, height: 600)) == .zero)
    }

    @Test func aZoomedPhotoPansToItsEdges() {
        let offset = PhotoLightboxMath.clampedOffset(CGSize(width: 900, height: -900), zoom: 2, in: CGSize(width: 300, height: 600))

        #expect(offset == CGSize(width: 150, height: -300))
    }
}
