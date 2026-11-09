// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A capsule button whose border is an angular gradient that keeps rotating.
///
/// With Reduce Motion on, the gradient stays still.
struct GradientBorderButton<Content: View>: View {
    var colors: [Color] = [.pink, .orange, .yellow, .mint, .blue, .purple, .pink]
    var lineWidth: Double = 3
    var period: Double = 3
    let action: () -> Void
    @ViewBuilder let label: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            label()
                .font(.title3.bold())
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .overlay {
            TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
                border(at: context.date)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func border(at date: Date) -> some View {
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        let gradient = AngularGradient(
            colors: colors,
            center: .center,
            angle: .degrees(reduceMotion ? 0 : elapsed / period * 360)
        )

        return ZStack {
            Capsule()
                .strokeBorder(gradient, lineWidth: lineWidth)
                .blur(radius: 12)
                .opacity(0.8)
            Capsule()
                .strokeBorder(gradient, lineWidth: lineWidth)
        }
    }
}

// MARK: - Demo

struct GradientBorderButtonDemo: View {
    @State private var isUpgraded = false

    var body: some View {
        GradientBorderButton {
            isUpgraded.toggle()
        } label: {
            Label(isUpgraded ? "Upgraded" : "Upgrade to Pro", systemImage: "crown.fill")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
    }
}

#Preview {
    GradientBorderButtonDemo()
}
