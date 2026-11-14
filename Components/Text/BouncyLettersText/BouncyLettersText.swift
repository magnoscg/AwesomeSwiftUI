// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Letters that hop one after another, in a repeating wave.
///
/// Letters are laid out one by one, so it suits a short single line.
/// With Reduce Motion on, it is plain text.
struct BouncyLettersText: View {
    let text: String
    /// Seconds between one letter's hop and the next one's.
    var stagger: Double = 0.08
    /// Seconds of rest after the last letter lands.
    var pause: Double = 0.7

    @ScaledMetric(relativeTo: .largeTitle) private var hopHeight = 28.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Text(text)
        } else {
            let letters = Array(text)

            HStack(spacing: 0) {
                ForEach(letters.indices, id: \.self) { index in
                    letter(letters[index], index: index, count: letters.count)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
        }
    }

    /// Every letter's timeline has the same total length, so they stay in step as they repeat.
    private func letter(_ character: Character, index: Int, count: Int) -> some View {
        let firstLead = 0.001
        let rise = 0.16
        let fall = 0.16
        let settle = 0.2
        let period = firstLead + Double(count - 1) * stagger + rise + fall + settle + pause
        let lead = max(Double(index) * stagger, firstLead)
        let rest = period - lead - rise - fall - settle
        let height = hopHeight

        return Text(String(character))
            .accessibilityRepresentation { EmptyView() }
            .keyframeAnimator(initialValue: BouncyLetterPose(), repeating: true) { view, pose in
                view
                    .scaleEffect(x: 2 - pose.stretch, y: pose.stretch, anchor: .bottom)
                    .offset(y: pose.lift)
            } keyframes: { _ in
                KeyframeTrack(\.lift) {
                    LinearKeyframe(0, duration: lead)
                    CubicKeyframe(-height, duration: rise)
                    CubicKeyframe(0, duration: fall)
                    LinearKeyframe(0, duration: settle + rest)
                }
                KeyframeTrack(\.stretch) {
                    LinearKeyframe(1, duration: lead)
                    CubicKeyframe(1.14, duration: rise)
                    CubicKeyframe(0.8, duration: fall)
                    SpringKeyframe(1, duration: settle, spring: .bouncy)
                    LinearKeyframe(1, duration: rest)
                }
            }
    }
}

private struct BouncyLetterPose {
    var lift = 0.0
    var stretch = 1.0
}

// MARK: - Demo

struct BouncyLettersTextDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 56) {
                BouncyLettersText(text: "Boing!")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .scaleEffect(1.5)

                BouncyLettersText(text: "Hop in sequence", stagger: 0.05)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    BouncyLettersTextDemo()
}
