// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

@MainActor
struct NavigationPathRouterTests {
    private func routerWithDepth(_ depth: Int) -> NavigationPathRouter<Int> {
        let router = NavigationPathRouter<Int>()
        for value in 0..<depth {
            router.push(value)
        }
        return router
    }

    @Test func pushAddsOneScreen() {
        let router = routerWithDepth(2)

        #expect(router.depth == 2)
    }

    @Test func popRemovesTheRequestedScreens() {
        let router = routerWithDepth(3)

        router.pop(2)

        #expect(router.depth == 1)
    }

    @Test func popOnAnEmptyPathDoesNothing() {
        let router = routerWithDepth(0)

        router.pop()

        #expect(router.depth == 0)
    }

    @Test func poppingTooManyStopsAtTheRoot() {
        let router = routerWithDepth(2)

        router.pop(Int.max)

        #expect(router.depth == 0)
    }

    @Test func aNegativePopIsIgnored() {
        let router = routerWithDepth(2)

        router.pop(-3)

        #expect(router.depth == 2)
    }

    @Test func popToRootEmptiesThePath() {
        let router = routerWithDepth(4)

        router.popToRoot()

        #expect(router.depth == 0)
    }
}
