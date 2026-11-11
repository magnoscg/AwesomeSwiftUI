// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A scroll view with a bottom bar that hides while scrolling down and returns on scrolling up.
///
/// With Reduce Motion on, the bar fades instead of sliding. With VoiceOver on, it stays visible.
struct HideOnScrollBar<Content: View, Bar: View>: View {
    var threshold: Double = 16
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bar: () -> Bar

    @State private var tracker = HideOnScrollBarTracker()
    @State private var isHidden = false
    @State private var barHeight: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var hidesBar: Bool { isHidden && !voiceOverEnabled }

    var body: some View {
        ScrollView(content: content)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bar()
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
                    .offset(y: hidesBar && !reduceMotion ? barHeight + 60 : 0)
                    .opacity(hidesBar && reduceMotion ? 0 : 1)
                    .allowsHitTesting(!hidesBar)
                    .animation(reduceMotion ? .linear(duration: 0.15) : .snappy(duration: 0.3), value: hidesBar)
            }
            .onScrollGeometryChange(for: HideOnScrollBarMetrics.self) { geometry in
                HideOnScrollBarMetrics(
                    offset: geometry.contentOffset.y + geometry.contentInsets.top,
                    maxOffset: geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height
                )
            } action: { _, metrics in
                tracker.update(offset: metrics.offset, maxOffset: metrics.maxOffset, threshold: threshold)
                isHidden = tracker.isHidden
            }
    }
}

private struct HideOnScrollBarMetrics: Equatable {
    let offset: Double
    let maxOffset: Double
}

/// Decides when the bar hides, ignoring small movements and the bounce at both ends.
struct HideOnScrollBarTracker: Equatable {
    private(set) var isHidden = false
    private var lastOffset = 0.0
    private var travel = 0.0

    mutating func update(offset: Double, maxOffset: Double, threshold: Double = 16) {
        guard offset > 0, maxOffset > 0 else {
            isHidden = false
            lastOffset = max(offset, 0)
            travel = 0
            return
        }
        guard offset < maxOffset else {
            lastOffset = maxOffset
            return
        }

        let delta = offset - lastOffset
        lastOffset = offset
        guard delta != 0 else { return }

        if (delta > 0) != (travel > 0) {
            travel = 0
        }
        travel += delta

        let required = max(threshold, 0)
        if travel >= required {
            isHidden = true
        } else if travel <= -required {
            isHidden = false
        }
    }
}

// MARK: - Demo

struct HideOnScrollBarDemo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let colors: [Color] = [.indigo, .teal, .orange, .pink, .blue, .green]

    var body: some View {
        ScrollViewReader { proxy in
            HideOnScrollBar {
                VStack(spacing: 12) {
                    ForEach(0..<30, id: \.self) { index in
                        row(index)
                            .id(index)
                    }
                }
                .padding(16)
            } bar: {
                HStack(spacing: 0) {
                    barButton("Home", symbol: "house.fill")
                    barButton("Search", symbol: "magnifyingglass")
                    barButton("Library", symbol: "books.vertical.fill")
                    barButton("Profile", symbol: "person.fill")
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.regularMaterial, in: .capsule)
                .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                .padding(.horizontal, 28)
                .padding(.bottom, 4)
            }
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                var target = 0
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.6))
                    guard !Task.isCancelled else { return }
                    target = target == 12 ? 4 : 12
                    withAnimation(.easeInOut(duration: 1)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colors[index % colors.count].gradient)
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Article \(index + 1)")
                    .font(.headline)
                Text("A short line of supporting text.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func barButton(_ title: String, symbol: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityLabel(title)
    }
}

#Preview {
    HideOnScrollBarDemo()
}
