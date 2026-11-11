// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Presents a sheet that fades in over the content with the iOS 27 `.crossFade` transition,
/// instead of moving up from the bottom.
///
/// Apple documents `.crossFade` for sheets. Keep `navigationTransition` on the root of the
/// sheet's content, outside any container such as `VStack`. A cross-fade has no movement,
/// so Reduce Motion needs nothing different.
@available(iOS 27, *)
struct CrossFadeNavigation<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            sheetContent()
                .navigationTransition(.crossFade)
        }
    }
}

@available(iOS 27, *)
extension View {
    func crossFadeSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(CrossFadeNavigation(isPresented: isPresented, sheetContent: content))
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct CrossFadeNavigationDemo: View {
    @State private var showsSheet = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sunrise.fill")
                    .font(.system(.largeTitle, weight: .semibold))
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text("Morning")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Button("Open") { showsSheet = true }
                    .font(.headline)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
            }
            .foregroundStyle(.white)
        }
        .crossFadeSheet(isPresented: $showsSheet) {
            CrossFadeNavigationDemoSheet()
        }
    }
}

@available(iOS 27, *)
private struct CrossFadeNavigationDemoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(.largeTitle, weight: .semibold))
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text("Evening")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Button("Close") { dismiss() }
                    .font(.headline)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
            }
            .foregroundStyle(.white)
        }
    }
}

@available(iOS 27, *)
#Preview {
    CrossFadeNavigationDemo()
}
