// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import SwiftUI
import Testing
@testable import Showcase

struct TooltipPopoverTests {
    private let container = CGSize(width: 400, height: 800)

    @Test func anAnchorLowOnTheScreenOpensAbove() {
        let anchor = CGRect(x: 100, y: 700, width: 40, height: 40)

        #expect(TooltipPopoverGeometry.opensAbove(anchor: anchor, container: container))
    }

    @Test func anAnchorHighOnTheScreenOpensBelow() {
        let anchor = CGRect(x: 100, y: 40, width: 40, height: 40)

        #expect(!TooltipPopoverGeometry.opensAbove(anchor: anchor, container: container))
    }

    @Test func theBubbleIsCenteredOnItsAnchor() {
        let anchor = CGRect(x: 180, y: 300, width: 40, height: 40)

        let frames = TooltipPopoverGeometry.frames(
            anchor: anchor,
            bubble: CGSize(width: 100, height: 50),
            container: container,
            opensAbove: true
        )

        #expect(frames.bubble.midX == anchor.midX)
        #expect(frames.bubble.maxY == anchor.minY - TooltipPopoverGeometry.arrowSize.height)
        #expect(frames.arrow.maxY == anchor.minY)
    }

    @Test func aBubbleBelowStartsUnderItsArrow() {
        let anchor = CGRect(x: 180, y: 300, width: 40, height: 40)

        let frames = TooltipPopoverGeometry.frames(
            anchor: anchor,
            bubble: CGSize(width: 100, height: 50),
            container: container,
            opensAbove: false
        )

        #expect(frames.arrow.minY == anchor.maxY)
        #expect(frames.bubble.minY == frames.arrow.maxY)
    }

    @Test(arguments: [CGFloat(0), 380])
    func theBubbleStaysOnScreenAndTheArrowStaysOnTheBubble(anchorX: CGFloat) {
        let anchor = CGRect(x: anchorX, y: 300, width: 20, height: 20)

        let frames = TooltipPopoverGeometry.frames(
            anchor: anchor,
            bubble: CGSize(width: 200, height: 50),
            container: container,
            opensAbove: true
        )

        #expect(frames.bubble.minX >= TooltipPopoverGeometry.margin)
        #expect(frames.bubble.maxX <= container.width - TooltipPopoverGeometry.margin)
        #expect(frames.arrow.minX >= frames.bubble.minX)
        #expect(frames.arrow.maxX <= frames.bubble.maxX)
    }

    @Test func aBubbleWiderThanTheScreenKeepsItsMargin() {
        let frames = TooltipPopoverGeometry.frames(
            anchor: CGRect(x: 100, y: 300, width: 20, height: 20),
            bubble: CGSize(width: 900, height: 50),
            container: container,
            opensAbove: true
        )

        #expect(frames.bubble.minX == TooltipPopoverGeometry.margin)
    }

    @Test func availableSpaceRespectsTheWidthAndTheScreen() {
        let anchor = CGRect(x: 100, y: 300, width: 20, height: 20)

        let room = TooltipPopoverGeometry.available(anchor: anchor, container: container, opensAbove: true, maximumWidth: 260)
        let narrow = TooltipPopoverGeometry.available(anchor: anchor, container: CGSize(width: 100, height: 800), opensAbove: true, maximumWidth: 260)

        #expect(room.width == 260)
        #expect(room.height == 300 - TooltipPopoverGeometry.arrowSize.height - TooltipPopoverGeometry.margin)
        #expect(narrow.width == 100 - TooltipPopoverGeometry.margin * 2)
    }

    @Test func noRoomNeverGoesNegative() {
        let room = TooltipPopoverGeometry.available(
            anchor: CGRect(x: 0, y: 2, width: 20, height: 20),
            container: CGSize(width: 10, height: 30),
            opensAbove: true,
            maximumWidth: 260
        )

        #expect(room == .zero)
    }

    @Test func theArrowTipOfAnEmptyContainerIsTheCenter() {
        let tip = TooltipPopoverGeometry.arrowTip(anchor: .zero, container: .zero, opensAbove: true)

        #expect(tip == .center)
    }

    @Test func theArrowTipIsAFractionOfTheContainer() {
        let anchor = CGRect(x: 180, y: 380, width: 40, height: 40)

        let tip = TooltipPopoverGeometry.arrowTip(anchor: anchor, container: container, opensAbove: false)

        #expect(tip.x == 0.5)
        #expect(abs(tip.y - 420.0 / 800.0) < 0.0001)
    }
}
