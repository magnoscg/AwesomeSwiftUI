// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

extension View {
    /// Wobbles the view, like an app icon in edit mode.
    ///
    /// Give each view a different `seed` so they do not move in step.
    func jiggleEditing(_ isActive: Bool, amplitude: Double = 2.4, seed: Int = 0) -> some View {
        modifier(JiggleEditModifier(isActive: isActive, amplitude: amplitude, seed: seed))
    }
}

/// With Reduce Motion on, the view stays still.
struct JiggleEditModifier: ViewModifier {
    var isActive: Bool
    var amplitude: Double
    var seed: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isJiggling: Bool { isActive && !reduceMotion }

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isJiggling)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate * 22 + Double(seed) * 2.4

            content
                .rotationEffect(.degrees(isJiggling ? sin(phase) * amplitude : 0))
                .offset(y: isJiggling ? cos(phase * 0.9) * 0.6 : 0)
                .animation(.easeOut(duration: 0.2), value: isJiggling)
        }
    }
}

// MARK: - Demo

private struct JiggleEditDemoApp: Identifiable {
    let id: String
    let systemImage: String
    let colors: [Color]
}

struct JiggleEditModifierDemo: View {
    private static let allApps = [
        JiggleEditDemoApp(id: "Mail", systemImage: "envelope.fill", colors: [.cyan, .blue]),
        JiggleEditDemoApp(id: "Music", systemImage: "music.note", colors: [.pink, .red]),
        JiggleEditDemoApp(id: "Photos", systemImage: "camera.macro", colors: [.yellow, .orange]),
        JiggleEditDemoApp(id: "Maps", systemImage: "map.fill", colors: [.mint, .green]),
        JiggleEditDemoApp(id: "Notes", systemImage: "note.text", colors: [.yellow, .brown]),
        JiggleEditDemoApp(id: "Clock", systemImage: "clock.fill", colors: [.gray, .black]),
        JiggleEditDemoApp(id: "Health", systemImage: "heart.fill", colors: [.red, .pink]),
        JiggleEditDemoApp(id: "Files", systemImage: "folder.fill", colors: [.blue, .indigo]),
        JiggleEditDemoApp(id: "Books", systemImage: "book.fill", colors: [.orange, .red]),
        JiggleEditDemoApp(id: "Wallet", systemImage: "wallet.pass.fill", colors: [.indigo, .black]),
        JiggleEditDemoApp(id: "Home", systemImage: "house.fill", colors: [.orange, .yellow]),
        JiggleEditDemoApp(id: "Weather", systemImage: "cloud.sun.fill", colors: [.teal, .blue]),
    ]

    @State private var apps = Self.allApps
    @State private var isEditing = true
    @ScaledMetric(relativeTo: .caption) private var iconSize = 66.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: iconSize + 10), spacing: 16)] }
    private var animation: Animation? { reduceMotion ? nil : .snappy }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        Button("Reset") {
                            withAnimation(animation) { apps = Self.allApps }
                        }
                        Spacer()
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                        .fontWeight(.bold)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)

                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            icon(for: app)
                                .jiggleEditing(isEditing, seed: index)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func icon(for app: JiggleEditDemoApp) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: iconSize * 0.23, style: .continuous)
                .fill(LinearGradient(colors: app.colors, startPoint: .top, endPoint: .bottom))
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: app.systemImage)
                        .font(.title)
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .topLeading) {
                    if isEditing {
                        Button {
                            withAnimation(animation) { apps.removeAll { $0.id == app.id } }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.7))
                        }
                        .accessibilityLabel("Remove \(app.id)")
                        .offset(x: -8, y: -8)
                    }
                }

            Text(app.id)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

#Preview {
    JiggleEditModifierDemo()
}
