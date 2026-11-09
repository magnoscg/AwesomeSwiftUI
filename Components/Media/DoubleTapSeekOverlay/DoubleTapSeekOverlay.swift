// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum DoubleTapSeekOverlaySide: Sendable {
    case backward, forward
}

/// Adds up repeated double taps on one side, like "+10 s" then "+20 s".
struct DoubleTapSeekOverlayTally: Equatable {
    private(set) var side: DoubleTapSeekOverlaySide?
    private(set) var seconds = 0.0

    static func side(forX x: CGFloat, width: CGFloat) -> DoubleTapSeekOverlaySide {
        x < width / 2 ? .backward : .forward
    }

    mutating func record(_ newSide: DoubleTapSeekOverlaySide, interval: Double) {
        seconds = side == newSide ? seconds + interval : interval
        side = newSide
    }

    mutating func reset() {
        self = DoubleTapSeekOverlayTally()
    }
}

/// Double tap the left or right half of a video to skip back or forward.
///
/// `onSeek` receives the seconds to move, negative when going back. VoiceOver users
/// get the same skips as named actions. With Reduce Motion on, the ripple is left out.
struct DoubleTapSeekOverlay<Video: View>: View {
    var interval = 10.0
    let onSeek: (Double) -> Void
    @ViewBuilder var video: () -> Video

    @State private var tally = DoubleTapSeekOverlayTally()
    @State private var tapCount = 0
    @State private var tapLocation = CGPoint.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .easeOut(duration: 0.2) }
    private var intervalText: String { interval.formatted() }

    var body: some View {
        video()
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        Color.clear
                            .contentShape(.rect)
                            .gesture(
                                SpatialTapGesture(count: 2).onEnded { value in
                                    tapLocation = value.location
                                    seek(DoubleTapSeekOverlayTally.side(forX: value.location.x, width: proxy.size.width))
                                }
                            )
                            .accessibilityElement()
                            .accessibilityLabel("Seek area")
                            .accessibilityAction(named: "Skip back \(intervalText) seconds") { seek(.backward) }
                            .accessibilityAction(named: "Skip forward \(intervalText) seconds") { seek(.forward) }

                        if let side = tally.side {
                            feedback(side, in: proxy.size).transition(.opacity)
                        }
                    }
                }
            }
            .task(id: tapCount) {
                guard tapCount > 0 else { return }
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
                withAnimation(animation) { tally.reset() }
            }
    }

    private func feedback(_ side: DoubleTapSeekOverlaySide, in size: CGSize) -> some View {
        let halfWidth = size.width / 2
        let isForward = side == .forward
        let rippleCenter = CGPoint(x: isForward ? tapLocation.x - halfWidth : tapLocation.x, y: tapLocation.y)

        return ZStack {
            Color.black.opacity(0.22)

            if !reduceMotion {
                DoubleTapSeekOverlayRipple(center: rippleCenter, diameter: max(size.width, size.height))
                    .id(tapCount)
            }

            VStack(spacing: 6) {
                Image(systemName: isForward ? "forward.fill" : "backward.fill").font(.title2)
                Text("\(isForward ? "+" : "-")\(tally.seconds.formatted()) s")
                    .font(.headline.monospacedDigit())
            }
            .foregroundStyle(.white)
        }
        .frame(width: max(halfWidth, 0), height: max(size.height, 0))
        .clipped()
        .frame(maxWidth: .infinity, alignment: isForward ? .trailing : .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func seek(_ side: DoubleTapSeekOverlaySide) {
        guard interval > 0 else { return }
        withAnimation(animation) { tally.record(side, interval: interval) }
        tapCount &+= 1
        onSeek(side == .backward ? -interval : interval)
    }
}

private struct DoubleTapSeekOverlayRipple: View {
    let center: CGPoint
    let diameter: CGFloat

    @State private var isExpanded = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.35))
            .frame(width: diameter, height: diameter)
            .scaleEffect(isExpanded ? 1 : 0.1)
            .opacity(isExpanded ? 0 : 1)
            .position(center)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { isExpanded = true }
            }
    }
}

// MARK: - Demo

struct DoubleTapSeekOverlayDemo: View {
    private let duration = 180.0

    @State private var position = 60.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Double tap either side")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                DoubleTapSeekOverlay(onSeek: { position = min(max(position + $0, 0), duration) }) {
                    videoPlaceholder
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 16))

                ProgressView(value: position, total: duration)
                    .tint(.red)
                    .accessibilityLabel("Playback position")

                Text(Duration.seconds(position).formatted(.time(pattern: .minuteSecond)))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
        }
    }

    private var videoPlaceholder: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [.indigo, .purple, .orange],
                startPoint: UnitPoint(x: 0.5 + sin(time * 0.7) * 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5 - sin(time * 0.7) * 0.5, y: 1)
            )
        }
        .overlay {
            Image(systemName: "film")
                .font(.system(.largeTitle, weight: .light))
                .foregroundStyle(.white.opacity(0.45))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    DoubleTapSeekOverlayDemo()
}
