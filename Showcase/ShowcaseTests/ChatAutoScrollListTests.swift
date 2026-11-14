// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ChatAutoScrollListTests {
    @Test func beingNearTheEndCountsAsTheBottom() {
        #expect(ChatAutoScrollListLogic.isAtBottom(visibleMaxY: 980, contentHeight: 1_000))
        #expect(!ChatAutoScrollListLogic.isAtBottom(visibleMaxY: 900, contentHeight: 1_000))
    }

    @Test func contentShorterThanTheScreenIsAtTheBottom() {
        #expect(ChatAutoScrollListLogic.isAtBottom(visibleMaxY: 800, contentHeight: 200))
    }

    @Test func leavingTheBottomByItselfKeepsFollowing() {
        var state = ChatAutoScrollListFollowState()

        state.scrolled(isAtBottom: false, isUserDriven: false)

        #expect(state.isFollowing)
    }

    @Test func scrollingUpStopsFollowing() {
        var state = ChatAutoScrollListFollowState()

        state.scrolled(isAtBottom: false, isUserDriven: true)

        #expect(!state.isFollowing)
    }

    @Test func messagesWhileReadingAreFlagged() {
        var state = ChatAutoScrollListFollowState()
        state.scrolled(isAtBottom: false, isUserDriven: true)

        state.messageArrived()

        #expect(state.hasNewMessages)
    }

    @Test func messagesWhileFollowingAreNotFlagged() {
        var state = ChatAutoScrollListFollowState()

        state.messageArrived()

        #expect(!state.hasNewMessages)
    }

    @Test func reachingTheBottomResumesFollowing() {
        var state = ChatAutoScrollListFollowState()
        state.scrolled(isAtBottom: false, isUserDriven: true)
        state.messageArrived()

        state.scrolled(isAtBottom: true, isUserDriven: true)

        #expect(state.isFollowing)
        #expect(!state.hasNewMessages)
    }
}
