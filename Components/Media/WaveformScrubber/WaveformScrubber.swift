// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum WaveformScrubberMath {
    /// The playback position for a touch at `x`, from 0 to 1.
    static func progress(forX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0, x.isFinite else { return 0 }
        return Double(min(max(x / width, 0), 1))
    }

    /// Averages the samples into `count` bars, each from 0 to 1.
    static func bars(from samples: [Double], count: Int) -> [Double] {
        guard count > 0, !samples.isEmpty else { return [] }
        return (0..<count).map { index in
            let start = index * samples.count / count
            let end = max((index + 1) * samples.count / count, start + 1)
            let bucket = samples[start..<min(end, samples.count)]
            let total = bucket.reduce(0) { $0 + ($1.isFinite ? min(max($1, 0), 1) : 0) }
            return total / Double(bucket.count)
        }
    }

    /// How many bars of this width and spacing fit in `width`.
    static func barCount(width: CGFloat, barWidth: CGFloat, spacing: CGFloat) -> Int {
        let pitch = barWidth + max(spacing, 0)
        guard width > 0, barWidth > 0, pitch > 0, (width / pitch).isFinite else { return 0 }
        return Int(min(width / pitch, 2_000))
    }
}

/// An audio waveform of bars. Drag it to seek. It fills as `progress` moves on.
///
/// `samples` are loudness values from 0 to 1. With Reduce Motion on, the bars don't grow during a drag.
struct WaveformScrubber: View {
    let samples: [Double]
    @Binding var progress: Double
    var tint: Color = .accentColor
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2
    var onScrubbingChanged: (Bool) -> Void = { _ in }

    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var safeProgress: Double { progress.isFinite ? min(max(progress, 0), 1) : 0 }

    var body: some View {
        GeometryReader { proxy in
            canvas
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isDragging) { _, state, _ in state = true }
                        .onChanged { progress = WaveformScrubberMath.progress(forX: $0.location.x, width: proxy.size.width) }
                )
        }
        .scaleEffect(y: isDragging && !reduceMotion ? 1.12 : 1)
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isDragging)
        .onChange(of: isDragging) { _, dragging in onScrubbingChanged(dragging) }
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue(safeProgress.formatted(.percent.precision(.fractionLength(0))))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: progress = min(safeProgress + 0.05, 1)
            case .decrement: progress = max(safeProgress - 0.05, 0)
            @unknown default: break
            }
        }
    }

    private var canvas: some View {
        Canvas { context, size in
            let count = WaveformScrubberMath.barCount(width: size.width, barWidth: barWidth, spacing: spacing)
            let bars = WaveformScrubberMath.bars(from: samples, count: count)
            guard !bars.isEmpty else { return }

            var path = Path()
            for (index, level) in bars.enumerated() {
                let height = max(size.height * level, barWidth)
                let rect = CGRect(
                    x: CGFloat(index) * (barWidth + max(spacing, 0)),
                    y: (size.height - height) / 2,
                    width: barWidth,
                    height: height
                )
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: barWidth / 2, height: barWidth / 2))
            }

            context.fill(path, with: .color(.secondary.opacity(0.35)))

            var played = context
            played.clip(to: Path(CGRect(x: 0, y: 0, width: size.width * safeProgress, height: size.height)))
            played.fill(path, with: .color(tint))
        }
    }
}

// MARK: - Demo

struct WaveformScrubberDemo: View {
    private static let samples = (0..<160).map { index in
        let time = Double(index)
        return min(abs(sin(time * 0.31)) * 0.55 + abs(sin(time * 0.083)) * 0.45, 1)
    }

    @State private var progress = 0.08
    @State private var isPlaying = false
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.12, green: 0.1, blue: 0.3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            WaveformScrubber(samples: Self.samples, progress: $progress, tint: .mint, onScrubbingChanged: { isScrubbing = $0 })
                .frame(height: 130)
                .padding(.horizontal, 20)
                .environment(\.colorScheme, .dark)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                Text("Morning Voice Note").font(.title2.bold())
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.white)
            .padding(.top, 60)
        }
        .overlay(alignment: .bottom) {
            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.mint)
            }
            .accessibilityLabel(isPlaying ? "Pause" : "Play")
            .padding(.bottom, 60)
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { return }
                if !isScrubbing { progress = progress >= 1 ? 0 : min(progress + 0.0035, 1) }
            }
        }
    }
}

#Preview {
    WaveformScrubberDemo()
}
