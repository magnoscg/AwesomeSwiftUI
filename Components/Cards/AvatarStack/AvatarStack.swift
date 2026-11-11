// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum AvatarStackMath {
    /// Splits a number of people into the avatars to draw and the count for the badge.
    static func visibleAndOverflow(count: Int, maxVisible: Int) -> (visible: Int, overflow: Int) {
        let visible = min(max(count, 0), max(maxVisible, 0))
        return (visible, max(count, 0) - visible)
    }

    /// The first letters of the first and last words of a name.
    static func initials(of name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        guard let first = words.first?.first else { return "?" }
        guard words.count > 1, let last = words.last?.first else { return String(first).uppercased() }
        return "\(first)\(last)".uppercased()
    }
}

/// Overlapping avatars of initials, with a +N badge for everyone who does not fit.
struct AvatarStack: View {
    let names: [String]
    var maxVisible = 4
    var diameter: CGFloat = 48

    @ScaledMetric(relativeTo: .body) private var textScale = 1.0

    private var size: CGFloat { diameter * textScale }

    private static var palette: [Color] { [.indigo, .pink, .orange, .teal, .purple, .blue] }

    private var split: (visible: Int, overflow: Int) {
        AvatarStackMath.visibleAndOverflow(count: names.count, maxVisible: maxVisible)
    }

    var body: some View {
        HStack(spacing: -size * 0.28) {
            ForEach(Array(names.prefix(split.visible).enumerated()), id: \.offset) { index, name in
                circle(AvatarStackMath.initials(of: name), fill: color(for: name))
                    .zIndex(Double(-index))
                    .transition(.scale.combined(with: .opacity))
            }

            if split.overflow > 0 {
                circle("+\(split.overflow)", fill: .gray)
                    .contentTransition(.numericText())
                    .zIndex(Double(-split.visible))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(names.isEmpty ? "No people" : names.formatted(.list(type: .and)))
    }

    private func circle(_ text: String, fill: Color) -> some View {
        Text(text)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(fill.gradient, in: .circle)
            .overlay { Circle().strokeBorder(.background, lineWidth: 3) }
    }

    private func color(for name: String) -> Color {
        let total = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[total % Self.palette.count]
    }
}

// MARK: - Demo

struct AvatarStackDemo: View {
    private let everyone = ["Ana Ruiz", "Luis Vega", "Marta Gil", "Omar Haddad", "Nora Lind", "Pablo Sanz", "Yuki Mori", "Sara Blanco", "Tomás Rey"]

    @State private var count = 3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Design review")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Today at 16:30")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AvatarStack(names: Array(everyone.prefix(count)), diameter: 64)
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: .rect(cornerRadius: 28))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)

            HStack(spacing: 14) {
                Button("Remove", systemImage: "person.badge.minus") { change(by: -1) }
                    .disabled(count == 0)
                Button("Add", systemImage: "person.badge.plus") { change(by: 1) }
                    .disabled(count == everyone.count)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.purple.opacity(0.4), .orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func change(by amount: Int) {
        withAnimation(reduceMotion ? nil : .bouncy(duration: 0.4)) { count += amount }
    }
}

#Preview {
    AvatarStackDemo()
}
