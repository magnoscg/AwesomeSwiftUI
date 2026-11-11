// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum WhatsNewSheetLogic {
    /// Whether `version` comes after the one that was already shown, comparing number by number,
    /// so 2.10 is newer than 2.9 and 2.0 is the same as 2. Nothing shown yet counts as older.
    static func isNewer(_ version: String, than seen: String) -> Bool {
        let new = numbers(in: version)
        let old = numbers(in: seen)
        for index in 0..<max(new.count, old.count) {
            let left = index < new.count ? new[index] : 0
            let right = index < old.count ? old[index] : 0
            if left != right { return left > right }
        }
        return false
    }

    static func numbers(in version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }

    /// How long a row waits before it comes in, so they arrive one after another without the
    /// last ones of a long list taking too long.
    static func delay(for index: Int, step: Double = 0.12, limit: Double = 0.6) -> Double {
        min(Double(max(index, 0)) * step, limit)
    }
}

struct WhatsNewSheetFeature: Identifiable {
    var symbol: String
    var title: String
    var text: String
    var tint: Color = .accentColor

    var id: String { title }
}

/// The page that tells what a new version brings: a title, a row per feature and a button.
///
/// Show it yourself in a sheet, or let `whatsNewSheet(version:features:)` show it once per version.
/// The rows come in one after another. With Reduce Motion on, they fade in together.
struct WhatsNewSheet: View {
    var title = "What’s New"
    let features: [WhatsNewSheetFeature]
    var buttonTitle = "Continue"
    var onContinue: () -> Void

    private let margin: CGFloat = 32

    @State private var hasAppeared = false
    @ScaledMetric(relativeTo: .title) private var symbolWidth = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 28) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        row(feature)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared || reduceMotion ? 0 : 18)
                            .animation(animation(for: index), value: hasAppeared)
                    }
                }
            }
            .padding(.horizontal, margin)
            .padding(.top, 56)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, margin)
            .padding(.vertical, 12)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
        .onAppear { hasAppeared = true }
    }

    private func row(_ feature: WhatsNewSheetFeature) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.symbol)
                .font(.title)
                .foregroundStyle(feature.tint)
                .frame(width: symbolWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func animation(for index: Int) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.25)
            : .spring(duration: 0.5).delay(WhatsNewSheetLogic.delay(for: index))
    }
}

struct WhatsNewSheetModifier: ViewModifier {
    let version: String
    let title: String
    let features: [WhatsNewSheetFeature]

    @AppStorage private var seenVersion: String
    @State private var isPresented = false

    init(version: String, title: String, features: [WhatsNewSheetFeature], storageKey: String) {
        self.version = version
        self.title = title
        self.features = features
        _seenVersion = AppStorage(wrappedValue: "", storageKey)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: seenVersion, initial: true) {
                if WhatsNewSheetLogic.isNewer(version, than: seenVersion) { isPresented = true }
            }
            .sheet(isPresented: $isPresented) {
                seenVersion = version
            } content: {
                WhatsNewSheet(title: title, features: features) {
                    isPresented = false
                }
            }
    }
}

extension View {
    /// Shows `WhatsNewSheet` the first time the app runs a `version` newer than the last one it
    /// was shown for, and remembers it in `UserDefaults` when the sheet closes.
    func whatsNewSheet(version: String, title: String = "What’s New", features: [WhatsNewSheetFeature], storageKey: String = "WhatsNewSheet.seenVersion") -> some View {
        modifier(WhatsNewSheetModifier(version: version, title: title, features: features, storageKey: storageKey))
    }
}

// MARK: - Demo

struct WhatsNewSheetDemo: View {
    private let storageKey = "WhatsNewSheetDemo.seenVersion"
    private let features = [
        WhatsNewSheetFeature(symbol: "square.and.pencil", title: "Quick Notes", text: "Start a note from anywhere and find it later in its own folder.", tint: .orange),
        WhatsNewSheetFeature(symbol: "tag.fill", title: "Smart Tags", text: "Add a tag as you write and browse every note that shares it.", tint: .teal),
        WhatsNewSheetFeature(symbol: "person.2.fill", title: "Shared Folders", text: "Invite people to a folder and see their changes as they make them.", tint: .indigo),
        WhatsNewSheetFeature(symbol: "lock.fill", title: "Locked Notes", text: "Keep a note behind Face ID, so only you can open it.", tint: .pink),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Notes 2.4")
                .font(.title2.bold())
            Text("The sheet comes up once for each new version.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Show Again", action: forget)
                .buttonStyle(.bordered)
                .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .whatsNewSheet(version: "2.4", features: features, storageKey: storageKey)
        .onAppear(perform: forget)
    }

    /// Forgets the version the sheet was shown for, as if the app had just been updated.
    private func forget() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

#Preview {
    WhatsNewSheetDemo()
}
