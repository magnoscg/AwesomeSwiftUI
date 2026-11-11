// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A heart that pops and throws out a burst of small particles when liked.
///
/// With Reduce Motion on, the heart simply fills, with no pop or burst.
struct LikeBurstButton: View {
    @Binding var isLiked: Bool
    var color: Color = .pink
    var particleCount: Int = 12

    @State private var burstCount = 0
    @ScaledMetric(relativeTo: .largeTitle) private var heartSize = 72.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            isLiked.toggle()
            if isLiked && !reduceMotion {
                burstCount += 1
            }
        } label: {
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    LikeBurstButtonSpark(
                        angle: Double(index) / Double(particleCount) * 360,
                        reach: heartSize * (index.isMultiple(of: 2) ? 1.25 : 0.95),
                        size: heartSize * 0.14,
                        color: [color, .orange, .yellow][index % 3],
                        trigger: burstCount
                    )
                }

                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: heartSize, weight: .semibold))
                    .foregroundStyle(isLiked ? color : Color.secondary)
                    .keyframeAnimator(initialValue: 1.0, trigger: burstCount) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(0.6, duration: 0.09)
                            SpringKeyframe(1.3, duration: 0.2, spring: .bouncy)
                            SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                        }
                    }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: burstCount)
        .accessibilityLabel("Like")
        .accessibilityAddTraits(isLiked ? .isSelected : [])
    }
}

private struct LikeBurstButtonSparkState {
    var distance = 0.0
    var scale = 0.0
    var opacity = 0.0
}

private struct LikeBurstButtonSpark: View {
    let angle: Double
    let reach: Double
    let size: Double
    let color: Color
    let trigger: Int

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .keyframeAnimator(initialValue: LikeBurstButtonSparkState(), trigger: trigger) { [angle] content, state in
                content
                    .scaleEffect(state.scale)
                    .opacity(state.opacity)
                    .offset(y: -state.distance)
                    .rotationEffect(.degrees(angle))
            } keyframes: { _ in
                KeyframeTrack(\.distance) {
                    MoveKeyframe(0)
                    CubicKeyframe(reach, duration: 0.6)
                }
                KeyframeTrack(\.scale) {
                    MoveKeyframe(0.2)
                    SpringKeyframe(1, duration: 0.18, spring: .bouncy)
                    LinearKeyframe(0.1, duration: 0.42)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: 0.35)
                    LinearKeyframe(0, duration: 0.25)
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Demo

struct LikeBurstButtonDemo: View {
    @State private var isLiked = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var count: Int { isLiked ? 129 : 128 }

    var body: some View {
        VStack(spacing: 28) {
            LikeBurstButton(isLiked: $isLiked)

            VStack(spacing: 4) {
                Text(count, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(count)))
                    .animation(reduceMotion ? nil : .snappy, value: count)
                Text("people love this")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pink.opacity(0.08).ignoresSafeArea())
    }
}

#Preview {
    LikeBurstButtonDemo()
}
