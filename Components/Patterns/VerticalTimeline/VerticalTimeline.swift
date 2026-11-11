// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct VerticalTimelineStep: Identifiable {
    let id: String
    let title: String
    let detail: String
}

enum VerticalTimelineStatus: Equatable {
    case done, current, upcoming

    /// A `currentIndex` past the end means everything is done, and a negative one that nothing has started.
    static func of(index: Int, currentIndex: Int) -> VerticalTimelineStatus {
        if index < currentIndex { return .done }
        return index == currentIndex ? .current : .upcoming
    }

    var spokenName: String {
        switch self {
        case .done: "Done"
        case .current: "In progress"
        case .upcoming: "Upcoming"
        }
    }
}

/// A vertical list of steps joined by a line, each done, in progress or still to come.
///
/// With Reduce Motion on, the current step does not pulse and changes are not animated.
struct VerticalTimeline: View {
    let steps: [VerticalTimelineStep]
    let currentIndex: Int
    var tint: Color = .indigo

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                row(
                    step,
                    status: .of(index: index, currentIndex: currentIndex),
                    isLast: index == steps.count - 1
                )
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.4), value: currentIndex)
    }

    private func row(_ step: VerticalTimelineStep, status: VerticalTimelineStatus, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                VerticalTimelineMarker(status: status, tint: tint)

                if !isLast {
                    Rectangle()
                        .fill(status == .done ? AnyShapeStyle(tint) : AnyShapeStyle(.quaternary))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(status == .upcoming ? .secondary : .primary)

                Text(step.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 26)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(step.title). \(step.detail)")
        .accessibilityValue(status.spokenName)
    }
}

private struct VerticalTimelineMarker: View {
    let status: VerticalTimelineStatus
    let tint: Color

    @ScaledMetric(relativeTo: .headline) private var size = 26.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch status {
            case .done:
                Circle().fill(tint)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(VerticalTimelineContrastingForeground(background: tint))
            case .current:
                halo
                Circle().fill(tint.opacity(0.18))
                Circle().strokeBorder(tint, lineWidth: 2)
                Circle().fill(tint).frame(width: size * 0.38, height: size * 0.38)
            case .upcoming:
                Circle().strokeBorder(.tertiary, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var halo: some View {
        if !reduceMotion {
            Circle()
                .fill(tint.opacity(0.35))
                .phaseAnimator([false, true]) { circle, isExpanded in
                    circle
                        .scaleEffect(isExpanded ? 1.7 : 1)
                        .opacity(isExpanded ? 0 : 1)
                } animation: { isExpanded in
                    isExpanded ? .easeOut(duration: 1.1) : nil
                }
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct VerticalTimelineContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct VerticalTimelineDemo: View {
    private let steps = [
        VerticalTimelineStep(id: "placed", title: "Order placed", detail: "Monday, 09:24"),
        VerticalTimelineStep(id: "packed", title: "Packed", detail: "Warehouse in Valencia"),
        VerticalTimelineStep(id: "shipped", title: "Shipped", detail: "On its way with your courier"),
        VerticalTimelineStep(id: "out", title: "Out for delivery", detail: "Arriving before 14:00"),
        VerticalTimelineStep(id: "delivered", title: "Delivered", detail: "Leave at the front door"),
    ]

    @State private var currentIndex = 2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Track order")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Order number 2048")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VerticalTimeline(steps: steps, currentIndex: currentIndex)
                    .padding(22)
                    .background(.background.secondary, in: .rect(cornerRadius: 24))
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                currentIndex = currentIndex >= steps.count ? 0 : currentIndex + 1
            }
        }
    }
}

#Preview {
    VerticalTimelineDemo()
}
