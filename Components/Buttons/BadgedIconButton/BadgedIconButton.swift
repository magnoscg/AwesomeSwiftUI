// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum BadgedIconButtonBadge {
    /// The text of the badge: none at zero, and `99+` past the limit.
    static func text(for count: Int, limit: Int = 99) -> String? {
        guard count > 0 else { return nil }
        return count > limit ? "\(limit)+" : "\(count)"
    }
}

/// An icon button, like a bell or a cart, with a count in a badge on its corner.
/// The badge pops in when the count appears, its number rolls as it changes,
/// and the icon bounces when the count goes up.
///
/// With Reduce Motion on, the badge fades and the icon stays still.
struct BadgedIconButton: View {
    let title: LocalizedStringResource
    let systemImage: String
    let count: Int
    var limit = 99
    var badgeColor: Color = .red
    let action: () -> Void

    @State private var bounces = 0
    @ScaledMetric(relativeTo: .title2) private var size = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var badgeText: String? {
        BadgedIconButtonBadge.text(for: count, limit: limit)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolEffect(.bounce, value: bounces)
                .frame(width: size, height: size)
                .overlay(alignment: .topTrailing) {
                    if let badgeText {
                        Text(badgeText)
                            .font(.caption2.bold())
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(count)))
                            .foregroundStyle(BadgedIconButtonContrastingForeground(background: badgeColor))
                            .padding(.horizontal, 5)
                            .frame(minWidth: size * 0.42, minHeight: size * 0.42)
                            .background(badgeColor, in: .capsule)
                            .fixedSize()
                            .alignmentGuide(.top) { $0.height * 0.3 }
                            .alignmentGuide(.trailing) { $0.width * 0.7 }
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    }
                }
                .contentShape(.rect)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.5), value: count)
        .accessibilityLabel(title)
        .accessibilityValue(Text(verbatim: badgeText ?? ""))
        .onChange(of: count) { old, new in
            if new > old, !reduceMotion { bounces += 1 }
        }
    }
}

nonisolated struct BadgedIconButtonContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct BadgedIconButtonDemo: View {
    @State private var notifications = 96
    @State private var messages = 2
    @State private var cartItems = 0
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("Inbox")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                BadgedIconButton(title: "Messages", systemImage: "bubble.left", count: messages) {
                    messages = 0
                }
                BadgedIconButton(title: "Cart", systemImage: "cart", count: cartItems, badgeColor: .yellow) {
                    cartItems = 0
                }
                BadgedIconButton(title: "Notifications", systemImage: "bell", count: notifications) {
                    notifications = 0
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Text("Tap an icon to clear its badge.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task {
            var step = 0
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled, isAutoPlaying else { return }
                switch step % 3 {
                case 0: notifications += 2
                case 1: cartItems += 1
                default: messages += 1
                }
                step += 1
            }
        }
    }
}

#Preview {
    BadgedIconButtonDemo()
}
