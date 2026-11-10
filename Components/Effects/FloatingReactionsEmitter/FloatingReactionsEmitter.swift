// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum FloatingReactionsEmitterMath {
    /// How far a reaction has moved from its origin, weaving side to side as it rises.
    static func offset(progress: Double, rise: CGFloat, drift: CGFloat, swayPhase: Double) -> CGSize {
        let clamped = min(max(progress, 0), 1)
        let sway = sin(clamped * 3 * .pi + swayPhase) * 16 * clamped
        return CGSize(width: drift * clamped + sway, height: -rise * clamped)
    }

    /// Solid for most of the way, then fading out.
    static func opacity(progress: Double) -> Double {
        let clamped = min(max(progress, 0), 1)
        return clamped < 0.6 ? 1 : (1 - clamped) / 0.4
    }

    static func scale(progress: Double) -> Double {
        0.4 + 0.6 * min(max(progress, 0) / 0.15, 1)
    }
}

private struct FloatingReactionsEmitterReaction: Identifiable {
    let id = UUID()
    let emoji: String
    let origin: CGPoint
    let start: Date
    let drift: CGFloat
    let swayPhase: Double
}

/// Wraps content so that a tap sends an emoji floating up from that point.
///
/// With Reduce Motion on, the emoji stays where it was tapped and fades out.
struct FloatingReactionsEmitter<Content: View>: View {
    var emojis: [String] = ["❤️", "🔥", "👏", "😂", "🎉"]
    var lifetime: Double = 1.8
    var rise: CGFloat = 320
    @ViewBuilder var content: () -> Content

    @State private var reactions: [FloatingReactionsEmitterReaction] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    private let maximumReactions = 40
    private var duration: Double { lifetime > 0 ? lifetime : 1 }

    var body: some View {
        GeometryReader { proxy in
            content()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .contentShape(.rect)
                .gesture(SpatialTapGesture().onEnded { value in
                    // Gestures report screen points, but `position` mirrors in right-to-left layouts.
                    let x = layoutDirection == .rightToLeft ? proxy.size.width - value.location.x : value.location.x
                    emit(from: CGPoint(x: x, y: value.location.y))
                })
                .overlay {
                    TimelineView(.animation(paused: reactions.isEmpty)) { timeline in
                        ZStack {
                            ForEach(reactions) { reaction in
                                bubble(for: reaction, at: timeline.date)
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(height: 44)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel("Send reaction")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            emit(from: CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.75))
                        }
                }
        }
        .task(id: reactions.last?.id) {
            guard !reactions.isEmpty else { return }

            try? await Task.sleep(for: .seconds(duration + 0.1))
            guard !Task.isCancelled else { return }

            let now = Date.now
            reactions.removeAll { now.timeIntervalSince($0.start) >= duration }
        }
    }

    private func bubble(for reaction: FloatingReactionsEmitterReaction, at date: Date) -> some View {
        let progress = date.timeIntervalSince(reaction.start) / duration
        let offset = reduceMotion
            ? .zero
            : FloatingReactionsEmitterMath.offset(progress: progress, rise: rise, drift: reaction.drift, swayPhase: reaction.swayPhase)

        return Text(reaction.emoji)
            .font(.largeTitle)
            .scaleEffect(reduceMotion ? 1 : FloatingReactionsEmitterMath.scale(progress: progress))
            .opacity(FloatingReactionsEmitterMath.opacity(progress: progress))
            .position(x: reaction.origin.x + offset.width, y: reaction.origin.y + offset.height)
    }

    private func emit(from location: CGPoint) {
        guard let emoji = emojis.randomElement() else { return }

        reactions.append(
            FloatingReactionsEmitterReaction(
                emoji: emoji,
                origin: location,
                start: .now,
                drift: .random(in: -70...70),
                swayPhase: .random(in: 0...(2 * .pi))
            )
        )
        if reactions.count > maximumReactions {
            reactions.removeFirst(reactions.count - maximumReactions)
        }
    }
}

// MARK: - Demo

struct FloatingReactionsEmitterDemo: View {
    var body: some View {
        FloatingReactionsEmitter {
            ZStack {
                LinearGradient(colors: [.purple, .pink, .orange], startPoint: .top, endPoint: .bottom)

                VStack(spacing: 14) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.largeTitle)
                        .accessibilityHidden(true)

                    Text("Live now")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("Tap anywhere to react")
                        .font(.body)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(24)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    FloatingReactionsEmitterDemo()
}
