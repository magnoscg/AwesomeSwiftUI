// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum ProfileHeaderStretchyMath {
    /// How tall the cover is for a scroll offset: it grows when the content is pulled down,
    /// and shrinks with the scroll until it is the bar.
    static func coverHeight(offset: CGFloat, expanded: CGFloat, collapsed: CGFloat) -> CGFloat {
        max(expanded - offset, min(collapsed, expanded))
    }

    /// From 0, the whole cover, to 1, only the bar.
    static func progress(offset: CGFloat, expanded: CGFloat, collapsed: CGFloat) -> Double {
        let travel = expanded - collapsed
        guard travel > 0 else { return 1 }
        return Double(min(max(offset / travel, 0), 1))
    }

    /// The avatar gets smaller as the cover closes, and is gone a little before it is the bar.
    static func avatarScale(progress: Double) -> Double {
        1 - 0.45 * min(max(progress, 0), 1)
    }

    static func avatarOpacity(progress: Double) -> Double {
        1 - min(max((progress - 0.55) / 0.35, 0), 1)
    }

    /// The name shows in the bar over the last stretch, once the avatar is gone.
    static func titleOpacity(progress: Double) -> Double {
        min(max((progress - 0.8) / 0.2, 0), 1)
    }
}

/// A profile whose cover stretches when the page is pulled down and closes into a bar with the
/// name as it scrolls, while the avatar on its edge shrinks away.
///
/// The cover and the avatar follow the scroll itself, so there is nothing to slow down for
/// Reduce Motion. Put it at the top of a screen: the cover runs under the status bar.
struct ProfileHeaderStretchy<Cover: View, Avatar: View, Content: View>: View {
    let name: String
    var coverHeight: CGFloat = 190
    @ViewBuilder var cover: () -> Cover
    @ViewBuilder var avatar: () -> Avatar
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @ScaledMetric(relativeTo: .title) private var avatarSize = 88.0

    private let barHeight: CGFloat = 44
    private let margin: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let collapsed = proxy.safeAreaInsets.top + barHeight
            let progress = ProfileHeaderStretchyMath.progress(offset: offset, expanded: coverHeight, collapsed: collapsed)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Room for the cover, and for the half of the avatar that hangs under it.
                    Color.clear
                        .frame(height: coverHeight + avatarSize / 2 + 12)

                    content()
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, new in
                offset = new
            }
            .overlay(alignment: .top) {
                header(height: ProfileHeaderStretchyMath.coverHeight(offset: offset, expanded: coverHeight, collapsed: collapsed), progress: progress)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private func header(height: CGFloat, progress: Double) -> some View {
        cover()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .overlay {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(progress)
            }
            .overlay(alignment: .bottom) {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(height: barHeight)
                    .padding(.horizontal, margin)
                    .opacity(ProfileHeaderStretchyMath.titleOpacity(progress: progress))
                    .accessibilityHidden(progress < 1)
            }
            .overlay(alignment: .bottomLeading) {
                avatar()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(.circle)
                    .overlay { Circle().stroke(.background, lineWidth: 4) }
                    .scaleEffect(ProfileHeaderStretchyMath.avatarScale(progress: progress), anchor: .bottomLeading)
                    .opacity(ProfileHeaderStretchyMath.avatarOpacity(progress: progress))
                    .padding(.leading, margin)
                    // Half of it hangs under the cover.
                    .alignmentGuide(.bottom) { $0[VerticalAlignment.center] }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Demo

struct ProfileHeaderStretchyDemo: View {
    private let posts = ["Morning light over the bay", "Notes from the design review", "A slow Sunday in the hills", "Why I draw every day", "The best coffee in Lisbon", "Sketches for the next app", "Ten minutes of quiet", "What the sea taught me", "Small tools, big ideas", "Walking home at dusk"]

    var body: some View {
        ProfileHeaderStretchy(name: "Maya Okafor") {
            LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: "mountain.2.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.top, 60)
                        .accessibilityHidden(true)
                }
        } avatar: {
            LinearGradient(colors: [.indigo, .teal], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Text("MO")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Maya Okafor")
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maya Okafor")
                        .font(.title2.bold())
                    Text("Designer. Draws, walks and writes about both.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 28) {
                    stat("128", "Posts")
                    stat("4.2K", "Followers")
                    stat("310", "Following")
                }

                Divider()

                ForEach(posts, id: \.self) { post in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityHidden(true)
                        Text(post)
                            .font(.body)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func stat(_ value: String, _ label: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ProfileHeaderStretchyDemo()
}
