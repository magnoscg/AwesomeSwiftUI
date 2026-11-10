// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import SwiftUI
import Testing
@testable import Showcase

struct SnapCornerDraggableTests {
    private let size = CGSize(width: 400, height: 800)

    @Test func eachQuadrantPicksItsCorner() {
        #expect(SnapCornerDraggableCorner.nearest(to: CGPoint(x: 10, y: 10), in: size) == .topLeading)
        #expect(SnapCornerDraggableCorner.nearest(to: CGPoint(x: 390, y: 10), in: size) == .topTrailing)
        #expect(SnapCornerDraggableCorner.nearest(to: CGPoint(x: 10, y: 790), in: size) == .bottomLeading)
        #expect(SnapCornerDraggableCorner.nearest(to: CGPoint(x: 390, y: 790), in: size) == .bottomTrailing)
    }

    @Test func aFlickPastTheEdgeKeepsItsDirection() {
        #expect(SnapCornerDraggableCorner.nearest(to: CGPoint(x: -900, y: 2000), in: size) == .bottomLeading)
    }

    @Test func anEmptyContainerStillAnswers() {
        #expect(SnapCornerDraggableCorner.nearest(to: .zero, in: .zero) == .bottomTrailing)
    }

    @Test func leadingCornersAreNamedLeftInLeftToRightLayouts() {
        #expect(SnapCornerDraggableCorner.topLeading.title(in: .leftToRight) == "top left")
        #expect(SnapCornerDraggableCorner.topTrailing.title(in: .leftToRight) == "top right")
        #expect(SnapCornerDraggableCorner.bottomLeading.title(in: .leftToRight) == "bottom left")
        #expect(SnapCornerDraggableCorner.bottomTrailing.title(in: .leftToRight) == "bottom right")
    }

    @Test func leadingCornersAreNamedRightInRightToLeftLayouts() {
        #expect(SnapCornerDraggableCorner.topLeading.title(in: .rightToLeft) == "top right")
        #expect(SnapCornerDraggableCorner.topTrailing.title(in: .rightToLeft) == "top left")
        #expect(SnapCornerDraggableCorner.bottomLeading.title(in: .rightToLeft) == "bottom right")
        #expect(SnapCornerDraggableCorner.bottomTrailing.title(in: .rightToLeft) == "bottom left")
    }
}
