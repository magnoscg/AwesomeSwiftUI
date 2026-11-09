// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Owns a stack's path, so that any view can push or pop screens by a typed value.
///
/// Popping more screens than the stack holds is safe: it stops at the root.
@MainActor
@Observable
final class NavigationPathRouter<Destination: Hashable> {
    var path = NavigationPath()

    var depth: Int { path.count }

    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop(_ count: Int = 1) {
        let removable = min(max(count, 0), path.count)
        guard removable > 0 else { return }
        path.removeLast(removable)
    }

    func popToRoot() {
        pop(path.count)
    }
}

/// A navigation stack wired to a router, which it also places in the environment.
///
/// Read it from any screen with `@Environment(NavigationPathRouter<MyRoute>.self)`.
struct NavigationPathRouterStack<Destination: Hashable, Root: View, Screen: View>: View {
    let router: NavigationPathRouter<Destination>
    @ViewBuilder let root: () -> Root
    @ViewBuilder let screen: (Destination) -> Screen

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            root()
                .navigationDestination(for: Destination.self, destination: screen)
        }
        .environment(router)
    }
}

// MARK: - Demo

private enum NavigationPathRouterDemoRoute: String, Hashable, CaseIterable {
    case profile = "Profile"
    case settings = "Settings"
    case about = "About"

    var systemImage: String {
        switch self {
        case .profile: "person.crop.circle.fill"
        case .settings: "gearshape.fill"
        case .about: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .profile: .blue
        case .settings: .purple
        case .about: .teal
        }
    }
}

private struct NavigationPathRouterDemoScreen: View {
    var current: NavigationPathRouterDemoRoute?

    @Environment(NavigationPathRouter<NavigationPathRouterDemoRoute>.self) private var router

    var body: some View {
        ZStack {
            LinearGradient(colors: [current?.color ?? .indigo, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Depth \(router.depth)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)

                ForEach(NavigationPathRouterDemoRoute.allCases.filter { $0 != current }, id: \.self) { route in
                    Button(route.rawValue, systemImage: route.systemImage) { router.push(route) }
                        .frame(maxWidth: .infinity)
                }

                if router.depth > 0 {
                    Button("Root", systemImage: "house.fill") { router.popToRoot() }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.22))
            .foregroundStyle(.white)
            .padding(32)
        }
        .navigationTitle(current?.rawValue ?? "Router")
    }
}

struct NavigationPathRouterDemo: View {
    @State private var router = NavigationPathRouter<NavigationPathRouterDemoRoute>()

    var body: some View {
        NavigationPathRouterStack(router: router) {
            NavigationPathRouterDemoScreen()
        } screen: { route in
            NavigationPathRouterDemoScreen(current: route)
        }
    }
}

#Preview {
    NavigationPathRouterDemo()
}
