// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Fires a one-shot burst of confetti every time `trigger` changes.
///
/// With Reduce Motion on, the pieces appear scattered and fade out without moving.
struct ConfettiBurst: ViewModifier {
    var trigger: Int
    var count: Int = 120
    /// Where the burst starts, as a fraction of the view.
    var origin: UnitPoint = UnitPoint(x: 0.5, y: 0.68)
    var colors: [Color] = [.pink, .yellow, .mint, .cyan, .orange, .purple]
    var lifetime: Double = 3

    @State private var start: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let motion = ConfettiBurstMotion()

    func body(content: Content) -> some View {
        content
            .overlay {
                TimelineView(.animation(paused: start == nil)) { timeline in
                    Canvas { context, size in
                        guard let start else { return }
                        draw(elapsed: timeline.date.timeIntervalSince(start), in: context, size: size)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .onChange(of: trigger) { start = .now }
            .task(id: start) {
                guard start != nil else { return }
                try? await Task.sleep(for: .seconds(lifetime))
                if !Task.isCancelled { start = nil }
            }
    }

    private func draw(elapsed: Double, in context: GraphicsContext, size: CGSize) {
        guard elapsed < lifetime, !colors.isEmpty else { return }

        let time = reduceMotion ? 0.6 : elapsed
        let fade = min((lifetime - elapsed) / (lifetime * 0.3), 1)

        for index in 0..<count {
            let offset = Self.motion.offset(
                // Two random values added together cluster the pieces around straight up.
                angle: (noise(index, 1) + noise(index, 7) - 1) * 0.9,
                speed: 500 + noise(index, 2) * 1900,
                at: time
            )

            var piece = context
            piece.opacity = fade
            piece.translateBy(x: origin.x * size.width + offset.x, y: origin.y * size.height + offset.y)
            piece.rotate(by: .radians(time * (noise(index, 3) * 8 - 4) + noise(index, 4) * 2 * .pi))
            piece.scaleBy(x: cos(time * (4 + noise(index, 5) * 8) + noise(index, 6) * 2 * .pi), y: 1)

            let color = GraphicsContext.Shading.color(colors[index % colors.count])
            if index.isMultiple(of: 3) {
                piece.fill(Path(ellipseIn: CGRect(x: -4, y: -4, width: 8, height: 8)), with: color)
            } else {
                piece.fill(Path(CGRect(x: -4, y: -6.5, width: 8, height: 13)), with: color)
            }
        }
    }

    /// A repeatable pseudo-random value in 0..<1, different for each burst.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + (salt + Double(trigger) * 0.37) * 311.7) * 43758.5453
        return value - floor(value)
    }
}

/// The flight of one piece: thrown from the origin, slowed by air and pulled down by gravity.
struct ConfettiBurstMotion {
    /// Points per second squared.
    var gravity: Double = 900
    /// How quickly air slows a piece, per second.
    var drag: Double = 2.6

    /// The offset from the origin, with y growing downward.
    /// - Parameters:
    ///   - angle: The launch direction in radians: 0 is straight up, positive leans right.
    ///   - speed: The launch speed in points per second.
    ///   - time: The seconds since launch.
    func offset(angle: Double, speed: Double, at time: Double) -> CGPoint {
        let time = max(time, 0)
        let drag = max(drag, 0.001)
        let travelled = (1 - exp(-drag * time)) / drag

        return CGPoint(
            x: sin(angle) * speed * travelled,
            y: -cos(angle) * speed * travelled + gravity / drag * (time - travelled)
        )
    }
}

extension View {
    /// Fires a one-shot burst of confetti over this view every time `trigger` changes.
    func confettiBurst(trigger: Int, count: Int = 120, origin: UnitPoint = UnitPoint(x: 0.5, y: 0.68)) -> some View {
        modifier(ConfettiBurst(trigger: trigger, count: count, origin: origin))
    }
}

// MARK: - Demo

struct ConfettiBurstDemo: View {
    @State private var bursts = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.09, blue: 0.33), Color(red: 0.36, green: 0.13, blue: 0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()

                Image(systemName: "trophy.fill")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("You Did It")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Celebrate") { bursts += 1 }
                    .font(.headline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.pink)
                    .padding(.bottom, 32)
            }
        }
        .confettiBurst(trigger: bursts)
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            bursts += 1
        }
    }
}

#Preview {
    ConfettiBurstDemo()
}
