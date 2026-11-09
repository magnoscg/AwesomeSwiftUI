// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI
import Testing
@testable import Showcase

@MainActor
struct TabNavigationStatePreserveTests {
    private func path(depth: Int) -> NavigationPath {
        var path = NavigationPath()
        for value in 0..<depth {
            path.append(value)
        }
        return path
    }

    @Test func eachTabKeepsItsOwnPath() {
        let store = TabNavigationStatePreserveStore(selection: "home")

        store.setPath(path(depth: 2), for: "home")
        store.setPath(path(depth: 1), for: "library")

        #expect(store.depth(of: "home") == 2)
        #expect(store.depth(of: "library") == 1)
    }

    @Test func anUnknownTabStartsAtTheRoot() {
        let store = TabNavigationStatePreserveStore(selection: "home")

        #expect(store.depth(of: "never seen") == 0)
    }

    @Test func switchingTabsKeepsThePaths() {
        let store = TabNavigationStatePreserveStore(selection: "home")
        store.setPath(path(depth: 3), for: "home")

        store.select("library")
        store.select("home")

        #expect(store.selection == "home")
        #expect(store.depth(of: "home") == 3)
    }

    @Test func choosingTheCurrentTabPopsToItsRoot() {
        let store = TabNavigationStatePreserveStore(selection: "home")
        store.setPath(path(depth: 3), for: "home")
        store.setPath(path(depth: 2), for: "library")

        store.select("home")

        #expect(store.depth(of: "home") == 0)
        #expect(store.depth(of: "library") == 2)
    }
}
