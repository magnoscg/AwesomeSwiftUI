// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct AsyncActionButtonTests {
    @Test func theFirstTapStartsTheAction() {
        var run = AsyncActionButtonRun()

        let started = run.start()

        #expect(started)
        #expect(run.isRunning)
    }

    @Test func aTapWhileTheActionRunsIsIgnored() {
        var run = AsyncActionButtonRun()
        _ = run.start()

        let startedAgain = run.start()

        #expect(!startedAgain)
        #expect(run.isRunning)
    }

    @Test func aTapAfterTheActionEndsStartsItAgain() {
        var run = AsyncActionButtonRun()
        _ = run.start()
        run.finish()

        let startedAgain = run.start()

        #expect(startedAgain)
    }
}
