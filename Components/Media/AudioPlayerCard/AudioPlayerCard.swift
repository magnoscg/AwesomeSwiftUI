// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A podcast-style player card. It shows state and reports changes: wire it to your own player.
///
/// Pass any view as the artwork, usually `Image("cover").resizable().scaledToFill()`.
struct AudioPlayerCard<Artwork: View>: View {
    let title: String
    let subtitle: String
    let duration: TimeInterval
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    /// Seconds per skip. Matching SF Symbols exist for 5, 10, 15, 30, 45, 60, 75 and 90.
    var skipInterval = 15
    /// Called with `true` when a scrub starts and `false` when it ends.
    var onScrubbingChanged: (Bool) -> Void = { _ in }
    @ViewBuilder var artwork: () -> Artwork

    @ScaledMetric(relativeTo: .title) private var artworkSize = 84.0
    @ScaledMetric(relativeTo: .largeTitle) private var playSize = 62.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var safeDuration: TimeInterval { duration.isFinite ? min(max(duration, 0), 360_000) : 0 }
    private var position: TimeInterval { currentTime.isFinite ? min(max(currentTime, 0), safeDuration) : 0 }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                artwork()
                    .frame(width: artworkSize, height: artworkSize)
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 4) {
                Slider(
                    value: Binding(get: { position }, set: { currentTime = $0 }),
                    in: 0...max(safeDuration, 1),
                    onEditingChanged: onScrubbingChanged
                )
                .disabled(safeDuration == 0)
                .accessibilityLabel("Playback position")
                .accessibilityValue("\(timeText(position)) of \(timeText(safeDuration))")

                HStack {
                    Text(timeText(position))
                    Spacer()
                    Text("-" + timeText(safeDuration - position))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            }

            HStack(spacing: 36) {
                skipButton(forward: false)

                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { isPlaying.toggle() }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                        .foregroundStyle(.background)
                        .frame(width: playSize, height: playSize)
                        .background(.primary, in: .circle)
                }
                .accessibilityLabel(isPlaying ? "Pause" : "Play")

                skipButton(forward: true)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: isPlaying)
        }
        .padding(20)
        .background(.regularMaterial, in: .rect(cornerRadius: 28))
    }

    private func skipButton(forward: Bool) -> some View {
        let base = forward ? "goforward" : "gobackward"
        let hasNumberedSymbol = [5, 10, 15, 30, 45, 60, 75, 90].contains(skipInterval)
        return Button {
            currentTime = min(max(position + Double(skipInterval) * (forward ? 1 : -1), 0), safeDuration)
        } label: {
            Image(systemName: hasNumberedSymbol ? "\(base).\(skipInterval)" : base)
                .font(.title2)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .disabled(safeDuration == 0)
        .accessibilityLabel(forward ? "Skip forward \(skipInterval) seconds" : "Skip back \(skipInterval) seconds")
    }

    private func timeText(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .minuteSecond))
    }
}

// MARK: - Demo

struct AudioPlayerCardDemo: View {
    private let duration: TimeInterval = 96

    @State private var currentTime: TimeInterval = 18
    @State private var isPlaying = false
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ViewThatFits(in: .vertical) {
                card
                ScrollView { card }
            }
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while currentTime < duration {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                if !isScrubbing { currentTime += 0.25 }
            }
            isPlaying = false
        }
    }

    private var card: some View {
        AudioPlayerCard(
            title: "Small Screens, Big Ideas",
            subtitle: "Episode 12 · Design Notes",
            duration: duration,
            currentTime: $currentTime,
            isPlaying: $isPlaying,
            onScrubbingChanged: { isScrubbing = $0 }
        ) {
            LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                }
        }
        .padding(20)
    }
}

#Preview {
    AudioPlayerCardDemo()
}
