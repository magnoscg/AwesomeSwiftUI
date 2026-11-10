// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct ToastHostTests {
    @Test func theFirstToastIsTheOneOnScreen() {
        var queue = ToastHostQueue()

        queue.add(ToastHostToast(message: "Saved"))
        queue.add(ToastHostToast(message: "Copied"))

        #expect(queue.current?.message == "Saved")
    }

    @Test func removingTheCurrentToastShowsTheNext() throws {
        var queue = ToastHostQueue()
        queue.add(ToastHostToast(message: "Saved"))
        queue.add(ToastHostToast(message: "Copied"))

        queue.remove(id: try #require(queue.current).id)

        #expect(queue.current?.message == "Copied")
    }

    @Test func anEmptyQueueShowsNothing() throws {
        var queue = ToastHostQueue()
        queue.add(ToastHostToast(message: "Saved"))

        queue.remove(id: try #require(queue.current).id)

        #expect(queue.current == nil)
    }

    @Test func theSameToastTwiceInARowIsAddedOnce() {
        var queue = ToastHostQueue()

        queue.add(ToastHostToast(message: "Saved", role: .success))
        queue.add(ToastHostToast(message: "Saved", role: .success))

        #expect(queue.toasts.count == 1)
    }

    @Test func theSameWordsWithAnotherRoleAreAnotherToast() {
        var queue = ToastHostQueue()

        queue.add(ToastHostToast(message: "Sync", role: .info))
        queue.add(ToastHostToast(message: "Sync", role: .error))
        queue.add(ToastHostToast(message: "Sync", role: .info))

        #expect(queue.toasts.count == 3)
    }

    @Test func aFullQueueDropsTheOldestWaitingToast() {
        var queue = ToastHostQueue(limit: 2)

        for message in ["One", "Two", "Three", "Four"] {
            queue.add(ToastHostToast(message: message))
        }

        #expect(queue.toasts.map(\.message) == ["One", "Three", "Four"])
    }

    @Test func aQueueWithNoRoomKeepsOnlyTheToastOnScreen() {
        var queue = ToastHostQueue(limit: 0)

        queue.add(ToastHostToast(message: "One"))
        queue.add(ToastHostToast(message: "Two"))

        #expect(queue.toasts.map(\.message) == ["One"])
    }

    @Test func removingAnUnknownToastChangesNothing() {
        var queue = ToastHostQueue()
        queue.add(ToastHostToast(message: "Saved"))

        queue.remove(id: ToastHostToast(message: "Other").id)

        #expect(queue.toasts.count == 1)
    }

    @Test func everyRoleHasItsOwnSymbol() {
        let symbols = [ToastHostRole.info, .success, .warning, .error].map(\.symbol)

        #expect(Set(symbols).count == 4)
    }
}
