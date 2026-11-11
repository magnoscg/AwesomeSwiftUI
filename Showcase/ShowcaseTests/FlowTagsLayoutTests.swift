// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

struct FlowTagsLayoutTests {
    @Test func noTagsGiveNoLines() {
        #expect(FlowTagsLayoutMath.lines(widths: [], maxWidth: 100, spacing: 8).isEmpty)
    }

    @Test func tagsThatFitShareALine() {
        #expect(FlowTagsLayoutMath.lines(widths: [40, 40], maxWidth: 100, spacing: 8) == [0..<2])
    }

    @Test func anExactFitStaysOnTheLine() {
        #expect(FlowTagsLayoutMath.lines(widths: [46, 46], maxWidth: 100, spacing: 8) == [0..<2])
    }

    @Test func spacingCanForceABreak() {
        #expect(FlowTagsLayoutMath.lines(widths: [50, 50], maxWidth: 100, spacing: 8) == [0..<1, 1..<2])
    }

    @Test func tagsWrapOntoSeveralLines() {
        let lines = FlowTagsLayoutMath.lines(widths: [60, 30, 60, 20, 90], maxWidth: 100, spacing: 8)

        #expect(lines == [0..<2, 2..<4, 4..<5])
    }

    @Test func anOversizedTagGetsItsOwnLine() {
        let lines = FlowTagsLayoutMath.lines(widths: [30, 200, 30], maxWidth: 100, spacing: 8)

        #expect(lines == [0..<1, 1..<2, 2..<3])
    }

    @MainActor
    @Test func aTagWiderThanTheLayoutTakesItsWrappedHeight() throws {
        let text = "A long tag that certainly has to wrap across several lines"
        let layout = ImageRenderer(content: FlowTagsLayout { Text(text) }.frame(width: 100))
        let plain = ImageRenderer(content: Text(text).frame(width: 100))

        let layoutHeight = try #require(layout.uiImage).size.height
        let plainHeight = try #require(plain.uiImage).size.height

        #expect(layoutHeight == plainHeight)
    }

    @Test func unlimitedWidthKeepsOneLine() {
        #expect(FlowTagsLayoutMath.lines(widths: [500, 500, 500], maxWidth: .infinity, spacing: 8) == [0..<3])
    }
}
