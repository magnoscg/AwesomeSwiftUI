// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum SplitFlapCounterMath {
    /// More places than any `Int` needs, so a huge `minimumDigits` cannot allocate without limit.
    static let maximumDigits = 20

    /// One cell per character, padded with zeros on the left and with a leading minus when negative.
    static func cells(for value: Int, minimumDigits: Int) -> [String] {
        let digits = String(value.magnitude).map(String.init)
        let wanted = min(max(minimumDigits, 0), maximumDigits)
        let padding = max(0, wanted - digits.count)
        return (value < 0 ? ["-"] : []) + Array(repeating: "0", count: padding) + digits
    }
}

/// A split-flap display where each digit flips down to its new value.
///
/// With Reduce Motion on, digits change without flipping.
struct SplitFlapCounter: View {
    let value: Int
    var minimumDigits = 1

    var body: some View {
        let cells = SplitFlapCounterMath.cells(for: value, minimumDigits: minimumDigits)

        ViewThatFits(in: .horizontal) {
            row(cells)
            ScrollView(.horizontal, showsIndicators: false) {
                row(cells)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.formatted())
    }

    private func row(_ cells: [String]) -> some View {
        // Identified by their place from the right, so the units stay put when the number grows.
        HStack(spacing: 6) {
            ForEach(Array(cells.indices.reversed()), id: \.self) { place in
                SplitFlapCounterCell(text: cells[cells.count - 1 - place])
            }
        }
    }
}

private struct SplitFlapCounterCell: View {
    let text: String

    @State private var shown: String
    @State private var previous: String
    @State private var flips = 0.0
    @ScaledMetric(relativeTo: .largeTitle) private var height = 92.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(text: String) {
        self.text = text
        _shown = State(initialValue: text)
        _previous = State(initialValue: text)
    }

    var body: some View {
        SplitFlapCounterFace(flips: flips, shown: shown, previous: previous, height: height)
            .onChange(of: text) { _, newText in
                if reduceMotion {
                    previous = newText
                    shown = newText
                } else {
                    previous = shown
                    shown = newText
                    withAnimation(.easeIn(duration: 0.42)) { flips += 1 }
                }
            }
    }
}

/// `flips` grows by one per change. Its fractional part is how far the current flip has gone.
private struct SplitFlapCounterFace: View, Animatable {
    var flips: Double
    let shown: String
    let previous: String
    let height: Double

    nonisolated var animatableData: Double {
        get { flips }
        set { flips = newValue }
    }

    var body: some View {
        let progress = flips - flips.rounded(.down)
        let isFlipping = progress > 0
        let topAngle = isFlipping ? -180 * min(progress, 0.5) : -90
        let bottomAngle = isFlipping ? 180 * (1 - max(progress, 0.5)) : 0

        ZStack {
            VStack(spacing: 2) {
                half(shown, isTop: true)
                half(isFlipping ? previous : shown, isTop: false)
            }

            VStack(spacing: 2) {
                half(previous, isTop: true)
                    .brightness(-0.25 * min(progress * 2, 1))
                    .rotation3DEffect(.degrees(topAngle), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.5)
                    .opacity(topAngle > -90 ? 1 : 0)
                half(shown, isTop: false)
                    .brightness(isFlipping ? -0.25 * (1 - progress) : 0)
                    .rotation3DEffect(.degrees(bottomAngle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.5)
                    .opacity(bottomAngle < 90 ? 1 : 0)
            }
        }
    }

    private func half(_ text: String, isTop: Bool) -> some View {
        let radius = height * 0.1

        return Text(text)
            .font(.system(size: height * 0.68, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: height * 0.68, height: height)
            .frame(height: height / 2, alignment: isTop ? .top : .bottom)
            .clipped()
            .background(
                Color(white: isTop ? 0.2 : 0.16),
                in: UnevenRoundedRectangle(
                    topLeadingRadius: isTop ? radius : 0,
                    bottomLeadingRadius: isTop ? 0 : radius,
                    bottomTrailingRadius: isTop ? 0 : radius,
                    topTrailingRadius: isTop ? radius : 0,
                    style: .continuous
                )
            )
    }
}

// MARK: - Demo

struct SplitFlapCounterDemo: View {
    @State private var value = 1_284
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Text("Passengers today")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            SplitFlapCounter(value: value, minimumDigits: 5)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.06))
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                value += 37
            }
        }
    }
}

#Preview {
    SplitFlapCounterDemo()
}
