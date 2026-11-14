// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct KeyframeTimelineShowcaseValues {
    var scale = 1.0
    var offset = 0.0
    var tint = 0.0
    var playhead = 0.0
}

/// The length of each keyframe in seconds. Every track adds up to the same total, so the loop closes.
private enum KeyframeTimelineShowcaseTiming {
    static let scale = [0.3, 0.45, 0.35, 0.9]
    static let offset = [0.3, 0.4, 0.5, 0.8]
    static let tint = [0.75, 0.5, 0.75]
    static let total = 2.0

    static func ticks(_ durations: [Double]) -> [Double] {
        var elapsed = 0.0
        return durations.map { duration in
            elapsed += duration
            return elapsed / total
        }
    }
}

/// Plays scale, offset and color tracks on one shared keyframe timeline, and draws the tracks below.
///
/// With Reduce Motion on, the content rests and the timeline stays still.
struct KeyframeTimelineShowcase<Content: View>: View {
    var restColor: Color = .indigo
    var peakColor: Color = .pink
    @ViewBuilder var content: () -> Content

    @ScaledMetric(relativeTo: .largeTitle) private var tileSize = 120.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            stage(KeyframeTimelineShowcaseValues())
        } else {
            KeyframeAnimator(initialValue: KeyframeTimelineShowcaseValues(), repeating: true) { values in
                stage(values)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.8, duration: KeyframeTimelineShowcaseTiming.scale[0])
                    SpringKeyframe(1.25, duration: KeyframeTimelineShowcaseTiming.scale[1], spring: .bouncy)
                    CubicKeyframe(0.92, duration: KeyframeTimelineShowcaseTiming.scale[2])
                    SpringKeyframe(1, duration: KeyframeTimelineShowcaseTiming.scale[3], spring: .bouncy)
                }
                KeyframeTrack(\.offset) {
                    LinearKeyframe(0, duration: KeyframeTimelineShowcaseTiming.offset[0])
                    CubicKeyframe(-90, duration: KeyframeTimelineShowcaseTiming.offset[1])
                    CubicKeyframe(0, duration: KeyframeTimelineShowcaseTiming.offset[2])
                    LinearKeyframe(0, duration: KeyframeTimelineShowcaseTiming.offset[3])
                }
                KeyframeTrack(\.tint) {
                    CubicKeyframe(1, duration: KeyframeTimelineShowcaseTiming.tint[0])
                    LinearKeyframe(1, duration: KeyframeTimelineShowcaseTiming.tint[1])
                    CubicKeyframe(0, duration: KeyframeTimelineShowcaseTiming.tint[2])
                }
                KeyframeTrack(\.playhead) {
                    // Each loop starts from the last value, so the playhead has to jump back.
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: KeyframeTimelineShowcaseTiming.total)
                }
            }
        }
    }

    private func stage(_ values: KeyframeTimelineShowcaseValues) -> some View {
        VStack(spacing: 32) {
            content()
                .frame(width: tileSize, height: tileSize)
                .background(
                    restColor.mix(with: peakColor, by: values.tint),
                    in: RoundedRectangle(cornerRadius: tileSize * 0.26, style: .continuous)
                )
                .scaleEffect(values.scale)
                .offset(y: values.offset)
                .frame(height: tileSize + 150, alignment: .bottom)

            VStack(spacing: 12) {
                lane("Scale", color: .orange, ticks: KeyframeTimelineShowcaseTiming.ticks(KeyframeTimelineShowcaseTiming.scale))
                lane("Offset", color: .teal, ticks: KeyframeTimelineShowcaseTiming.ticks(KeyframeTimelineShowcaseTiming.offset))
                lane("Color", color: peakColor, ticks: KeyframeTimelineShowcaseTiming.ticks(KeyframeTimelineShowcaseTiming.tint))
            }
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.primary)
                        .frame(width: 2)
                        .offset(x: proxy.size.width * values.playhead - 1)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func lane(_ title: String, color: Color, ticks: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Canvas { context, size in
                let track = CGRect(x: 0, y: size.height / 2 - 2, width: size.width, height: 4)
                context.fill(Path(roundedRect: track, cornerRadius: 2), with: .color(color.opacity(0.3)))
                for tick in ticks {
                    // The first and the last dot stay whole inside the lane.
                    let dot = CGRect(x: (size.width - 10) * tick, y: size.height / 2 - 5, width: 10, height: 10)
                    context.fill(Path(ellipseIn: dot), with: .color(color))
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - Demo

struct KeyframeTimelineShowcaseDemo: View {
    var body: some View {
        KeyframeTimelineShowcase {
            Image(systemName: "sparkles")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityLabel("Animated tile")
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    KeyframeTimelineShowcaseDemo()
}
