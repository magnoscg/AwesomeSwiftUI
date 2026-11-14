// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A tab view with a Liquid Glass accessory above a tab bar that minimizes on scroll.
///
/// With Reduce Motion on, the tab bar stays at its full size.
@available(iOS 26, *)
struct GlassTabAccessory<Selection: Hashable, Tabs: TabContent<Selection>, Accessory: View>: View {
    @Binding var selection: Selection
    var minimizeBehavior: TabBarMinimizeBehavior = .onScrollDown
    @TabContentBuilder<Selection> let tabs: () -> Tabs
    @ViewBuilder let accessory: () -> Accessory

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $selection, content: tabs)
            .tabBarMinimizeBehavior(reduceMotion ? .never : minimizeBehavior)
            .tabViewBottomAccessory(content: accessory)
    }
}

// MARK: - Demo

@available(iOS 26, *)
private struct GlassTabAccessoryPlayer: View {
    @Binding var isPlaying: Bool

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, isActive: isPlaying && !reduceMotion)
                .foregroundStyle(.pink)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("Midnight Drive")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if placement != .inline {
                    Text("The Glass Hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Button {
                isPlaying.toggle()
            } label: {
                // The glyph is too small to hit. The padding widens what answers to a touch,
                // and the same padding taken back keeps the accessory as it was.
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .padding(17)
                    .contentShape(.rect)
                    .padding(-17)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}

@available(iOS 26, *)
struct GlassTabAccessoryDemo: View {
    @State private var selection = "albums"
    @State private var isPlaying = true

    var body: some View {
        GlassTabAccessory(selection: $selection) {
            Tab("Albums", systemImage: "square.stack.fill", value: "albums") {
                shelf(title: "New music", colors: [.pink, .orange, .purple, .blue, .teal])
            }
            Tab("Radio", systemImage: "dot.radiowaves.left.and.right", value: "radio") {
                shelf(title: "On air", colors: [.indigo, .mint, .red, .cyan, .yellow])
            }
        } accessory: {
            GlassTabAccessoryPlayer(isPlaying: $isPlaying)
        }
    }

    private func shelf(title: String, colors: [Color]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                ForEach(0..<24, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colors[index % colors.count].gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Text(title)
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
                .background(.bar)
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassTabAccessoryDemo()
}
