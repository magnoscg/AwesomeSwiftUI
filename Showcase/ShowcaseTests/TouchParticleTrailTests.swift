// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import CoreGraphics
import Foundation
import Testing
@testable import Showcase

struct TouchParticleTrailTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func emitter(
        at points: [CGPoint],
        secondsApart: Double = 0.016,
        lifetime: Double = 1,
        drifts: Bool = true
    ) -> TouchParticleTrailEmitter {
        var emitter = TouchParticleTrailEmitter()
        for (index, point) in points.enumerated() {
            emitter.emit(
                at: point,
                now: start.addingTimeInterval(Double(index) * secondsApart),
                lifetime: lifetime,
                drifts: drifts
            )
        }
        return emitter
    }

    @Test func theFirstTouchLeavesOneParticle() {
        #expect(emitter(at: [CGPoint(x: 10, y: 10)]).particles.count == 1)
    }

    @Test func aFastDragFillsTheGap() {
        let trail = emitter(at: [.zero, CGPoint(x: 90, y: 0)])

        #expect(trail.particles.count == 11)
    }

    @Test func aVeryLongJumpIsLimited() {
        let trail = emitter(at: [.zero, CGPoint(x: 90_000, y: 0)])

        #expect(trail.particles.count == 17)
    }

    @Test func aTinyMoveAddsNothing() {
        let trail = emitter(at: [.zero, CGPoint(x: 2, y: 1)])

        #expect(trail.particles.count == 1)
    }

    @Test func aLongPauseStartsANewStroke() {
        let trail = emitter(at: [.zero, CGPoint(x: 300, y: 0)], secondsApart: 0.5)

        #expect(trail.particles.count == 2)
    }

    @Test func invalidPointsAreIgnored() {
        let trail = emitter(at: [CGPoint(x: CGFloat.nan, y: 0), CGPoint(x: 0, y: CGFloat.infinity)])

        #expect(trail.particles.isEmpty)
    }

    @Test func theParticleCountIsCapped() {
        let points = (0..<200).map { CGPoint(x: CGFloat($0) * 60, y: 0) }

        #expect(emitter(at: points).particles.count == 240)
    }

    @Test func expiredParticlesAreRemovedOnTheNextEmission() {
        var trail = emitter(at: [.zero], lifetime: 0.1)

        trail.emit(at: CGPoint(x: 400, y: 400), now: start.addingTimeInterval(1), lifetime: 0.1, drifts: true)

        #expect(trail.particles.count == 1)
    }

    @Test func itFinishesWhenTheNewestParticleExpires() {
        let trail = emitter(at: [.zero], lifetime: 0.5)

        #expect(!trail.isFinished(at: start.addingTimeInterval(0.4)))
        #expect(trail.isFinished(at: start.addingTimeInterval(0.6)))
    }

    @Test func anEmptyTrailIsNotFinished() {
        #expect(!TouchParticleTrailEmitter().isFinished(at: start))
    }

    @Test func withoutDriftParticlesStayInPlace() throws {
        let trail = emitter(at: [CGPoint(x: 50, y: 60)], drifts: false)

        let particle = try #require(trail.particles.first)
        let frame = try #require(particle.frame(at: start.addingTimeInterval(0.5)))

        #expect(abs(frame.rect.midX - 50) < 0.001)
        #expect(abs(frame.rect.midY - 60) < 0.001)
    }

    @Test func aParticleFadesAndThenHasNoFrame() throws {
        let trail = emitter(at: [.zero], lifetime: 1)
        let particle = try #require(trail.particles.first)

        let young = try #require(particle.frame(at: start.addingTimeInterval(0.1)))
        let old = try #require(particle.frame(at: start.addingTimeInterval(0.9)))

        #expect(old.opacity < young.opacity)
        #expect(particle.frame(at: start.addingTimeInterval(1.1)) == nil)
        #expect(particle.frame(at: start.addingTimeInterval(-1)) == nil)
    }

    @Test func aZeroLifetimeStillLivesBriefly() throws {
        let trail = emitter(at: [.zero], lifetime: 0)
        let particle = try #require(trail.particles.first)

        #expect(particle.lifetime > 0)
    }

    @Test func liftingTheFingerStartsANewStroke() {
        var trail = emitter(at: [.zero])

        trail.endStroke()
        trail.emit(at: CGPoint(x: 90, y: 0), now: start.addingTimeInterval(0.05), lifetime: 1, drifts: true)

        #expect(trail.particles.count == 2)
    }
}
