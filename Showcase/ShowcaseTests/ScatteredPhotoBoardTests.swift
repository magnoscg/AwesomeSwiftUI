// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ScatteredPhotoBoardTests {
    private let card = CGSize(width: 100, height: 120)
    private let board = CGSize(width: 400, height: 800)

    @Test func placementIsRepeatable() {
        let first = ScatteredPhotoBoardLayout.center(index: 3, count: 8, card: card, board: board)
        let second = ScatteredPhotoBoardLayout.center(index: 3, count: 8, card: card, board: board)

        #expect(first == second)
    }

    @Test(arguments: 0..<12)
    func everyCardStartsOnTheBoard(index: Int) {
        let center = ScatteredPhotoBoardLayout.center(index: index, count: 12, card: card, board: board)

        #expect(center.x >= 50 && center.x <= 350)
        #expect(center.y >= 60 && center.y <= 740)
    }

    @Test(arguments: 0..<12)
    func anglesAreSlight(index: Int) {
        #expect(abs(ScatteredPhotoBoardLayout.angle(index: index)) <= 9)
    }

    @Test func aDraggedCardStopsAtTheEdge() {
        let point = ScatteredPhotoBoardLayout.clamped(CGPoint(x: -500, y: 9000), card: card, board: board)

        #expect(point == CGPoint(x: 50, y: 740))
    }

    @Test func aCardBiggerThanTheBoardIsCentered() {
        let point = ScatteredPhotoBoardLayout.clamped(CGPoint(x: 900, y: 900), card: CGSize(width: 500, height: 900), board: board)

        #expect(point == CGPoint(x: 200, y: 400))
    }

    @Test func emptyInputsDoNotCrash() {
        #expect(ScatteredPhotoBoardLayout.center(index: 0, count: 0, card: card, board: board) == CGPoint(x: 200, y: 400))
        #expect(ScatteredPhotoBoardLayout.center(index: 2, count: 5, card: card, board: .zero) == .zero)
    }

    @Test func aDragPastTheEdgeKeepsNoHiddenDistance() {
        let wide = CGSize(width: 150, height: 180)
        let home = CGPoint(x: 206, y: 400)
        let saved = ScatteredPhotoBoardLayout.settledOffset(home: home, saved: .zero, translation: CGSize(width: 180, height: 0), card: wide, board: board)

        let next = ScatteredPhotoBoardLayout.settledOffset(home: home, saved: saved, translation: CGSize(width: -40, height: 0), card: wide, board: board)

        #expect(saved.width == 119)
        #expect(home.x + next.width == 285)
    }
}
