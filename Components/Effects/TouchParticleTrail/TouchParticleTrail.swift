// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Leaves a trail of fading particles behind the finger while it drags over the content.
///
/// The content keeps receiving its own touches. With Reduce Motion on, the
/// particles stay where they were left and only fade.
struct TouchParticleTrail<Content: View>: View {
    var colors: [Color] = [.cyan, .purple, .pink]
    var lifetime = 0.9
    @ViewBuilder var content: () -> Content

    @State private var emitter = TouchParticleTrailEmitter()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: emitter.particles.isEmpty)) { context in
                    Canvas { canvas, _ in
                        canvas.blendMode = .plusLighter
                        let palette = colors.isEmpty ? [Color.white] : colors
                        for particle in emitter.particles {
                            guard let frame = particle.frame(at: context.date) else { continue }
                            let color = palette[particle.colorIndex % palette.count]
                            let glow = frame.rect.insetBy(dx: -frame.rect.width * 0.8, dy: -frame.rect.height * 0.8)
                            canvas.fill(Path(ellipseIn: glow), with: .color(color.opacity(frame.opacity * 0.25)))
                            canvas.fill(Path(ellipseIn: frame.rect), with: .color(color.opacity(frame.opacity)))
                        }
                    }
                    .onChange(of: context.date) { _, now in
                        if emitter.isFinished(at: now) { emitter.removeAll() }
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    emitter.emit(at: value.location, now: .now, lifetime: lifetime, drifts: !reduceMotion)
                }
            )
    }
}

struct TouchParticleTrailParticle {
    var position: CGPoint
    var velocity: CGVector
    var birth: Date
    var lifetime: Double
    var size: CGFloat
    var colorIndex: Int

    struct Frame {
        var rect: CGRect
        var opacity: Double
    }

    func isExpired(at now: Date) -> Bool {
        now.timeIntervalSince(birth) >= lifetime
    }

    /// Where the particle is drawn at a given moment, or `nil` once it has faded out.
    func frame(at now: Date) -> Frame? {
        let age = now.timeIntervalSince(birth)
        guard age >= 0, age < lifetime, lifetime > 0 else { return nil }

        let progress = age / lifetime
        let side = size * (1 - progress * 0.6)
        return Frame(
            rect: CGRect(
                x: position.x + velocity.dx * age - side / 2,
                y: position.y + velocity.dy * age - side / 2,
                width: side,
                height: side
            ),
            opacity: 1 - progress
        )
    }
}

struct TouchParticleTrailEmitter {
    private(set) var particles: [TouchParticleTrailParticle] = []
    private var lastPoint: CGPoint?
    private var lastEmission: Date?

    private let capacity = 240
    private let spacing: CGFloat = 9
    private let maximumPerEvent = 16
    private let strokeGap = 0.12

    /// Adds particles between the last point and this one, so a fast drag leaves no gaps.
    ///
    /// A long pause starts a new stroke. That also covers a gesture the system
    /// cancelled, which never reports its end.
    mutating func emit(at point: CGPoint, now: Date, lifetime: Double, drifts: Bool) {
        guard point.x.isFinite, point.y.isFinite else { return }
        let lifetime = max(lifetime, 0.05)
        particles.removeAll { $0.isExpired(at: now) }

        let previous = lastEmission.map { now.timeIntervalSince($0) <= strokeGap } == true ? lastPoint : nil
        lastEmission = now

        var count = 1
        if let previous {
            let distance = hypot(point.x - previous.x, point.y - previous.y)
            guard distance >= spacing else { return }
            count = Int(min(distance / spacing, CGFloat(maximumPerEvent)))
        }

        for step in 1...count {
            let progress = CGFloat(step) / CGFloat(count)
            let position = previous.map {
                CGPoint(x: $0.x + (point.x - $0.x) * progress, y: $0.y + (point.y - $0.y) * progress)
            } ?? point
            particles.append(makeParticle(at: position, now: now, lifetime: lifetime, drifts: drifts))
        }
        lastPoint = point

        if particles.count > capacity {
            particles.removeFirst(particles.count - capacity)
        }
    }

    /// Particles are in birth order and share a lifetime, so the last one is the last to go.
    func isFinished(at now: Date) -> Bool {
        particles.last?.isExpired(at: now) ?? false
    }

    mutating func removeAll() {
        particles.removeAll()
        lastPoint = nil
        lastEmission = nil
    }

    private func makeParticle(
        at position: CGPoint,
        now: Date,
        lifetime: Double,
        drifts: Bool
    ) -> TouchParticleTrailParticle {
        let angle = Double.random(in: 0..<(2 * .pi))
        let speed = drifts ? Double.random(in: 10...70) : 0
        return TouchParticleTrailParticle(
            position: position,
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            birth: now,
            lifetime: lifetime,
            size: .random(in: 7...15),
            colorIndex: .random(in: 0..<1_000)
        )
    }
}

// MARK: - Demo

struct TouchParticleTrailDemo: View {
    var body: some View {
        TouchParticleTrail {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.03, blue: 0.16), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 10) {
                    Image(systemName: "hand.draw.fill")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text("Drag anywhere")
                        .font(.title2.bold())
                }
                .foregroundStyle(.white.opacity(0.75))
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    TouchParticleTrailDemo()
}
