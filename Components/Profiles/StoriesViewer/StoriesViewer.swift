// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct StoriesViewerStory: Identifiable {
    let id: String
    let image: Image
    var title: String
    var caption: String
    /// What the image shows, for VoiceOver. Leave it nil when the image is decoration.
    var imageLabel: String?
}

/// A full-screen story pager with segmented progress bars.
///
/// Tap the left or right half to move, and hold to pause. Stories do not advance by themselves
/// with Reduce Motion or VoiceOver on: the tap areas still work.
struct StoriesViewer: View {
    let stories: [StoriesViewerStory]
    var duration: TimeInterval = 4
    var onClose: (() -> Void)?
    var onFinish: () -> Void = {}

    @State private var playback = StoriesViewerPlayback()
    @State private var isPressing = false
    @State private var pressStart: Date?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private let holdThreshold: TimeInterval = 0.25

    private var advancesByItself: Bool { !reduceMotion && !voiceOverEnabled }

    private var isRunning: Bool {
        advancesByItself && !isPressing && !playback.isFinished && !stories.isEmpty
    }

    private var current: StoriesViewerStory? {
        stories.indices.contains(playback.index) ? stories[playback.index] : stories.last
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let current {
                Color.clear
                    .overlay { storyImage(current) }
                    .clipped()
                    .ignoresSafeArea()
                    .id(current.id)
                    .transition(.opacity)

                tapAreas

                VStack(spacing: 0) {
                    header(for: current)
                    Spacer(minLength: 24)
                    caption(for: current)
                }
                .opacity(isPressing ? 0 : 1)
                .animation(.easeInOut(duration: 0.2).delay(isPressing ? holdThreshold : 0), value: isPressing)
            }
        }
        .foregroundStyle(.white)
        .task(id: StoriesViewerSchedule(isRunning: isRunning, count: stories.count, duration: duration)) {
            guard isRunning else { return }
            var last = Date.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard !Task.isCancelled else { return }
                let now = Date.now
                let elapsed = now.timeIntervalSince(last)
                last = now
                update { $0.tick(elapsed: elapsed, duration: duration, count: stories.count) }
            }
        }
        .onChange(of: stories.count) { _, count in
            playback.clamp(count: count)
        }
        .onChange(of: playback.isFinished) { _, isFinished in
            if isFinished { onFinish() }
        }
    }

    @ViewBuilder
    private func storyImage(_ story: StoriesViewerStory) -> some View {
        let image = story.image.resizable().scaledToFill()

        if let label = story.imageLabel {
            image.accessibilityLabel(label)
        } else {
            image.accessibilityRepresentation { EmptyView() }
        }
    }

    private var tapAreas: some View {
        HStack(spacing: 0) {
            tapArea("Previous story") {
                update { $0.previous(count: stories.count) }
            }
            tapArea("Next story") {
                update { $0.next(count: stories.count) }
            }
        }
    }

    private func tapArea(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            let wasHold = pressStart.map { Date.now.timeIntervalSince($0) >= holdThreshold } ?? false
            pressStart = nil
            if !wasHold {
                action()
            }
        } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(StoriesViewerTapAreaStyle { isPressed in
            if isPressed { pressStart = .now }
            isPressing = isPressed
        })
        .accessibilityLabel(label)
    }

    private func header(for story: StoriesViewerStory) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(stories.indices, id: \.self) { segment in
                    Capsule()
                        .fill(.white.opacity(0.32))
                        .overlay {
                            Capsule()
                                .fill(.white)
                                .scaleEffect(x: fill(for: segment), anchor: .leading)
                        }
                        .frame(height: 3)
                }
            }
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Story")
            .accessibilityValue("\(min(playback.index + 1, stories.count)) of \(stories.count)")

            HStack {
                Text(story.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .allowsHitTesting(false)
                Spacer()
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func caption(for story: StoriesViewerStory) -> some View {
        Text(story.caption)
            .font(.title3.weight(.semibold))
            .lineLimit(8)
            .minimumScaleFactor(0.6)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .allowsHitTesting(false)
    }

    private func fill(for segment: Int) -> Double {
        if !advancesByItself, segment == playback.index { return 1 }
        return playback.fill(for: segment)
    }

    private func update(_ change: (inout StoriesViewerPlayback) -> Void) {
        var updated = playback
        change(&updated)
        if updated.index == playback.index {
            playback = updated
        } else {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { playback = updated }
        }
    }
}

private struct StoriesViewerSchedule: Equatable {
    let isRunning: Bool
    let count: Int
    let duration: TimeInterval
}

/// Reports touches, including ones the system cancels, so a hold can never get stuck.
private struct StoriesViewerTapAreaStyle: ButtonStyle {
    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .onChange(of: configuration.isPressed) { _, isPressed in
                onPressChange(isPressed)
            }
    }
}

struct StoriesViewerPlayback: Equatable {
    private(set) var index = 0
    private(set) var progress = 0.0
    private(set) var isFinished = false

    mutating func tick(elapsed: TimeInterval, duration: TimeInterval, count: Int) {
        guard count > 0, !isFinished, elapsed > 0 else { return }
        progress += elapsed / max(duration, 0.1)
        if progress >= 1 {
            next(count: count)
        }
    }

    mutating func next(count: Int) {
        guard count > 0, !isFinished else { return }
        if index + 1 < count {
            index += 1
            progress = 0
        } else {
            progress = 1
            isFinished = true
        }
    }

    mutating func previous(count: Int) {
        guard count > 0 else { return }
        isFinished = false
        index = max(index - 1, 0)
        progress = 0
    }

    /// Keeps the position valid when the list of stories changes, and moves on if new ones arrive after the end.
    mutating func clamp(count: Int) {
        if isFinished, index + 1 < count {
            isFinished = false
            index += 1
            progress = 0
            return
        }
        guard index >= count else { return }
        index = max(count - 1, 0)
        progress = 0
    }

    /// How full a segment's bar is, from 0 to 1.
    func fill(for segment: Int) -> Double {
        if segment < index { return 1 }
        return segment == index ? min(max(progress, 0), 1) : 0
    }
}

// MARK: - Demo

struct StoriesViewerDemo: View {
    @State private var run = 0

    private let stories = [
        StoriesViewerStory(
            id: "dawn",
            image: placeholder(colors: [.orange, .pink, .purple], symbol: "sunrise.fill"),
            title: "Morning hike",
            caption: "First light over the ridge.",
            imageLabel: "A sunrise on a pink and purple sky"
        ),
        StoriesViewerStory(
            id: "forest",
            image: placeholder(colors: [.teal, .green, .black], symbol: "tree.fill"),
            title: "Into the woods",
            caption: "Three hours of pure green.",
            imageLabel: "A tree on a dark green background"
        ),
        StoriesViewerStory(
            id: "night",
            image: placeholder(colors: [.indigo, .blue, .black], symbol: "moon.stars.fill"),
            title: "Camp",
            caption: "And then the stars came out.",
            imageLabel: "A moon and stars on a night sky"
        ),
    ]

    var body: some View {
        StoriesViewer(stories: stories, duration: 3, onFinish: { run += 1 })
            .id(run)
    }

    private static func placeholder(colors: [Color], symbol: String) -> Image {
        let size = CGSize(width: 402, height: 874)
        return Image(size: size, opaque: true) { context in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )

            var icon = context.resolve(Image(systemName: symbol))
            icon.shading = .color(.white.opacity(0.35))
            let scale = 200 / max(icon.size.width, icon.size.height, 1)
            let iconSize = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
            context.draw(icon, in: CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            ))
        }
    }
}

#Preview {
    StoriesViewerDemo()
}
