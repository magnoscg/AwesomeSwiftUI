// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct PagedGridLauncherTests {
    @Test func noItemsMeansNoPages() {
        #expect(PagedGridLauncherLayout.pages(itemCount: 0, columns: 4, rows: 5).isEmpty)
    }

    @Test func fullPagesThenTheRemainder() {
        #expect(PagedGridLauncherLayout.pages(itemCount: 46, columns: 4, rows: 5) == [0..<20, 20..<40, 40..<46])
    }

    @Test func anExactFitHasNoEmptyPage() {
        #expect(PagedGridLauncherLayout.pages(itemCount: 40, columns: 4, rows: 5) == [0..<20, 20..<40])
    }

    @Test func zeroOrNegativeSizesPutOneItemPerPage() {
        #expect(PagedGridLauncherLayout.pages(itemCount: 2, columns: 0, rows: -3) == [0..<1, 1..<2])
    }

    @Test func extremeSizesDoNotOverflow() {
        #expect(PagedGridLauncherLayout.pages(itemCount: 7, columns: .max, rows: .max) == [0..<7])
    }
}
