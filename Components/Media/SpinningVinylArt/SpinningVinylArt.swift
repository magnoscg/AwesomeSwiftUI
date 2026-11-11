// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// The disc's angle over time. Speed ramps linearly after each change, so nothing jumps.
struct SpinningVinylArtSpin: Equatable {
    private var startAngle = 0.0
    private var startSpeed = 0.0
    private var targetSpeed = 0.0
    private var changedAt = Date.distantPast
    var ramp: TimeInterval = 0.9

    init(ramp: TimeInterval = 0.9) {
        self.ramp = ramp
    }

    func angle(at date: Date) -> Double {
        let elapsed = max(date.timeIntervalSince(changedAt), 0)
        let rampTime = max(ramp, 0)
        let duringRamp = min(elapsed, rampTime)
        let change = rampTime > 0 ? (targetSpeed - startSpeed) / rampTime : 0
        return startAngle + startSpeed * duringRamp + change * duringRamp * duringRamp / 2
            + targetSpeed * max(elapsed - rampTime, 0)
    }

    func speed(at date: Date) -> Double {
        let rampTime = max(ramp, 0)
        guard rampTime > 0 else { return targetSpeed }
        let fraction = min(max(date.timeIntervalSince(changedAt), 0) / rampTime, 1)
        return startSpeed + (targetSpeed - startSpeed) * fraction
    }

    mutating func setSpeed(_ speed: Double, at date: Date) {
        startAngle = angle(at: date).truncatingRemainder(dividingBy: 360)
        startSpeed = self.speed(at: date)
        targetSpeed = speed
        changedAt = date
    }
}

/// Circular album art that spins while playing and eases to a stop when paused.
///
/// Pass any view as the art, usually `Image("cover").resizable().scaledToFill()`.
/// With Reduce Motion on, the disc stays still.
struct SpinningVinylArt<Artwork: View>: View {
    let isPlaying: Bool
    /// Revolutions per minute. A 33 rpm record is slow enough to read the label.
    var rpm = 33.0
    var accessibilityName = "Album art"
    @ViewBuilder var artwork: () -> Artwork

    @State private var spin = SpinningVinylArtSpin()
    @State private var isEasing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var degreesPerSecond: Double { rpm.isFinite ? min(max(rpm, -1_000), 1_000) * 6 : 0 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion || !(isPlaying || isEasing))) { context in
            disc.rotationEffect(.degrees(reduceMotion ? 0 : spin.angle(at: context.date)))
        }
        .overlay {
            Circle()
                .fill(AngularGradient(colors: [.clear, .white.opacity(0.22), .clear, .white.opacity(0.16), .clear], center: .center))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(accessibilityName)
        .task(id: [isPlaying, reduceMotion]) {
            guard !reduceMotion else { return }
            spin.setSpeed(isPlaying ? degreesPerSecond : 0, at: .now)
            isEasing = !isPlaying
            guard !isPlaying else { return }
            try? await Task.sleep(for: .seconds(max(spin.ramp, 0) + 0.05))
            guard !Task.isCancelled else { return }
            isEasing = false
        }
        .onChange(of: degreesPerSecond) {
            guard isPlaying, !reduceMotion else { return }
            spin.setSpeed(degreesPerSecond, at: .now)
        }
    }

    private var disc: some View {
        GeometryReader { proxy in
            let side = max(min(proxy.size.width, proxy.size.height), 0)

            ZStack {
                Circle().fill(Color(white: 0.08))

                ForEach(1..<8, id: \.self) { ring in
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                        .padding(side * CGFloat(ring) * 0.028)
                }

                artwork()
                    .frame(width: side * 0.6, height: side * 0.6)
                    .clipShape(.circle)

                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: side * 0.05, height: side * 0.05)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Demo

struct SpinningVinylArtDemo: View {
    @State private var isPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                SpinningVinylArt(isPlaying: isPlaying) {
                    LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay {
                            Image(systemName: "music.quarternote.3")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                }
                .padding(.horizontal, 28)

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(.largeTitle, weight: .regular))
                        .imageScale(.large)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(isPlaying ? 2.2 : 1.4))
                guard !Task.isCancelled else { return }
                isPlaying.toggle()
            }
        }
    }
}

#Preview {
    SpinningVinylArtDemo()
}
