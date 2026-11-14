// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum TapbackReactionBubbleLogic {
    /// The reaction a message has after one is chosen: choosing the one it had takes it away.
    static func toggled(_ current: String?, choosing reaction: String) -> String? {
        current == reaction ? nil : reaction
    }

    /// How long a reaction of the bar waits before it pops in, so they arrive in a quick wave
    /// that a long bar does not stretch.
    static func delay(for index: Int, step: Double = 0.03, limit: Double = 0.18) -> Double {
        min(Double(max(index, 0)) * step, limit)
    }
}

/// A message you press and hold to react to: it lifts, a bar of reactions opens above it, and the
/// one you choose stays on its corner as a badge. Choose it again to take it away.
///
/// The caller owns `isPicking`, so it can close the bar from outside and dim the other messages.
/// VoiceOver offers each reaction as an action of the message. With Reduce Motion on, nothing
/// scales: the bar and the badge fade.
struct TapbackReactionBubble<Content: View>: View {
    @Binding var reaction: String?
    @Binding var isPicking: Bool
    var reactions = ["❤️", "👍", "👎", "😂", "‼️", "❓"]
    /// The side of the screen the message sits on. The bar grows from that side and the badge
    /// goes to the other corner, toward the middle of the screen.
    var side = HorizontalAlignment.leading
    @ViewBuilder var content: () -> Content

    private let gap: CGFloat = 8
    private let badgeOverhang = 0.65

    @State private var isBarShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Plain values for the alignment guides, which may not capture a generic view: Xcode 26 rejects it.
        let gap = gap
        let overhang = badgeOverhang
        let isLeading = side == .leading

        content()
            .overlay(alignment: Alignment(horizontal: side == .leading ? .trailing : .leading, vertical: .top)) {
                // The guides go on a container that is always there: on a view that comes and goes
                // with a transition they are not read.
                ZStack {
                    if let reaction {
                        badge(reaction)
                    }
                }
                // Most of the badge hangs outside the corner, so it does not cover the message.
                .alignmentGuide(.top) { $0.height * overhang }
                .alignmentGuide(isLeading ? .trailing : .leading) { $0.width * (isLeading ? 1 - overhang : overhang) }
            }
            .scaleEffect(isPicking && !reduceMotion ? 1.04 : 1)
            .overlay(alignment: Alignment(horizontal: side, vertical: .top)) {
                ZStack {
                    if isPicking {
                        bar
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                    }
                }
                // The bottom of the bar sits a gap above the top of the message.
                .alignmentGuide(.top) { $0[.bottom] + gap }
            }
            .zIndex(isPicking ? 1 : 0)
            .onLongPressGesture(minimumDuration: 0.4) {
                isPicking = true
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.3), value: isPicking)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.5), value: reaction)
            .sensoryFeedback(trigger: isPicking) { _, isPicking in
                isPicking ? .impact(weight: .medium) : nil
            }
            .sensoryFeedback(.selection, trigger: reaction)
            .accessibilityElement(children: .combine)
            .accessibilityValue(reaction.map { "Reacted with \($0)" } ?? "")
            .accessibilityActions {
                ForEach(reactions, id: \.self) { option in
                    Button(option == reaction ? "Remove \(option)" : "React with \(option)") {
                        choose(option)
                    }
                }
            }
    }

    private func badge(_ reaction: String) -> some View {
        Text(reaction)
            .font(.footnote)
            .padding(6)
            .background(.regularMaterial, in: .circle)
            .overlay { Circle().strokeBorder(.background, lineWidth: 2) }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.2).combined(with: .opacity))
            .id(reaction)
            .accessibilityHidden(true)
    }

    private var bar: some View {
        HStack(spacing: 4) {
            ForEach(Array(reactions.enumerated()), id: \.element) { index, option in
                Button {
                    choose(option)
                } label: {
                    Text(option)
                        .font(.title2)
                        .frame(minWidth: 40, minHeight: 40)
                        .background(option == reaction ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.clear), in: .circle)
                }
                .buttonStyle(.plain)
                .scaleEffect(isBarShown || reduceMotion ? 1 : 0.4)
                .animation(.spring(duration: 0.25, bounce: 0.45).delay(TapbackReactionBubbleLogic.delay(for: index)), value: isBarShown)
                .accessibilityLabel(option == reaction ? "Remove \(option)" : "React with \(option)")
            }
        }
        .padding(6)
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .fixedSize()
        .onAppear { isBarShown = true }
        .onDisappear { isBarShown = false }
    }

    private func choose(_ option: String) {
        reaction = TapbackReactionBubbleLogic.toggled(reaction, choosing: option)
        isPicking = false
    }
}

// MARK: - Demo

private struct TapbackReactionBubbleDemoMessage: Identifiable {
    let id: Int
    let text: String
    let isMine: Bool
}

struct TapbackReactionBubbleDemo: View {
    private let messages = [
        TapbackReactionBubbleDemoMessage(id: 0, text: "Are we still on for the hike on Saturday?", isMine: false),
        TapbackReactionBubbleDemoMessage(id: 1, text: "Yes! I’ll bring the snacks.", isMine: true),
        TapbackReactionBubbleDemoMessage(id: 2, text: "Perfect. Meet at the trailhead at eight?", isMine: false),
        TapbackReactionBubbleDemoMessage(id: 3, text: "Eight it is.", isMine: true),
    ]

    @State private var reactions: [Int: String] = [1: "❤️"]
    @State private var picking: Int?

    var body: some View {
        VStack(spacing: 18) {
            Text("Press and hold a message")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            ForEach(messages) { message in
                let isOther = picking != nil && picking != message.id

                TapbackReactionBubble(
                    reaction: Binding { reactions[message.id] } set: { reactions[message.id] = $0 },
                    isPicking: Binding { picking == message.id } set: { picking = $0 ? message.id : nil },
                    side: message.isMine ? .trailing : .leading
                ) {
                    Text(message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(message.isMine ? .white : .primary)
                        .background(message.isMine ? AnyShapeStyle(.blue) : AnyShapeStyle(.fill.tertiary), in: .rect(cornerRadius: 20))
                }
                .frame(maxWidth: 280, alignment: message.isMine ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: message.isMine ? .trailing : .leading)
                .opacity(isOther ? 0.3 : 1)
                .allowsHitTesting(!isOther)
                .zIndex(picking == message.id ? 1 : 0)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Catches the taps outside the open message, which close its bar.
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture { picking = nil }
        }
        .animation(.easeInOut(duration: 0.25), value: picking)
    }
}

#Preview {
    TapbackReactionBubbleDemo()
}
