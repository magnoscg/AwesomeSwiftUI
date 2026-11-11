// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Custom controls over any video view. A tap shows them and they hide after a few seconds of playback.
///
/// Pass `VideoPlayer(player: player)`, or your own player layer, as the video, and drive
/// `isPlaying` and `currentTime` from it. With VoiceOver on, the controls never hide.
struct VideoPlayerChrome<Video: View>: View {
    private struct HideKey: Hashable {
        let isVisible, isPlaying, isScrubbing: Bool
        let activity: Int
    }

    let title: String
    let duration: TimeInterval
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    var hideDelay: TimeInterval = 3
    @ViewBuilder var video: () -> Video

    @State private var isVisible = true
    @State private var isScrubbing = false
    @State private var activity = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.25) }
    private var showsChrome: Bool { isVisible || voiceOverEnabled }
    private var safeDuration: TimeInterval { duration.isFinite ? min(max(duration, 0), 360_000) : 0 }
    private var position: TimeInterval { currentTime.isFinite ? min(max(currentTime, 0), safeDuration) : 0 }

    private var hideKey: HideKey {
        HideKey(isVisible: isVisible, isPlaying: isPlaying, isScrubbing: isScrubbing, activity: activity)
    }

    var body: some View {
        video()
            .overlay {
                ZStack {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(animation) { isVisible.toggle() }
                        }
                        .accessibilityHidden(true)

                    if showsChrome {
                        chrome.transition(.opacity)
                    }
                }
            }
            .task(id: hideKey) {
                guard isVisible, isPlaying, !isScrubbing, !voiceOverEnabled else { return }
                try? await Task.sleep(for: .seconds(max(hideDelay, 0)))
                guard !Task.isCancelled else { return }
                withAnimation(animation) { isVisible = false }
            }
    }

    private var chrome: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            HStack(spacing: 44) {
                transportButton("gobackward.10", label: "Back 10 seconds") { seek(by: -10) }

                transportButton(isPlaying ? "pause.fill" : "play.fill", label: isPlaying ? "Pause" : "Play", font: .largeTitle) {
                    isPlaying.toggle()
                    activity &+= 1
                }

                transportButton("goforward.10", label: "Forward 10 seconds") { seek(by: 10) }
            }

            Spacer(minLength: 8)

            scrubber
        }
        .padding(16)
        .background {
            LinearGradient(colors: [.black.opacity(0.6), .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private var scrubber: some View {
        VStack(spacing: 2) {
            Slider(
                value: Binding(get: { position }, set: { currentTime = $0 }),
                in: 0...max(safeDuration, 1),
                onEditingChanged: { isScrubbing = $0 }
            )
            .tint(.white)
            .disabled(safeDuration == 0)
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(timeText(position)) of \(timeText(safeDuration))")

            HStack {
                Text(timeText(position))
                Spacer()
                Text(timeText(safeDuration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityHidden(true)
        }
    }

    private func transportButton(
        _ systemImage: String,
        label: String,
        font: Font = .title2,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(font)
                .foregroundStyle(.white)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func seek(by delta: TimeInterval) {
        currentTime = min(max(position + delta, 0), safeDuration)
        activity &+= 1
    }

    private func timeText(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .minuteSecond))
    }
}

// MARK: - Demo

struct VideoPlayerChromeDemo: View {
    private let duration: TimeInterval = 120

    @State private var currentTime: TimeInterval = 34
    @State private var isPlaying = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VideoPlayerChrome(title: "Sunset Over the Bay", duration: duration, currentTime: $currentTime, isPlaying: $isPlaying) {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion || !isPlaying)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                LinearGradient(
                    colors: [.orange, .pink, .indigo],
                    startPoint: UnitPoint(x: 0.5 + sin(time * 0.6) * 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5 - sin(time * 0.6) * 0.5, y: 1)
                )
                .ignoresSafeArea()
            }
            .accessibilityHidden(true)
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while currentTime < duration {
                try? await Task.sleep(for: .seconds(0.25))
                guard !Task.isCancelled else { return }
                currentTime += 0.25
            }
            isPlaying = false
        }
    }
}

#Preview {
    VideoPlayerChromeDemo()
}
