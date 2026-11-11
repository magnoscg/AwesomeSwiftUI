// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// When each dot rises. Every dot waits, bounces and rests for the same total, so the three
/// keep their order however long the indicator stays on screen.
nonisolated enum TypingIndicatorBubbleTiming {
    static let bounce = 0.5

    /// What a dot waits before it rises: each one a step after the one before it.
    static func delay(for index: Int, stagger: Double) -> Double {
        Double(max(index, 0)) * max(stagger, 0)
    }

    /// What a dot rests after its bounce, so its wait, bounce and rest add up to `period`.
    static func rest(for index: Int, stagger: Double, period: Double) -> Double {
        max(period - bounce - delay(for: index, stagger: stagger), 0)
    }

    /// The shortest period in which the last dot still has time to bounce.
    static func period(_ period: Double, dots: Int, stagger: Double) -> Double {
        max(period, bounce + delay(for: dots - 1, stagger: stagger))
    }
}

/// Three dots that bounce in turn inside a message bubble while someone is typing.
///
/// Set `isTyping` to false and the bubble shrinks away into its corner. With Reduce Motion
/// on, the dots only brighten in turn and the bubble fades. VoiceOver reads `label`.
struct TypingIndicatorBubble: View {
    var isTyping = true
    var label: LocalizedStringResource = "Typing"
    var bubbleColor = Color(.secondarySystemFill)
    var dotColor = Color.secondary
    var dotCount = 3
    var period = 1.3

    @ScaledMetric(relativeTo: .body) private var dotSize = 9.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stagger = 0.16
    private let cornerRadius: CGFloat = 20

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if isTyping {
                bubble
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.5, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.35), value: isTyping)
    }

    private var bubble: some View {
        HStack(spacing: dotSize * 0.6) {
            ForEach(0..<max(dotCount, 1), id: \.self) { index in
                dot(at: index)
            }
        }
        .padding(.horizontal, dotSize * 1.6)
        .padding(.vertical, dotSize * 1.5)
        // The corner next to the sender is tighter, like the tail of a message.
        .background(bubbleColor, in: .rect(cornerRadii: .init(topLeading: cornerRadius, bottomLeading: 6, bottomTrailing: cornerRadius, topTrailing: cornerRadius)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private func dot(at index: Int) -> some View {
        let count = max(dotCount, 1)
        let total = TypingIndicatorBubbleTiming.period(period, dots: count, stagger: stagger)
        let delay = TypingIndicatorBubbleTiming.delay(for: index, stagger: stagger)
        let rest = TypingIndicatorBubbleTiming.rest(for: index, stagger: stagger, period: total)
        let half = TypingIndicatorBubbleTiming.bounce / 2
        let lift = reduceMotion ? 0 : dotSize * 0.7

        return Circle()
            .fill(dotColor)
            .frame(width: dotSize, height: dotSize)
            .keyframeAnimator(initialValue: 0.0, repeating: true) { content, rise in
                content
                    .offset(y: -lift * rise)
                    .opacity(0.45 + 0.55 * rise)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: delay)
                    CubicKeyframe(1, duration: half)
                    CubicKeyframe(0, duration: half)
                    LinearKeyframe(0, duration: rest)
                }
            }
    }
}

// MARK: - Demo

struct TypingIndicatorBubbleDemo: View {
    private static let replies = ["On my way!", "Save me a seat", "Five minutes, I promise"]

    @State private var messages = ["Are you coming tonight?"]
    @State private var isTyping = false

    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Maya")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)

            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                Text(message)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(index == 0 ? .white : .primary)
                    .background(index == 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.secondarySystemFill)), in: .rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity, alignment: index == 0 ? .trailing : .leading)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            TypingIndicatorBubble(isTyping: isTyping, label: "Maya is typing")

            Spacer(minLength: 0)

            Button(isTyping ? "Stop typing" : "Start typing") {
                isTyping.toggle()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(reduceMotion ? nil : .snappy, value: messages)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task {
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(0.7))
                guard !Task.isCancelled, isAutoPlaying else { return }
                isTyping = true

                try? await Task.sleep(for: .seconds(1.9))
                guard !Task.isCancelled, isAutoPlaying else { return }
                isTyping = false
                messages = messages.count > Self.replies.count
                    ? [messages[0]]
                    : messages + [Self.replies[messages.count - 1]]
            }
        }
    }
}

#Preview {
    TypingIndicatorBubbleDemo()
}
