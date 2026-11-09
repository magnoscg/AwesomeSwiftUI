// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// The time math of the ring, apart from the view so it can be tested.
enum CountdownRingMath {
    static func remaining(now: Date, endDate: Date, duration: TimeInterval) -> TimeInterval {
        min(max(endDate.timeIntervalSince(now), 0), max(duration, 0))
    }

    static func fraction(remaining: TimeInterval, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(remaining / duration, 0), 1)
    }

    /// Rounds up, so the number only reaches 0 when the time is really over.
    static func wholeSeconds(remaining: TimeInterval) -> Int {
        Int(max(remaining, 0).rounded(.up))
    }

    /// `45` below a minute, `1:05` from then on.
    static func text(seconds: Int, locale: Locale = .autoupdatingCurrent) -> String {
        guard seconds >= 60 else {
            return seconds.formatted(.number.locale(locale))
        }
        return Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond).locale(locale))
    }
}

/// A ring that empties and a number that counts down to `endDate`. Give it a frame to size it.
///
/// With Reduce Motion on, the ring moves once per second instead of continuously.
struct CountdownRing: View {
    var endDate: Date
    var duration: TimeInterval
    var colors: [Color] = [.orange, .pink]
    var lineWidth: CGFloat = 18
    var font: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    var onFinish: (() -> Void)? = nil

    @State private var isFinished = false
    @State private var notifiedEndDate: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1.0 / 30.0, paused: isFinished)) { context in
            let remaining = CountdownRingMath.remaining(
                now: isFinished ? endDate : context.date,
                endDate: endDate,
                duration: duration
            )
            let seconds = CountdownRingMath.wholeSeconds(remaining: remaining)
            let fraction = CountdownRingMath.fraction(
                remaining: reduceMotion ? TimeInterval(seconds) : remaining,
                duration: duration
            )

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(CountdownRingMath.text(seconds: seconds))
                    .font(font)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(seconds)))
                    .animation(reduceMotion ? nil : .snappy, value: seconds)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(lineWidth + 4)
            }
            .padding(lineWidth / 2)
            .accessibilityElement()
            .accessibilityLabel("Time remaining")
            .accessibilityValue("\(seconds) seconds")
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: endDate) {
            isFinished = false
            let delay = endDate.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            isFinished = true
            guard notifiedEndDate != endDate else { return }
            notifiedEndDate = endDate
            onFinish?()
        }
    }
}

// MARK: - Demo

struct CountdownRingDemo: View {
    @State private var endDate = Date.now.addingTimeInterval(3)
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = 96

    private let duration: TimeInterval = 3

    var body: some View {
        VStack(spacing: 36) {
            Text("Get ready")
                .font(.system(.title, design: .rounded, weight: .bold))

            CountdownRing(
                endDate: endDate,
                duration: duration,
                lineWidth: 26,
                font: .system(size: numberSize, weight: .bold, design: .rounded)
            )
            .frame(width: 280)

            Text("Your next set starts soon")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(duration + 0.8))
                endDate = Date.now.addingTimeInterval(duration)
            }
        }
    }
}

#Preview {
    CountdownRingDemo()
}
