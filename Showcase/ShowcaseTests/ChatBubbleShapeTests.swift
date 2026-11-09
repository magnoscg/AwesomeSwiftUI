// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import SwiftUI
import Testing
@testable import Showcase

struct ChatBubbleShapeTests {
    @Test func runsOfASenderAreGrouped() {
        let positions = ChatBubbleShapeLogic.positions(for: ["a", "b", "b", "b", "a", "a"])

        #expect(positions == [.single, .first, .middle, .last, .first, .last])
    }

    @Test func emptyAndSingleConversationsAreSafe() {
        #expect(ChatBubbleShapeLogic.positions(for: [String]()).isEmpty)
        #expect(ChatBubbleShapeLogic.positions(for: ["a"]) == [.single])
    }

    @Test func onlyTheEndOfARunHasATail() {
        #expect(ChatBubbleShapeLogic.hasTail(.single))
        #expect(ChatBubbleShapeLogic.hasTail(.last))
        #expect(!ChatBubbleShapeLogic.hasTail(.first))
        #expect(!ChatBubbleShapeLogic.hasTail(.middle))
    }

    @Test func cornersTightenWhereMessagesTouch() {
        let middle = ChatBubbleShapeLogic.radii(for: .middle, radius: 18, tightRadius: 4)
        let first = ChatBubbleShapeLogic.radii(for: .first, radius: 18, tightRadius: 4)

        #expect(middle.topTrailing == 4)
        #expect(middle.bottomTrailing == 4)
        #expect(middle.topLeading == 18)
        #expect(first.topTrailing == 18)
        #expect(first.bottomTrailing == 4)
    }

    @Test(arguments: [CGRect.zero, CGRect(x: 0, y: 0, width: 10, height: 0)])
    func anEmptyRectHasNoPath(rect: CGRect) {
        #expect(ChatBubbleShape().path(in: rect).isEmpty)
    }

    @Test func aTinyRectStillBuildsAPath() {
        let path = ChatBubbleShape(position: .last, radius: 500).path(in: CGRect(x: 0, y: 0, width: 4, height: 4))

        #expect(!path.isEmpty)
    }
}
