// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct FullScreenMenuOverlayLink: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let systemImage: String
    let action: () -> Void
}

/// A full-screen menu whose links arrive one by one. Add it on top of your content.
///
/// With Reduce Motion on, the menu and its links appear at once.
struct FullScreenMenuOverlay: View {
    @Binding var isPresented: Bool
    let links: [FullScreenMenuOverlayLink]
    var colors: [Color] = [.indigo, .purple, .pink]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isPresented {
                FullScreenMenuOverlayPanel(
                    links: links,
                    colors: colors,
                    close: { isPresented = false }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: isPresented)
    }
}

private struct FullScreenMenuOverlayPanel: View {
    let links: [FullScreenMenuOverlayLink]
    let colors: [Color]
    let close: () -> Void

    @State private var showsLinks = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Scrolls only when large text makes the links taller than the screen.
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(links.enumerated()), id: \.element.id) { index, link in
                        row(for: link)
                            .opacity(showsLinks ? 1 : 0)
                            .offset(y: showsLinks ? 0 : 28)
                            .animation(animation(forRow: index), value: showsLinks)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 90)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.2), in: .circle)
            }
            .accessibilityLabel("Close")
            .padding(20)
        }
        .onAppear { showsLinks = true }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, close)
    }

    private func animation(forRow index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return .spring(duration: 0.55, bounce: 0.25).delay(0.12 + 0.08 * Double(min(index, 12)))
    }

    private func row(for link: FullScreenMenuOverlayLink) -> some View {
        Button {
            close()
            link.action()
        } label: {
            Label(link.title, systemImage: link.systemImage)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Demo

struct FullScreenMenuOverlayDemo: View {
    @State private var isOpen = false
    @State private var page = "Studio"

    private var links: [FullScreenMenuOverlayLink] {
        [
            ("Studio", "paintpalette.fill"),
            ("Projects", "square.grid.2x2.fill"),
            ("Journal", "book.fill"),
            ("Contact", "paperplane.fill"),
        ].map { title, systemImage in
            FullScreenMenuOverlayLink(id: title, title: "\(title)", systemImage: systemImage) { page = title }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("Menu", systemImage: "line.3.horizontal") { isOpen = true }
                        .labelStyle(.iconOnly)
                        .font(.title2.weight(.semibold))
                        .padding(20)
                }

                Spacer()

                Text(page)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.opacity)

                Spacer()
            }
            .accessibilityHidden(isOpen)

            FullScreenMenuOverlay(isPresented: $isOpen, links: links)
        }
    }
}

#Preview {
    FullScreenMenuOverlayDemo()
}
