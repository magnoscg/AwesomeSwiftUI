// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct ActivityRingsRing {
    var title: String
    var progress: Double
    var colors: [Color]
}

/// Concentric gradient rings that close as their goals are reached.
struct ActivityRings: View {
    let rings: [ActivityRingsRing]
    var diameter: CGFloat = 240
    var lineWidth: CGFloat = 28
    var gap: CGFloat = 5

    var body: some View {
        let size = max(diameter, 0)
        let stroke = max(lineWidth, 0)
        let pitch = stroke + max(gap, 0)
        let visible = ActivityRingsMath.visibleCount(ringCount: rings.count, diameter: size, lineWidth: stroke, gap: max(gap, 0))

        ZStack {
            ForEach(0..<visible, id: \.self) { index in
                ActivityRingsTrack(ring: rings[index], diameter: size, lineWidth: stroke, inset: CGFloat(index) * pitch)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity rings")
        .accessibilityValue(summary)
    }

    private var summary: String {
        rings.map { ring in
            let percent = ActivityRingsMath.clamped(ring.progress).formatted(.percent.precision(.fractionLength(0)))
            return "\(ring.title) \(percent)"
        }
        .joined(separator: ", ")
    }
}

private struct ActivityRingsTrack: View {
    let ring: ActivityRingsRing
    let diameter: CGFloat
    let lineWidth: CGFloat
    let inset: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var colors: [Color] { ring.colors.isEmpty ? [.accentColor] : ring.colors }
    private var progress: Double { ActivityRingsMath.clamped(ring.progress) }

    var body: some View {
        ZStack {
            Circle()
                .inset(by: inset + lineWidth / 2)
                .stroke((colors.first ?? .accentColor).opacity(0.2), lineWidth: lineWidth)

            Circle()
                .inset(by: inset + lineWidth / 2)
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: colors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(colors.first ?? .accentColor)
                .frame(width: lineWidth, height: lineWidth)
                .offset(y: -(diameter / 2 - inset - lineWidth / 2))
                .opacity(progress > 0 ? 1 : 0)
        }
        .animation(reduceMotion ? nil : .spring(duration: 1.1, bounce: 0.2), value: progress)
    }
}

enum ActivityRingsMath {
    static func clamped(_ progress: Double) -> Double {
        progress.isFinite ? min(max(progress, 0), 1) : 0
    }

    /// How many rings fit inside the diameter, so inner rings never turn inside out.
    static func visibleCount(ringCount: Int, diameter: Double, lineWidth: Double, gap: Double) -> Int {
        let pitch = lineWidth + gap
        guard ringCount > 0, diameter > 0, pitch > 0, pitch.isFinite, diameter.isFinite else { return 0 }
        // The innermost ring needs no gap after it, which is why one gap is added back.
        return Int(min(Double(ringCount), ((diameter / 2 + gap) / pitch).rounded(.down)))
    }
}

// MARK: - Demo

struct ActivityRingsDemo: View {
    @State private var fill = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let goals: [(title: String, value: Double, goal: Double, unit: String, colors: [Color])] = [
        ("Move", 520, 600, "kcal", [.red, .pink]),
        ("Exercise", 22, 30, "min", [.green, .mint]),
        ("Stand", 11, 12, "h", [.cyan, .blue]),
    ]

    var body: some View {
        VStack(spacing: 40) {
            ActivityRings(rings: goals.map { goal in
                ActivityRingsRing(title: goal.title, progress: goal.value / goal.goal * fill, colors: goal.colors)
            })

            VStack(spacing: 14) {
                ForEach(goals, id: \.title) { goal in
                    HStack {
                        Circle()
                            .fill(LinearGradient(colors: goal.colors, startPoint: .top, endPoint: .bottom))
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)
                        Text(goal.title)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(goal.value * fill)) / \(Int(goal.goal)) \(goal.unit)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(.horizontal, 44)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                fill = 1
                return
            }
            while !Task.isCancelled {
                fill = 1
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }
                fill = 0
                try? await Task.sleep(for: .seconds(1.1))
            }
        }
    }
}

#Preview {
    ActivityRingsDemo()
}
