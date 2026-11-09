// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

@MainActor
private final class LoadMoreFooterFetchLog {
    var calls = 0
}

private struct LoadMoreFooterTestError: Error {}

@MainActor
@Suite struct LoadMoreFooterTests {
    private func makePager(lastPage: Int, log: LoadMoreFooterFetchLog) -> LoadMoreFooterPager<Int> {
        LoadMoreFooterPager { page in
            log.calls += 1
            await Task.yield()
            return LoadMoreFooterPage(elements: [page], hasMore: page < lastPage)
        }
    }

    @Test func appendsPagesInOrderAndReturnsToIdle() async {
        let log = LoadMoreFooterFetchLog()
        let pager = makePager(lastPage: 3, log: log)

        await pager.loadNextPage()
        await pager.loadNextPage()

        #expect(pager.elements == [0, 1])
        #expect(pager.phase == .idle)
    }

    @Test func ignoresARequestWhileOneIsRunning() async {
        let log = LoadMoreFooterFetchLog()
        let pager = makePager(lastPage: 3, log: log)

        async let first: Void = pager.loadNextPage()
        async let second: Void = pager.loadNextPage()
        _ = await (first, second)

        #expect(log.calls == 1)
        #expect(pager.elements == [0])
    }

    @Test func stopsAfterTheLastPage() async {
        let log = LoadMoreFooterFetchLog()
        let pager = makePager(lastPage: 0, log: log)

        await pager.loadNextPage()
        await pager.loadNextPage()

        #expect(pager.phase == .finished)
        #expect(log.calls == 1)
    }

    @Test func anEmptyPageFinishesEvenIfItClaimsMore() async {
        let pager = LoadMoreFooterPager<Int> { _ in
            LoadMoreFooterPage(elements: [], hasMore: true)
        }

        await pager.loadNextPage()

        #expect(pager.phase == .finished)
    }

    @Test func aFailureCanBeRetried() async {
        let log = LoadMoreFooterFetchLog()
        let pager = LoadMoreFooterPager<Int> { page in
            log.calls += 1
            if log.calls == 1 { throw LoadMoreFooterTestError() }
            return LoadMoreFooterPage(elements: [page], hasMore: false)
        }

        await pager.loadNextPage()
        let phaseAfterFailure = pager.phase
        await pager.loadNextPage()

        #expect(phaseAfterFailure == .failed)
        #expect(pager.elements == [0])
        #expect(pager.phase == .finished)
    }
}
