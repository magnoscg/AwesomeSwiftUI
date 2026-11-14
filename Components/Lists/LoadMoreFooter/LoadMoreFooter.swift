// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum LoadMoreFooterPhase: Equatable, Sendable {
    case idle, loading, failed, finished
}

struct LoadMoreFooterPage<Element> {
    let elements: [Element]
    let hasMore: Bool
}

/// Holds the loaded pages and makes sure only one request runs at a time.
@MainActor
@Observable
final class LoadMoreFooterPager<Element> {
    private(set) var elements: [Element] = []
    private(set) var phase = LoadMoreFooterPhase.idle

    private var nextPage = 0
    private let fetch: @MainActor (Int) async throws -> LoadMoreFooterPage<Element>

    init(fetch: @escaping @MainActor (Int) async throws -> LoadMoreFooterPage<Element>) {
        self.fetch = fetch
    }

    func loadNextPage() async {
        guard phase == .idle || phase == .failed else { return }
        phase = .loading
        do {
            let page = try await fetch(nextPage)
            elements += page.elements
            nextPage += 1
            phase = page.hasMore && !page.elements.isEmpty ? .idle : .finished
        } catch is CancellationError {
            phase = .idle
        } catch {
            phase = .failed
        }
    }
}

/// The last row of an infinite list. It asks for the next page as soon as it appears.
struct LoadMoreFooter: View {
    let phase: LoadMoreFooterPhase
    var finishedText = "You're all caught up"
    let onLoad: () -> Void

    var body: some View {
        Group {
            switch phase {
            case .idle:
                ProgressView()
                    .accessibilityLabel("Loading more")
                    .onAppear(perform: onLoad)
            case .loading:
                ProgressView()
                    .accessibilityLabel("Loading more")
            case .failed:
                Button("Try again", systemImage: "arrow.clockwise", action: onLoad)
                    .buttonStyle(.bordered)
            case .finished:
                Text(finishedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Demo

struct LoadMoreFooterDemo: View {
    @State private var pager = LoadMoreFooterPager<Int>(fetch: Self.fetchPage)
    @ScaledMetric(relativeTo: .headline) private var iconSize = 52.0

    private static func fetchPage(_ page: Int) async throws -> LoadMoreFooterPage<Int> {
        try await Task.sleep(for: .seconds(0.9))
        return LoadMoreFooterPage(elements: Array((page * 8)..<((page + 1) * 8)), hasMore: page < 3)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pager.elements, id: \.self, content: row)

                    LoadMoreFooter(phase: pager.phase) {
                        Task { await pager.loadNextPage() }
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Stories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(_ number: Int) -> some View {
        let hue = Double(number % 8) / 8
        return HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(Color(hue: hue, saturation: 0.65, brightness: 0.85).gradient, in: .rect(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Story \(number + 1)").font(.headline)
                Text("A short line about this story")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LoadMoreFooterDemo()
}
