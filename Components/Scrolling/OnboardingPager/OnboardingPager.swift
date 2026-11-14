// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct OnboardingPagerPage {
    var symbol: String
    var title: LocalizedStringResource
    var message: LocalizedStringResource
    var colors: [Color]
}

/// A full-screen onboarding flow with swipeable pages, a progress indicator and a button
/// that advances or finishes. `onFinish` runs once.
struct OnboardingPager: View {
    let pages: [OnboardingPagerPage]
    var finishTitle: LocalizedStringResource = "Get Started"
    var onFinish: () -> Void = {}

    @State private var page = 0
    @State private var didFinish = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLastPage: Bool { page >= pages.count - 1 }

    var body: some View {
        if pages.isEmpty {
            Color.clear
        } else {
            VStack(spacing: 20) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPagerContent(page: item, isActive: index == page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                indicator

                Button(action: advance) {
                    Text(isLastPage ? finishTitle : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(.white, in: .capsule)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .foregroundStyle(.white)
            .background {
                LinearGradient(colors: currentColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: page)
            .sensoryFeedback(.selection, trigger: page)
            .onChange(of: pages.count) { _, count in
                page = min(page, max(count - 1, 0))
            }
        }
    }

    private var currentColors: [Color] {
        pages.indices.contains(page) ? pages[page].colors : [.black]
    }

    private var indicator: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(.white.opacity(index == page ? 1 : 0.4))
                        .frame(width: index == page ? 28 : 8, height: 8)
                }
            }
            Text("\(page + 1) / \(pages.count)")
                .font(.footnote.monospacedDigit())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(min(page + 1, pages.count)) of \(pages.count)")
    }

    private func advance() {
        if isLastPage {
            guard !didFinish else { return }
            didFinish = true
            onFinish()
        } else {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.4)) { page += 1 }
        }
    }
}

private struct OnboardingPagerContent: View {
    let page: OnboardingPagerPage
    let isActive: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 96
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            Image(systemName: page.symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .symbolEffect(.bounce, value: reduceMotion ? false : isActive)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text(page.message)
                    .font(.body)
                    .opacity(0.85)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Demo

struct OnboardingPagerDemo: View {
    @State private var run = 0

    private let pages = [
        OnboardingPagerPage(symbol: "sparkles", title: "Welcome", message: "A calmer way to keep track of your day.", colors: [.indigo, .purple]),
        OnboardingPagerPage(symbol: "bell.badge.fill", title: "Stay on Time", message: "Gentle reminders, only when they matter.", colors: [.orange, .pink]),
        OnboardingPagerPage(symbol: "checkmark.seal.fill", title: "All Set", message: "Your first list is ready and waiting.", colors: [.teal, .blue]),
    ]

    var body: some View {
        OnboardingPager(pages: pages, onFinish: { run += 1 })
            .id(run)
    }
}

#Preview {
    OnboardingPagerDemo()
}
