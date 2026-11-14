// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A side menu that pushes the content away. Drag sideways or tap the content to close it.
///
/// With Reduce Motion on, the menu opens and closes without sliding.
struct SideDrawer<MenuContent: View, Content: View>: View {
    @Binding var isOpen: Bool
    var menuWidth: CGFloat = 280
    @ViewBuilder var menu: MenuContent
    @ViewBuilder var content: Content

    @State private var dragTranslation: CGFloat = 0
    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Gestures report screen points, but layout mirrors in right-to-left layouts: 1 or -1 converts between them.
    private var forward: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.15)
    }

    private var pushOffset: CGFloat {
        min(max((isOpen ? menuWidth : 0) + dragTranslation, 0), menuWidth)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            menu
                .frame(width: menuWidth)
                .frame(maxHeight: .infinity)
                .offset(x: pushOffset - menuWidth)
                .accessibilityHidden(!isOpen)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(isOpen)
                .overlay {
                    if isOpen {
                        Button {
                            isOpen = false
                        } label: {
                            Color.clear.contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close menu")
                    }
                }
                .shadow(color: .black.opacity(pushOffset > 0 ? 0.3 : 0), radius: 20)
                .offset(x: pushOffset)
        }
        .gesture(dragGesture)
        .animation(animation, value: isOpen)
        .onChange(of: isDragging) { _, dragging in
            if !dragging { withAnimation(animation) { dragTranslation = 0 } }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { dragTranslation = $0.translation.width * forward }
            .onEnded { value in
                let projected = (isOpen ? menuWidth : 0) + value.predictedEndTranslation.width * forward
                withAnimation(animation) {
                    isOpen = projected > menuWidth / 2
                    dragTranslation = 0
                }
            }
    }
}

// MARK: - Demo

struct SideDrawerDemo: View {
    private let destinations = [
        ("Inbox", "tray.fill"),
        ("Starred", "star.fill"),
        ("Archive", "archivebox.fill"),
        ("Settings", "gearshape.fill"),
    ]

    @State private var isOpen = false
    @State private var current = "tray.fill"

    var body: some View {
        SideDrawer(isOpen: $isOpen) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Workspace")
                    .font(.title2.bold())
                    .padding(.bottom, 20)

                ForEach(destinations, id: \.0) { name, symbol in
                    Button {
                        current = symbol
                        isOpen = false
                    } label: {
                        // The whole row answers to a touch, not only its text.
                        Label(name, systemImage: symbol)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                }

                Spacer()
            }
            .foregroundStyle(.white)
            .buttonStyle(.plain)
            .padding(.top, 40)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        } content: {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Image(systemName: current)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)

                Button {
                    isOpen = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.2), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Menu")
                .padding(20)
            }
        }
        .background(LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}

#Preview {
    SideDrawerDemo()
}
