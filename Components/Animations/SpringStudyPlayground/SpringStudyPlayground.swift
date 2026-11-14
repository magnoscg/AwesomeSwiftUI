// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum SpringStudyPlaygroundMath {
    static let responseRange = 0.1...1.5
    static let dampingRange = 0.1...1.0

    static func clamped(_ value: Double, to range: ClosedRange<Double>) -> Double {
        value.isNaN ? range.lowerBound : min(max(value, range.lowerBound), range.upperBound)
    }

    /// The position of a spring going from 0 to 1, sampled evenly over `duration` seconds.
    static func samples(response: Double, damping: Double, count: Int, duration: Double) -> [Double] {
        guard count > 1, duration > 0, duration.isFinite else { return [] }
        let spring = Spring(
            response: clamped(response, to: responseRange),
            dampingRatio: clamped(damping, to: dampingRange)
        )
        let last = min(count, 512) - 1
        return (0...last).map { spring.value(target: 1.0, time: duration * Double($0) / Double(last)) }
    }
}

nonisolated private struct SpringStudyPlaygroundCurve: Shape {
    let samples: [Double]
    let maximum: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count > 1, maximum > 0 else { return path }
        let points = samples.enumerated().map { index, value in
            CGPoint(
                x: rect.minX + rect.width * Double(index) / Double(samples.count - 1),
                y: rect.maxY - rect.height * value / maximum
            )
        }
        path.addLines(points)
        return path
    }
}

/// Sliders for response and damping that show how a spring moves a view, with its curve drawn below.
///
/// With Reduce Motion on, the ball jumps and the curve still shows what the spring would do.
struct SpringStudyPlayground: View {
    private enum Preset: String, CaseIterable, Identifiable {
        case smooth = "Smooth"
        case bouncy = "Bouncy"
        case stiff = "Stiff"

        var id: Self { self }

        var values: (response: Double, damping: Double) {
            switch self {
            case .smooth: (0.8, 1)
            case .bouncy: (0.75, 0.3)
            case .stiff: (0.2, 0.75)
            }
        }
    }

    /// The curve's scale. A spring with the lowest damping overshoots to almost this.
    private static let curveMaximum = 1.9
    private static let presetSpacing: CGFloat = 10

    @State private var response: Double
    @State private var damping: Double
    @State private var isAtEnd = false
    @ScaledMetric(relativeTo: .title2) private var ballSize = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(response: Double = 0.55, damping: Double = 0.55) {
        _response = State(initialValue: SpringStudyPlaygroundMath.clamped(response, to: SpringStudyPlaygroundMath.responseRange))
        _damping = State(initialValue: SpringStudyPlaygroundMath.clamped(damping, to: SpringStudyPlaygroundMath.dampingRange))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                stage
                curve
                slider("Response", value: $response, range: SpringStudyPlaygroundMath.responseRange, unit: " s")
                slider("Damping", value: $damping, range: SpringStudyPlaygroundMath.dampingRange, unit: "")
                presets
            }
            .padding(20)
        }
    }

    private var stage: some View {
        Circle()
            .fill(.linearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom))
            .frame(width: ballSize, height: ballSize)
            .frame(maxWidth: .infinity, alignment: isAtEnd ? .trailing : .leading)
            .padding(10)
            .background(.quaternary, in: Capsule())
            .accessibilityHidden(true)
    }

    private var curve: some View {
        let settling = Spring(response: response, dampingRatio: damping).settlingDuration
        // The curve covers the time the spring takes to settle, so it always reaches the line.
        let samples = SpringStudyPlaygroundMath.samples(response: response, damping: damping, count: 120, duration: max(settling, 1))

        return VStack(alignment: .leading, spacing: 10) {
            ZStack {
                GeometryReader { proxy in
                    Path { path in
                        let y = proxy.size.height * (1 - 1 / Self.curveMaximum)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                SpringStudyPlaygroundCurve(samples: samples, maximum: Self.curveMaximum)
                    .stroke(.pink, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 150)
            .accessibilityHidden(true)

            Text("Settles in \(settling.formatted(.number.precision(.fractionLength(1)))) s")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        let text = value.wrappedValue.formatted(.number.precision(.fractionLength(2))) + unit

        return VStack(spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(text).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)

            Slider(value: value, in: range) { Text(title) }
                .accessibilityValue(text)
                .tint(.pink)
        }
    }

    private var presets: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Self.presetSpacing) { presetButtons }
            VStack(spacing: Self.presetSpacing) { presetButtons }
        }
    }

    @ViewBuilder private var presetButtons: some View {
        ForEach(Preset.allCases) { preset in
            Button {
                response = preset.values.response
                damping = preset.values.damping
                play()
            } label: {
                // In a narrow row a name shrinks a little before it would break in two.
                Text(preset.rawValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }

        Button(action: play) {
            Text("Play").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.pink)
    }

    private func play() {
        withAnimation(reduceMotion ? nil : .spring(response: response, dampingFraction: damping)) {
            isAtEnd.toggle()
        }
    }
}

// MARK: - Demo

struct SpringStudyPlaygroundDemo: View {
    var body: some View {
        SpringStudyPlayground()
    }
}

#Preview {
    SpringStudyPlaygroundDemo()
}
