// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Converts between values, tick indices and scroll offsets. Bad input yields a usable scale.
struct RulerScrollPickerScale: Equatable {
    static let maximumTickCount = 20_000

    let lowerBound: Double
    let step: Double
    let tickCount: Int

    init(range: ClosedRange<Double>, step: Double) {
        let safeStep = step.isFinite && step > 0 ? step : 1
        let quotient = (range.upperBound - range.lowerBound) / safeStep
        // 0.1 has no exact binary form, so 0.3 / 0.1 lands just under 3.
        let ticks = abs(quotient - quotient.rounded()) < 1e-9 ? quotient.rounded() : quotient.rounded(.down)

        lowerBound = range.lowerBound
        self.step = safeStep
        tickCount = ticks.isFinite ? Int(min(max(ticks, 0), Double(Self.maximumTickCount - 1))) + 1 : 1
    }

    func value(at index: Int) -> Double {
        lowerBound + Double(min(max(index, 0), tickCount - 1)) * step
    }

    func index(for value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return clampedIndex(((value - lowerBound) / step).rounded())
    }

    func index(forOffset offset: CGFloat, spacing: CGFloat) -> Int {
        guard offset.isFinite, spacing > 0 else { return 0 }
        return clampedIndex(Double((offset / spacing).rounded()))
    }

    private func clampedIndex(_ index: Double) -> Int {
        guard index.isFinite else { return 0 }
        return Int(min(max(index, 0), Double(tickCount - 1)))
    }
}

/// A ruler of tick marks that snaps to a value under a fixed center indicator.
///
/// Dragging writes the value, and changing the value from outside scrolls the ruler.
/// With Reduce Motion on, outside changes jump instead of gliding.
struct RulerScrollPicker: View {
    let title: LocalizedStringResource
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var step: Double = 1
    var majorEvery: Int = 10
    var tickSpacing: CGFloat = 12
    var tint: Color = .indigo

    @State private var position = ScrollPosition(x: 0)
    @State private var phase = ScrollPhase.idle
    @State private var currentIndex = 0
    @ScaledMetric(relativeTo: .caption) private var labelHeight = 22.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tickHeight = 48.0

    private var scale: RulerScrollPickerScale { RulerScrollPickerScale(range: range, step: step) }
    private var spacing: CGFloat { tickSpacing.isFinite ? max(tickSpacing, 4) : 12 }
    private var major: Int { max(majorEvery, 1) }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<scale.tickCount, id: \.self) { index in
                        tick(at: index)
                    }
                }
                .padding(.horizontal, max((proxy.size.width - spacing) / 2, 0))
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(RulerScrollPickerSnap(spacing: spacing))
            .scrollPosition($position)
            .onScrollPhaseChange { _, newPhase in phase = newPhase }
            .onScrollGeometryChange(for: Int.self) { geometry in
                scale.index(forOffset: geometry.contentOffset.x, spacing: spacing)
            } action: { _, newIndex in
                userScrolled(to: newIndex)
            }
        }
        .frame(height: tickHeight + labelHeight + 8)
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.18),
                .init(color: .black, location: 0.82),
                .init(color: .clear, location: 1),
            ], startPoint: .leading, endPoint: .trailing)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(tint)
                .frame(width: 4, height: tickHeight + 8)
                .allowsHitTesting(false)
        }
        .sensoryFeedback(.selection, trigger: currentIndex)
        .onAppear { syncScroll(animated: false) }
        .onChange(of: value) { syncScroll(animated: true) }
        .onChange(of: scale) { syncScroll(animated: false) }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue(value.formatted())
        .accessibilityAdjustableAction { direction in
            let index = scale.index(for: value)
            switch direction {
            case .increment: value = scale.value(at: index + 1)
            case .decrement: value = scale.value(at: index - 1)
            @unknown default: break
            }
        }
    }

    private func tick(at index: Int) -> some View {
        let isMajor = index % major == 0
        let isMiddle = !isMajor && major >= 2 && index % (major / 2) == 0

        return Capsule()
            .fill(isMajor ? Color.primary : Color.secondary.opacity(0.6))
            .frame(width: isMajor ? 2.5 : 1.5, height: isMajor ? tickHeight : isMiddle ? tickHeight * 0.7 : tickHeight * 0.45)
            .frame(width: spacing, height: tickHeight + labelHeight + 8, alignment: .top)
            .overlay(alignment: .bottom) {
                if isMajor {
                    Text(scale.value(at: index).formatted())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
    }

    private func userScrolled(to index: Int) {
        guard phase.isScrolling, phase != .animating else { return }

        currentIndex = index
        let newValue = scale.value(at: index)
        if newValue != value {
            value = newValue
        }
    }

    private func syncScroll(animated: Bool) {
        guard !phase.isScrolling || phase == .animating else { return }

        let index = scale.index(for: value)
        guard !animated || index != currentIndex else { return }

        currentIndex = index
        let offset = CGFloat(index) * spacing
        if animated, !reduceMotion {
            withAnimation(.smooth(duration: 0.7)) { position.scrollTo(x: offset) }
        } else {
            position.scrollTo(x: offset)
        }
    }
}

private struct RulerScrollPickerSnap: ScrollTargetBehavior {
    let spacing: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.x = (target.rect.minX / spacing).rounded() * spacing
    }
}

// MARK: - Demo

struct RulerScrollPickerDemo: View {
    @State private var weight = 62.0
    @State private var lastAutoValue = 62.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tour = [78.5, 55.0, 91.0, 62.0]

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                Text("Your weight")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(weight, format: .number.precision(.fractionLength(1)))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: weight))

                    Text("kg")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .animation(reduceMotion ? nil : .smooth(duration: 0.7), value: weight)

                RulerScrollPicker(title: "Weight in kilograms", value: $weight, range: 40...120, step: 0.5)
            }
            .padding(.vertical, 24)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            for target in tour + tour + tour {
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled, weight == lastAutoValue else { return }
                lastAutoValue = target
                weight = target
            }
        }
    }
}

#Preview {
    RulerScrollPickerDemo()
}
