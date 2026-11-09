// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A single line that scrolls horizontally, only when it does not fit.
///
/// With Reduce Motion on, a long line is truncated instead of scrolling.
struct MarqueeText: View {
    let text: String
    /// Points per second.
    var speed: Double = 42
    /// Seconds to wait at the start of each lap.
    var pause: Double = 1

    @ScaledMetric(relativeTo: .body) private var gap = 48.0
    @State private var textWidth = 0.0
    @State private var containerWidth = 0.0
    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scrolls: Bool {
        containerWidth > 0 && textWidth > containerWidth && speed > 0 && !reduceMotion
    }

    var body: some View {
        Text(text)
            .lineLimit(1)
            .opacity(scrolls ? 0 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: Double.self) { $0.size.width } action: { containerWidth = $0 }
            .background {
                Text(text)
                    .lineLimit(1)
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: Double.self) { $0.size.width } action: { textWidth = $0 }
            }
            .overlay(alignment: .leading) {
                if scrolls { scrollingCopies }
            }
            .mask {
                if scrolls {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.03),
                            .init(color: .black, location: 0.92),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.black
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .task(id: text) { start = .now }
    }

    /// The second copy follows the first, so the end of a lap looks just like its start.
    private var scrollingCopies: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            HStack(spacing: gap) {
                Text(text)
                Text(text)
            }
            .lineLimit(1)
            .fixedSize()
            .offset(x: -offset(at: context.date))
        }
    }

    private func offset(at date: Date) -> Double {
        let lapDistance = textWidth + gap
        let lapDuration = pause + lapDistance / speed
        let timeInLap = date.timeIntervalSince(start).truncatingRemainder(dividingBy: lapDuration)
        return max(timeInLap - pause, 0) * speed
    }
}

// MARK: - Demo

struct MarqueeTextDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.linearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .fontWeight(.semibold)
                            .padding(80)
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    MarqueeText(text: "The Very Long Song Title That Could Never Fit on One Line")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    MarqueeText(text: "Short and still")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    MarqueeTextDemo()
}
