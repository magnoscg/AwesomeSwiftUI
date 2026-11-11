// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A scroll view that shows a floating button after scrolling down, which returns to the top.
///
/// With Reduce Motion on, the button fades and the view jumps to the top.
struct ScrollToTopButton<Content: View>: View {
    var threshold: CGFloat = 320
    var tint: Color = .indigo
    @ViewBuilder var content: Content

    @State private var position = ScrollPosition(edge: .top)
    @State private var isVisible = false
    @ScaledMetric(relativeTo: .title3) private var buttonSize = 52.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            content
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > threshold
        } action: { _, isPastThreshold in
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.35)) {
                isVisible = isPastThreshold
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isVisible {
                button
                    .padding(20)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            }
        }
    }

    private var button: some View {
        Button {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.5)) {
                position.scrollTo(edge: .top)
            }
        } label: {
            Image(systemName: "arrow.up")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: buttonSize, height: buttonSize)
                .background(tint.gradient, in: .circle)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to top")
    }
}

// MARK: - Demo

struct ScrollToTopButtonDemo: View {
    private let colors: [Color] = [.indigo, .blue, .teal, .green, .orange, .pink]

    var body: some View {
        ScrollToTopButton {
            LazyVStack(spacing: 14) {
                ForEach(0..<30, id: \.self) { index in
                    HStack(spacing: 14) {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(colors[index % colors.count].gradient, in: .rect(cornerRadius: 14))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Story \(index + 1)")
                                .font(.headline)
                            Text("A short description of this story")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(.regularMaterial, in: .rect(cornerRadius: 18))
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    ScrollToTopButtonDemo()
}
