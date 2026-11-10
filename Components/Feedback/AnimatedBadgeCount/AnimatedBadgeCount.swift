// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A count badge whose number rolls to its new value while the capsule springs to fit.
///
/// It hides at zero. With Reduce Motion on, the number changes without moving.
struct AnimatedBadgeCount: View {
    var count: Int
    var maximum = 99
    var tint: Color = .red
    var unit = "new"

    @ScaledMetric(relativeTo: .caption) private var height = 22.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var text: String? {
        AnimatedBadgeCountFormat.text(count: count, maximum: maximum)
    }

    var body: some View {
        ZStack {
            if let text {
                Text(text)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(count)))
                    .padding(.horizontal, height * 0.32)
                    .frame(minWidth: height, minHeight: height)
                    .background(tint, in: .capsule)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .accessibilityLabel("\(text) \(unit)")
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.45), value: text)
    }
}

enum AnimatedBadgeCountFormat {
    /// The text of the badge, or `nil` when there is nothing to count.
    static func text(count: Int, maximum: Int) -> String? {
        guard count > 0 else { return nil }
        let maximum = max(maximum, 1)
        return count > maximum ? "\(maximum)+" : "\(count)"
    }
}

// MARK: - Demo

struct AnimatedBadgeCountDemo: View {
    private static let script = [3, 4, 9, 12, 98, 99, 120, 0, 1, 2]

    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var count: Int { Self.script[step] }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            HStack(spacing: 22) {
                icon("bell.fill", label: "Notifications", tint: .red)
                icon("envelope.fill", label: "Mail", tint: .orange)
                icon("cart.fill", label: "Cart", tint: .green)
            }
            .scaleEffect(1.4)
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.75))
                guard !Task.isCancelled else { return }
                step = (step + 1) % Self.script.count
            }
        }
    }

    private func icon(_ systemImage: String, label: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.largeTitle)
            .foregroundStyle(.white)
            .padding(12)
            .accessibilityLabel(label)
            .overlay(alignment: .topTrailing) {
                AnimatedBadgeCount(count: count, tint: tint)
                    .offset(x: 12, y: -6)
            }
    }
}

#Preview {
    AnimatedBadgeCountDemo()
}
