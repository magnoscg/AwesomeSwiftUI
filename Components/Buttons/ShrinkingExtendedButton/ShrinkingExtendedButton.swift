// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum ShrinkingExtendedButtonMath {
    /// Rubber-banding past the top gives a negative offset, which counts as being at the top.
    static func shouldExtend(offset: CGFloat, threshold: CGFloat) -> Bool {
        offset <= max(threshold, 0)
    }
}

/// An extended floating button that shrinks from a labeled pill to a plain icon.
///
/// Pass `isExtended`, or drive it from a scroll view with `ShrinkingExtendedButtonScrollTracker`.
/// With Reduce Motion on, it changes shape without animating.
struct ShrinkingExtendedButton: View {
    let title: LocalizedStringResource
    let systemImage: String
    var isExtended = true
    var tint: Color = .indigo
    let action: () -> Void

    @ScaledMetric(relativeTo: .headline) private var height = 58.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))

                if isExtended {
                    Text(title)
                        .font(.headline)
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                }
            }
            .foregroundStyle(ShrinkingExtendedButtonContrastingForeground(background: tint))
            .padding(.horizontal, isExtended ? 22 : 0)
            .frame(minWidth: height, minHeight: height)
            .background(tint.gradient, in: Capsule())
            .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.15), value: isExtended)
    }
}

/// Apply to a scroll view to set `isExtended` from how far it has moved from the top.
struct ShrinkingExtendedButtonScrollTracker: ViewModifier {
    @Binding var isExtended: Bool
    var threshold: CGFloat = 40

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: Bool.self) { geometry in
            ShrinkingExtendedButtonMath.shouldExtend(
                offset: geometry.contentOffset.y + geometry.contentInsets.top,
                threshold: threshold
            )
        } action: { _, shouldExtend in
            isExtended = shouldExtend
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct ShrinkingExtendedButtonContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct ShrinkingExtendedButtonDemo: View {
    @State private var isExtended = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<30, id: \.self) { index in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hue: Double(index % 8) / 8, saturation: 0.55, brightness: 0.9))
                                .frame(width: 44, height: 44)
                                .accessibilityHidden(true)
                            Text("Message \(index + 1)")
                                .font(.headline)
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(16)
            }
            .modifier(ShrinkingExtendedButtonScrollTracker(isExtended: $isExtended))

            ShrinkingExtendedButton(title: "New Message", systemImage: "square.and.pencil", isExtended: isExtended) {}
                .padding(24)
        }
    }
}

#Preview {
    ShrinkingExtendedButtonDemo()
}
