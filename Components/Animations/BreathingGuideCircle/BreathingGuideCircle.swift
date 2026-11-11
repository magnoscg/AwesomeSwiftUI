// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum BreathingGuideCirclePhase: String {
    case inhale = "Breathe In"
    case hold = "Hold"
    case exhale = "Breathe Out"
}

struct BreathingGuideCircleState: Equatable {
    let phase: BreathingGuideCirclePhase
    let secondsLeft: Int
    /// 0 is fully contracted and 1 is fully expanded.
    let expansion: Double
}

enum BreathingGuideCircleMath {
    /// Where the cycle is after `elapsed` seconds. Invalid durations count as zero.
    static func state(at elapsed: TimeInterval, inhale: Double, hold: Double, exhale: Double) -> BreathingGuideCircleState {
        let inhale = sanitized(inhale)
        let hold = sanitized(hold)
        let exhale = sanitized(exhale)
        let total = inhale + hold + exhale
        guard total > 0, elapsed.isFinite else {
            return BreathingGuideCircleState(phase: .inhale, secondsLeft: 0, expansion: 0)
        }

        var time = elapsed.truncatingRemainder(dividingBy: total)
        if time < 0 { time += total }

        if time < inhale {
            return BreathingGuideCircleState(phase: .inhale, secondsLeft: Int((inhale - time).rounded(.up)), expansion: eased(time / inhale))
        }
        time -= inhale
        if time < hold {
            return BreathingGuideCircleState(phase: .hold, secondsLeft: Int((hold - time).rounded(.up)), expansion: 1)
        }
        time -= hold
        let progress = exhale > 0 ? min(time / exhale, 1) : 1
        return BreathingGuideCircleState(phase: .exhale, secondsLeft: Int((exhale - time).rounded(.up)), expansion: 1 - eased(progress))
    }

    private static func sanitized(_ duration: Double) -> Double {
        duration.isFinite ? min(max(duration, 0), 3_600) : 0
    }

    private static func eased(_ progress: Double) -> Double {
        progress * progress * (3 - 2 * progress)
    }
}

/// A circle that expands and contracts through breathing phases, with a label and a countdown.
///
/// With Reduce Motion on, the circle stays still and the label keeps guiding.
struct BreathingGuideCircle: View {
    var inhale = 4.0
    var hold = 4.0
    var exhale = 6.0
    var tint: Color = .teal
    var diameter: CGFloat = 260

    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How much the scale of every ring grows from contracted to expanded.
    private let ringGrowth = 0.38

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1.0 / 30.0)) { timeline in
            let state = BreathingGuideCircleMath.state(
                at: timeline.date.timeIntervalSince(start),
                inhale: inhale,
                hold: hold,
                exhale: exhale
            )

            VStack(spacing: 36) {
                circle(expansion: reduceMotion ? 0.6 : state.expansion)

                VStack(spacing: 6) {
                    Text(state.phase.rawValue)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .multilineTextAlignment(.center)
                    Text(state.secondsLeft, format: .number)
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Breathing guide")
            .accessibilityValue(state.phase.rawValue)
        }
    }

    private func circle(expansion: Double) -> some View {
        let size = max(diameter, 0)

        return ZStack {
            Circle()
                .fill(tint.opacity(0.14))
                .scaleEffect(0.62 + ringGrowth * expansion)
            Circle()
                .fill(tint.opacity(0.26))
                .scaleEffect(0.5 + ringGrowth * expansion)
            Circle()
                .fill(.linearGradient(colors: [tint, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .scaleEffect(0.38 + ringGrowth * expansion)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Demo

struct BreathingGuideCircleDemo: View {
    var body: some View {
        BreathingGuideCircle(inhale: 1.6, hold: 0.8, exhale: 1.6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BreathingGuideCircleDemo()
}
