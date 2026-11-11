// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// An avatar with a gradient ring that spins while there are unseen stories.
///
/// `placeholder` shows while the image loads or when there is no URL. With Reduce Motion on,
/// the ring stays still.
struct StoryRingAvatar<Placeholder: View>: View {
    let name: String
    var url: URL?
    var hasUnseenStories: Bool = true
    var size: CGFloat = 72
    var colors: [Color] = [.yellow, .orange, .pink, .purple, .yellow]
    @ViewBuilder var placeholder: () -> Placeholder

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spins: Bool { hasUnseenStories && !reduceMotion }

    var body: some View {
        let diameter = max(size, 0)
        let ringWidth = diameter * 0.05
        let photoSize = max(diameter - ringWidth * 4, 0)

        ZStack {
            Circle()
                .strokeBorder(.quaternary, lineWidth: max(ringWidth * 0.5, 1))

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !spins)) { timeline in
                Circle()
                    .strokeBorder(AngularGradient(colors: colors, center: .center), lineWidth: ringWidth)
                    .rotationEffect(.degrees(spins ? angle(at: timeline.date) : 0))
            }
            .opacity(hasUnseenStories ? 1 : 0)

            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder()
                }
            }
            .frame(width: photoSize, height: photoSize)
            .clipShape(.circle)
        }
        .frame(width: diameter, height: diameter)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: hasUnseenStories)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(hasUnseenStories ? "New stories" : "No new stories")
    }

    private func angle(at date: Date) -> Double {
        (date.timeIntervalSinceReferenceDate * 90).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Demo

struct StoryRingAvatarDemo: View {
    private struct Friend: Identifiable {
        let id: String
        let symbol: String
        let colors: [Color]
    }

    private let friends = [
        Friend(id: "Ana", symbol: "person.fill", colors: [.pink, .orange]),
        Friend(id: "Leo", symbol: "pawprint.fill", colors: [.teal, .blue]),
        Friend(id: "Mia", symbol: "camera.fill", colors: [.purple, .indigo]),
        Friend(id: "Noa", symbol: "music.note", colors: [.green, .mint]),
    ]

    @State private var seen: Set<String> = ["Noa"]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ScrollView(.horizontal) {
                HStack(spacing: 18) {
                    ForEach(friends) { friend in
                        Button {
                            if seen.remove(friend.id) == nil { seen.insert(friend.id) }
                        } label: {
                            VStack(spacing: 8) {
                                avatar(for: friend, size: 74)
                                Text(friend.id)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(friend.id)
                        .accessibilityValue(seen.contains(friend.id) ? "No new stories" : "New stories")
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)

            avatar(for: friends[0], size: 190)

            Text("Tap a friend to mark their stories as seen.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func avatar(for friend: Friend, size: CGFloat) -> some View {
        StoryRingAvatar(name: friend.id, hasUnseenStories: !seen.contains(friend.id), size: size) {
            ZStack {
                LinearGradient(colors: friend.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: friend.symbol)
                    .font(.system(size: size * 0.38))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    StoryRingAvatarDemo()
}
