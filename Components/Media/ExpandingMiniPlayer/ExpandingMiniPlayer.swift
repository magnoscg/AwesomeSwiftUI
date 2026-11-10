// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A mini player over your content that grows into a full player when tapped or pulled up.
///
/// Pull the full player down, or use its close button, to shrink it again.
/// With Reduce Motion on, the two states swap without morphing.
struct ExpandingMiniPlayer<Content: View, Artwork: View>: View {
    private enum MorphID: Hashable { case background, artwork }

    let title: String
    let subtitle: String
    @Binding var isPlaying: Bool
    /// From 0 to 1.
    var progress = 0.0
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}
    @ViewBuilder var content: () -> Content
    @ViewBuilder var artwork: () -> Artwork

    @State private var isExpanded = false
    @GestureState private var dragOffset: CGFloat = 0
    @Namespace private var namespace
    @ScaledMetric(relativeTo: .subheadline) private var barHeight = 64.0
    @ScaledMetric(relativeTo: .subheadline) private var miniArtworkSize = 46.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minTouchTarget: CGFloat = 44
    private let miniBarSpacing: CGFloat = 12

    private var safeProgress: Double { progress.isFinite ? min(max(progress, 0), 1) : 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .safeAreaPadding(.bottom, barHeight + 16)
                .accessibilityHidden(isExpanded)

            if isExpanded {
                fullPlayer.zIndex(1)
            } else {
                miniBar
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.1), value: dragOffset)
    }

    // MARK: Mini player

    private var miniBar: some View {
        HStack(spacing: miniBarSpacing) {
            Button { setExpanded(true) } label: {
                HStack(spacing: miniBarSpacing) {
                    artwork()
                        .frame(width: miniArtworkSize, height: miniArtworkSize)
                        .clipShape(.rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: MorphID.artwork, in: namespace)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.subheadline.weight(.semibold))
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .accessibilityLabel("Open player")
            .accessibilityValue("\(title), \(subtitle)")

            playButton(font: .title3)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .frame(minHeight: barHeight)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
                .matchedGeometryEffect(id: MorphID.background, in: namespace)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .offset(y: min(dragOffset, 0) * 0.25)
        .simultaneousGesture(dragGesture)
    }

    // MARK: Full player

    private var fullPlayer: some View {
        VStack(spacing: 24) {
            Button { setExpanded(false) } label: {
                Image(systemName: "chevron.compact.down")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: minTouchTarget)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Close player")

            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { artwork() }
                .clipShape(.rect(cornerRadius: 28))
                .matchedGeometryEffect(id: MorphID.artwork, in: namespace)
                .frame(maxWidth: 360)
                .layoutPriority(-1)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.body).foregroundStyle(.secondary)
            }
            .lineLimit(2)
            .multilineTextAlignment(.center)

            ProgressView(value: safeProgress)
                .accessibilityLabel("Playback position")

            HStack(spacing: 44) {
                transportButton("backward.fill", label: "Previous", action: onPrevious)
                playButton(font: .largeTitle)
                transportButton("forward.fill", label: "Next", action: onNext)
            }

            Spacer(minLength: 0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.thickMaterial)
                .matchedGeometryEffect(id: MorphID.background, in: namespace)
                .ignoresSafeArea()
        }
        .contentShape(.rect)
        .gesture(dragGesture)
        .offset(y: max(dragOffset, 0))
        .accessibilityAction(.escape) { setExpanded(false) }
    }

    // MARK: Parts

    private func playButton(font: Font) -> some View {
        Button { isPlaying.toggle() } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(font)
                .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
                .contentShape(.rect)
        }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }

    private func transportButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title)
                .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
                .contentShape(.rect)
        }
        .accessibilityLabel(label)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, offset, _ in
                offset = value.translation.height
            }
            .onEnded { value in
                let distance = value.translation.height
                let predicted = value.predictedEndTranslation.height
                if isExpanded {
                    if distance > 120 || predicted > 320 { setExpanded(false) }
                } else if distance < -40 || predicted < -160 {
                    setExpanded(true)
                }
            }
    }

    private func setExpanded(_ expanded: Bool) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.15)) {
            isExpanded = expanded
        }
    }
}

// MARK: - Demo

struct ExpandingMiniPlayerDemo: View {
    private let songs = ["Midnight Drive", "Paper Planes", "Slow Tides", "Golden Hour", "Neon Rain", "Open Road", "Quiet Storm", "First Light"]

    @State private var isPlaying = false
    @State private var progress = 0.2
    @ScaledMetric(relativeTo: .body) private var coverSize = 48.0

    var body: some View {
        ExpandingMiniPlayer(
            title: "Midnight Drive",
            subtitle: "The Night Owls",
            isPlaying: $isPlaying,
            progress: progress
        ) {
            NavigationStack {
                List(songs, id: \.self) { song in
                    HStack(spacing: 14) {
                        cover.frame(width: coverSize, height: coverSize)
                            .clipShape(.rect(cornerRadius: 10))
                            .accessibilityHidden(true)
                        Text(song).font(.body)
                    }
                }
                .navigationTitle("Library")
            }
        } artwork: {
            cover
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                progress = progress >= 1 ? 0 : progress + 0.004
            }
        }
    }

    private var cover: some View {
        LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .foregroundStyle(.white.opacity(0.9))
            }
    }
}

#Preview {
    ExpandingMiniPlayerDemo()
}
