// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct AddToCartFlyButtonTests {
    private let destination = CGSize(width: 100, height: -200)

    @Test func theArcStartsAtZeroAndEndsOnTheCart() {
        #expect(AddToCartFlyButtonLogic.arcOffset(progress: 0, destination: destination, lift: 80) == .zero)
        #expect(AddToCartFlyButtonLogic.arcOffset(progress: 1, destination: destination, lift: 80) == destination)
    }

    @Test func theArcRisesAboveTheStraightLine() {
        let halfway = AddToCartFlyButtonLogic.arcOffset(progress: 0.5, destination: destination, lift: 80)

        #expect(halfway.height < destination.height / 2)
    }

    @Test(arguments: [(-3.0, 0.0), (5.0, 1.0)] as [(Double, Double)])
    func progressIsClamped(progress: Double, clamped: Double) {
        let result = AddToCartFlyButtonLogic.arcOffset(progress: progress, destination: destination, lift: 80)

        #expect(result == AddToCartFlyButtonLogic.arcOffset(progress: clamped, destination: destination, lift: 80))
    }
}
