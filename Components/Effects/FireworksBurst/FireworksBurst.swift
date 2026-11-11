// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum FireworksBurstMath {
    enum Stage: Equatable {
        case climbing(Double)
        case bursting(Double)
        case finished
    }

    static let climbDuration = 0.65
    static let burstDuration = 1.5
    static var lifetime: Double { climbDuration + burstDuration }

    /// Where a rocket is in its life. Without a climb, it bursts as soon as it is launched.
    static func stage(elapsed: Double, skipsClimb: Bool = false) -> Stage {
        let afterClimb = skipsClimb ? max(elapsed, 0) : elapsed - climbDuration

        if !skipsClimb, afterClimb < 0 {
            return .climbing(min(max(elapsed / climbDuration, 0), 1))
        }
        return afterClimb < burstDuration ? .bursting(afterClimb / burstDuration) : .finished
    }

    /// A spark races outward, slows down and then droops under gravity.
    static func sparkOffset(angle: Double, speed: CGFloat, progress: Double) -> CGSize {
        let travel = speed * (1 - pow(1 - progress, 3))
        return CGSize(
            width: travel * cos(angle),
            height: travel * sin(angle) + 70 * progress * progress
        )
    }
}

private struct FireworksBurstSpark {
    let angle: Double
    let speed: CGFloat
    let size: CGFloat
}

private struct FireworksBurstRocket: Identifiable {
    let id = UUID()
    let launchDate: Date
    let start: CGPoint
    let target: CGPoint
    let color: Color
    let sparks: [FireworksBurstSpark]
}

/// Rockets that climb to where you tap and explode into sparks.
///
/// With Reduce Motion on, each burst appears in place and fades without moving.
struct FireworksBurst: View {
    var sparkCount: Int = 64
    var colors: [Color] = [.pink, .orange, .yellow, .mint, .cyan, .purple]

    @State private var rockets: [FireworksBurstRocket] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maximumRockets = 12

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: rockets.isEmpty)) { timeline in
                Canvas { context, _ in
                    context.blendMode = .plusLighter
                    for rocket in rockets {
                        draw(rocket, at: timeline.date, in: context)
                    }
                }
            }
            .contentShape(.rect)
            .gesture(
                SpatialTapGesture().onEnded { launch(to: $0.location, groundY: proxy.size.height) }
            )
            .accessibilityElement()
            .accessibilityLabel("Night sky")
            .accessibilityHint("Launches a firework")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                launch(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 3), groundY: proxy.size.height)
            }
        }
        .task(id: rockets.last?.id) {
            guard !rockets.isEmpty else { return }

            try? await Task.sleep(for: .seconds(FireworksBurstMath.lifetime + 0.1))
            guard !Task.isCancelled else { return }

            let now = Date.now
            rockets.removeAll { now.timeIntervalSince($0.launchDate) >= FireworksBurstMath.lifetime }
        }
    }

    private func launch(to target: CGPoint, groundY: CGFloat) {
        let count = min(max(sparkCount, 1), 300)
        let sparks = (0..<count).map { index in
            FireworksBurstSpark(
                angle: Double(index) / Double(count) * 2 * .pi + .random(in: -0.08...0.08),
                speed: .random(in: 70...170),
                size: .random(in: 1.5...3.5)
            )
        }

        rockets.append(
            FireworksBurstRocket(
                launchDate: .now,
                start: CGPoint(x: target.x + .random(in: -24...24), y: groundY),
                target: target,
                color: colors.randomElement() ?? .white,
                sparks: sparks
            )
        )
        if rockets.count > maximumRockets {
            rockets.removeFirst(rockets.count - maximumRockets)
        }
    }

    private func draw(_ rocket: FireworksBurstRocket, at date: Date, in context: GraphicsContext) {
        let elapsed = date.timeIntervalSince(rocket.launchDate)

        switch FireworksBurstMath.stage(elapsed: elapsed, skipsClimb: reduceMotion) {
        case .climbing(let progress):
            let eased = 1 - (1 - progress) * (1 - progress)
            let head = CGPoint(
                x: rocket.start.x + (rocket.target.x - rocket.start.x) * eased,
                y: rocket.start.y + (rocket.target.y - rocket.start.y) * eased
            )
            var trail = Path()
            trail.move(to: CGPoint(x: head.x, y: head.y + 26))
            trail.addLine(to: head)
            context.stroke(trail, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        case .bursting(let progress):
            let shading = GraphicsContext.Shading.color(rocket.color.opacity(1 - progress))
            for spark in rocket.sparks {
                let shown = reduceMotion ? 0.8 : progress
                let offset = FireworksBurstMath.sparkOffset(angle: spark.angle, speed: spark.speed, progress: shown)
                let center = CGPoint(x: rocket.target.x + offset.width, y: rocket.target.y + offset.height)
                let dot = CGRect(x: center.x - spark.size / 2, y: center.y - spark.size / 2, width: spark.size, height: spark.size)
                context.fill(Path(ellipseIn: dot), with: shading)
            }

        case .finished:
            break
        }
    }
}

// MARK: - Demo

struct FireworksBurstDemo: View {
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.14), Color(red: 0.13, green: 0.07, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            FireworksBurst()
                .ignoresSafeArea()

            Text("Tap the sky")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 24)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    FireworksBurstDemo()
}
