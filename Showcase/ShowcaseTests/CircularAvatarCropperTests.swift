// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct CircularAvatarCropperTests {
    @Test func theShorterSideMatchesTheWindow() {
        #expect(CircularAvatarCropperTransform.fillSize(aspectRatio: 2) == CGSize(width: 2, height: 1))
        #expect(CircularAvatarCropperTransform.fillSize(aspectRatio: 0.5) == CGSize(width: 1, height: 2))
    }

    @Test(arguments: [CGFloat(0), -3, .infinity, .nan])
    func badAspectRatiosStayFinite(ratio: CGFloat) {
        let fill = CircularAvatarCropperTransform.fillSize(aspectRatio: ratio)

        #expect(fill.width.isFinite)
        #expect(fill.height.isFinite)
    }

    @Test func zoomStaysInRange() {
        let tooSmall = CircularAvatarCropperTransform(zoom: 0.2).clamped(aspectRatio: 1, maxZoom: 4)
        let tooBig = CircularAvatarCropperTransform(zoom: 40).clamped(aspectRatio: 1, maxZoom: 4)

        #expect(tooSmall.zoom == 1)
        #expect(tooBig.zoom == 4)
    }

    @Test func aMaxZoomBelowOneStillGivesAFilledWindow() {
        #expect(CircularAvatarCropperTransform(zoom: 3).clamped(aspectRatio: 1, maxZoom: -2).zoom == 1)
    }

    @Test func theWindowStaysCovered() {
        let transform = CircularAvatarCropperTransform(zoom: 2, offset: CGSize(width: 5, height: -5))

        let clamped = transform.clamped(aspectRatio: 1, maxZoom: 4)

        #expect(clamped.offset == CGSize(width: 0.5, height: -0.5))
    }

    @Test func aSquarePhotoAtZoomOneShowsEverything() {
        let rect = CircularAvatarCropperTransform().normalizedCropRect(aspectRatio: 1)

        #expect(rect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test func movingThePhotoLeftCropsFurtherRight() {
        let transform = CircularAvatarCropperTransform(zoom: 2, offset: CGSize(width: -0.5, height: 0))

        let rect = transform.normalizedCropRect(aspectRatio: 1)

        #expect(rect == CGRect(x: 0.5, y: 0.25, width: 0.5, height: 0.5))
    }
}
