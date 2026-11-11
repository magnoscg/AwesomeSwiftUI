// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A horizontal row of tabs that scrolls the selected tab into the middle.
///
/// With Reduce Motion on, the row and the underline jump to the new tab.
struct ScrollingTabStrip: View {
    let tabs: [String]
    @Binding var selection: String
    var tint: Color = .pink

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.35)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 22) {
                    ForEach(tabs, id: \.self) { tab in
                        tabButton(tab)
                            .id(tab)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection, initial: true) { _, newValue in
                withAnimation(animation) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func tabButton(_ tab: String) -> some View {
        let isSelected = tab == selection

        return Button {
            withAnimation(animation) { selection = tab }
        } label: {
            VStack(spacing: 8) {
                Text(tab)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                ZStack {
                    Capsule().fill(.clear)

                    if isSelected {
                        Capsule()
                            .fill(tint)
                            .matchedGeometryEffect(id: "underline", in: namespace)
                    }
                }
                .frame(height: 3)
            }
            .fixedSize()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct ScrollingTabStripDemo: View {
    private let tabs = ["For You", "Trending", "Music", "Sports", "Travel", "Food", "Science", "Design", "Movies", "Gaming"]
    private let symbols = ["sparkles", "flame.fill", "music.note", "figure.run", "airplane", "fork.knife", "atom", "paintbrush.fill", "film.fill", "gamecontroller.fill"]

    @State private var selection = "For You"

    private var index: Int { tabs.firstIndex(of: selection) ?? 0 }

    var body: some View {
        VStack(spacing: 18) {
            ScrollingTabStrip(tabs: tabs, selection: $selection)
                .padding(.top, 12)

            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .hueRotation(.degrees(Double(index) * 34))

                VStack(spacing: 16) {
                    Image(systemName: symbols[index])
                        .font(.largeTitle)
                        .imageScale(.large)
                        .contentTransition(.symbolEffect(.replace))
                        .accessibilityHidden(true)

                    Text("Stories about \(selection)")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    ScrollingTabStripDemo()
}
