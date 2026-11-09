// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Page dots where the current one stretches into a capsule. Bind `current` to a paged `TabView` or a scroll position.
///
/// With Reduce Motion on, the capsule changes without animating.
struct PageDotsIndicator: View {
    let count: Int
    let current: Int
    var tint: Color = .primary

    @ScaledMetric(relativeTo: .caption) private var dotSize = 8.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: dotSize) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                Capsule()
                    .fill(tint.opacity(index == current ? 1 : 0.25))
                    .frame(width: index == current ? dotSize * 3 : dotSize, height: dotSize)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.3), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(current + 1) of \(count)")
    }
}

// MARK: - Demo

struct PageDotsIndicatorDemo: View {
    private let pages: [(title: String, symbol: String, colors: [Color])] = [
        ("Plan your trip", "map.fill", [.blue, .indigo]),
        ("Book in seconds", "ticket.fill", [.pink, .orange]),
        ("Pack with a list", "suitcase.fill", [.teal, .green]),
        ("Share the memories", "camera.fill", [.purple, .pink]),
    ]

    @State private var page = 0

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: pages[index].symbol)
                            .font(.largeTitle)
                            .imageScale(.large)
                            .accessibilityHidden(true)

                        Text(pages[index].title)
                            .font(.title.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(colors: pages[index].colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .rect(cornerRadius: 32)
                    )
                    .padding(.horizontal, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDotsIndicator(count: pages.count, current: page)
                .padding(.bottom, 16)
        }
    }
}

#Preview {
    PageDotsIndicatorDemo()
}
