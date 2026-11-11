// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A poster with a play button that opens into the playing video, in the same frame.
///
/// Pass any views: usually `Image("poster").resizable().scaledToFill()` and
/// `VideoPlayer(player: player)`. Start and stop your player from `isPlaying`.
/// With Reduce Motion on, the video fades in instead of opening from the button.
struct VideoPosterToPlayer<Poster: View, Player: View>: View {
    @Binding var isPlaying: Bool
    var aspectRatio: CGFloat = 16.0 / 9.0
    var cornerRadius: CGFloat = 22
    @ViewBuilder var poster: () -> Poster
    @ViewBuilder var player: () -> Player

    @ScaledMetric(relativeTo: .title) private var buttonSize = 72.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .smooth(duration: 0.6) }

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 16.0 / 9.0, contentMode: .fit)
            .overlay { poster().accessibilityHidden(true) }
            .overlay {
                if isPlaying {
                    player().transition(reduceMotion ? .opacity : AnyTransition(VideoPosterToPlayerReveal()))
                }
            }
            .overlay(alignment: .topTrailing) {
                if isPlaying {
                    Button {
                        withAnimation(animation) { isPlaying = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.5), in: .circle)
                            // The padding is part of the button, so all of it answers to a touch.
                            .padding(10)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Close video")
                    .transition(.opacity)
                }
            }
            .overlay {
                if !isPlaying {
                    Button {
                        withAnimation(animation) { isPlaying = true }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play video")
                    .transition(reduceMotion ? .opacity : .scale(scale: 1.8).combined(with: .opacity))
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

/// Reveals the player through a circle that grows from the center until it covers the frame.
private struct VideoPosterToPlayerReveal: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content.mask {
            GeometryReader { proxy in
                let diameter = hypot(proxy.size.width, proxy.size.height)

                Circle()
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(phase.isIdentity ? 1 : 0.05)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }
}

// MARK: - Demo

struct VideoPosterToPlayerDemo: View {
    @State private var isPlaying = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.1), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VideoPosterToPlayer(isPlaying: $isPlaying) {
                    LinearGradient(colors: [.teal, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(alignment: .bottomLeading) {
                            Label("Trailer", systemImage: "film")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(16)
                        }
                } player: {
                    videoPlaceholder
                }

                Text("The Long Way Home")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(isPlaying ? "Now playing" : "A two-minute trailer about a very long walk.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(20)
        }
    }

    private var videoPlaceholder: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion || !isPlaying)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [.orange, .pink, .purple],
                startPoint: UnitPoint(x: 0.5 + sin(time * 0.9) * 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5 - sin(time * 0.9) * 0.5, y: 1)
            )
        }
        .overlay {
            Image(systemName: "waveform")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.6))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VideoPosterToPlayerDemo()
}
