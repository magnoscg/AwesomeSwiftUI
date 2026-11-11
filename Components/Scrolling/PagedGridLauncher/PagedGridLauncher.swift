// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct PagedGridLauncherItem: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let colors: [Color]
}

/// A launcher of icon grids that pages horizontally, each page filled row by row.
struct PagedGridLauncher: View {
    let items: [PagedGridLauncherItem]
    @Binding var page: Int
    var columns: Int = 4
    var rows: Int = 5
    var onSelect: (PagedGridLauncherItem) -> Void = { _ in }

    @State private var scrolledPage: Int?

    @ScaledMetric(relativeTo: .caption2) private var iconSize: CGFloat = 60
    private let pageDotSize: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columnCount: Int {
        let requested = PagedGridLauncherLayout.clamped(columns)
        return dynamicTypeSize.isAccessibilitySize ? min(requested, 2) : requested
    }

    private var pages: [Range<Int>] {
        PagedGridLauncherLayout.pages(itemCount: items.count, columns: columnCount, rows: rows)
    }

    var body: some View {
        let pages = pages

        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolledPage)

            pageIndicator(count: pages.count)
        }
        .onAppear { scrolledPage = page }
        .onChange(of: scrolledPage) { _, value in
            if let value, value != page {
                page = value
            }
        }
        .onChange(of: page) { _, value in
            if value != scrolledPage {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.45)) { scrolledPage = value }
            }
        }
        .onChange(of: pages.count) { _, count in
            page = min(page, max(count - 1, 0))
        }
    }

    private func pageView(_ range: Range<Int>) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount), spacing: 20) {
                ForEach(items[range]) { item in
                    icon(for: item)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func icon(for item: PagedGridLauncherItem) -> some View {
        Button {
            onSelect(item)
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: iconSize * 0.24, style: .continuous)
                    .fill(LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: iconSize, height: iconSize)
                    .overlay {
                        Image(systemName: item.symbol)
                            .font(.system(size: iconSize * 0.46, weight: .medium))
                            .foregroundStyle(.white)
                    }
                Text(item.title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }

    private func pageIndicator(count: Int) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(.primary.opacity(index == page ? 0.9 : 0.25))
                        .frame(width: pageDotSize, height: pageDotSize)
                }
            }
            Text("\(page + 1) / \(count)")
                .font(.caption.monospacedDigit())
        }
        .animation(reduceMotion ? nil : .snappy, value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(min(page + 1, count)) of \(count)")
        .accessibilityAdjustableAction { direction in
            let target = direction == .increment ? page + 1 : page - 1
            if (0..<count).contains(target) {
                page = target
            }
        }
    }
}

enum PagedGridLauncherLayout {
    static func clamped(_ value: Int) -> Int {
        min(max(value, 1), 12)
    }

    /// Splits the items into page-sized ranges, filling each page before the next one.
    static func pages(itemCount: Int, columns: Int, rows: Int) -> [Range<Int>] {
        guard itemCount > 0 else { return [] }
        let perPage = clamped(columns) * clamped(rows)
        return stride(from: 0, to: itemCount, by: perPage).map { start in
            start..<(itemCount - start > perPage ? start + perPage : itemCount)
        }
    }
}

// MARK: - Demo

struct PagedGridLauncherDemo: View {
    @State private var page = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let palettes: [[Color]] = [
        [.blue, .cyan], [.pink, .orange], [.green, .mint], [.purple, .indigo], [.orange, .yellow], [.teal, .blue], [.red, .pink],
    ]

    private static let apps: [(String, String)] = [
        ("Mail", "envelope.fill"), ("Maps", "map.fill"), ("Music", "music.note"), ("Photos", "photo.fill"),
        ("Clock", "clock.fill"), ("Notes", "note.text"), ("Files", "folder.fill"), ("Books", "book.fill"),
        ("Camera", "camera.fill"), ("Wallet", "wallet.pass.fill"), ("Weather", "cloud.sun.fill"), ("Home", "house.fill"),
        ("Health", "heart.fill"), ("News", "newspaper.fill"), ("Stocks", "chart.line.uptrend.xyaxis"), ("Calendar", "calendar"),
        ("Phone", "phone.fill"), ("Chat", "message.fill"), ("Video", "video.fill"), ("Radio", "dot.radiowaves.left.and.right"),
    ]

    private let items: [PagedGridLauncherItem] = (0..<46).map { index in
        let app = apps[index % apps.count]
        return PagedGridLauncherItem(id: "\(index)", title: app.0, symbol: app.1, colors: palettes[index % palettes.count])
    }

    var body: some View {
        PagedGridLauncher(items: items, page: $page)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.indigo.opacity(0.35), .teal.opacity(0.25)], startPoint: .top, endPoint: .bottom))
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.3))
                    guard !Task.isCancelled else { return }
                    page = (page + 1) % 3
                }
            }
    }
}

#Preview {
    PagedGridLauncherDemo()
}
