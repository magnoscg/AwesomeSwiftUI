// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum PhotoLightboxMath {
    /// `photo` is the photo's size at fit. A side that still fits the container cannot pan.
    static func clampedOffset(_ offset: CGSize, zoom: CGFloat, photo: CGSize, in size: CGSize) -> CGSize {
        let limit = CGSize(width: max((photo.width * zoom - size.width) / 2, 0), height: max((photo.height * zoom - size.height) / 2, 0))
        return CGSize(
            width: min(max(offset.width, -limit.width), limit.width),
            height: min(max(offset.height, -limit.height), limit.height)
        )
    }

    static func clampedZoom(_ zoom: CGFloat, maxZoom: CGFloat) -> CGFloat {
        min(max(zoom, 1), max(maxZoom, 1))
    }

    /// The nearest valid page, or 0 for an empty pager.
    static func clampedPage(_ page: Int, count: Int) -> Int {
        min(max(page, 0), max(count - 1, 0))
    }
}

/// A full-screen photo pager. Each page zooms on its own, and a swipe down closes the viewer.
///
/// Present it above your content, for example in a `ZStack`. Pinch or double tap to zoom. Paging
/// and the swipe down stop while the current photo is zoomed, so a drag pans it instead.
struct PhotoLightbox: View {
    let photos: [Image]
    @Binding var selection: Int
    var maxZoom: CGFloat = 4
    var onClose: () -> Void

    @State private var zooms: [Int: CGFloat] = [:]
    @GestureState private var pullDown: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCurrentZoomed: Bool { (zooms[selection] ?? 1) > 1 }
    private var pullProgress: CGFloat { min(pullDown / 320, 1) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .opacity(1 - pullProgress * 0.7)
                .ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(photos.indices, id: \.self) { index in
                    PhotoLightboxPage(
                        photo: photos[index],
                        zoom: Binding(get: { zooms[index] ?? 1 }, set: { zooms[index] = $0 }),
                        maxZoom: maxZoom
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .scaleEffect(1 - pullProgress * 0.2)
            .offset(y: pullDown)
            .animation(reduceMotion ? nil : .snappy, value: pullDown == 0)
            .simultaneousGesture(closeGesture, including: isCurrentZoomed ? .subviews : .all)

            header
                .opacity(pullDown == 0 ? 1 : 0)
        }
        .preferredColorScheme(.dark)
        .accessibilityAction(.escape) { onClose() }
        .onChange(of: photos.count, initial: true) { _, count in
            let page = PhotoLightboxMath.clampedPage(selection, count: count)
            if page != selection { selection = page }
        }
    }

    private var header: some View {
        HStack {
            if !photos.isEmpty {
                Text("\(PhotoLightboxMath.clampedPage(selection, count: photos.count) + 1) of \(photos.count)")
                    .font(.headline)
                    .monospacedDigit()
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .accessibilityLabel("Close")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
    }

    private var closeGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .updating($pullDown) { value, state, _ in
                if state != 0 || abs(value.translation.height) > abs(value.translation.width) {
                    state = max(value.translation.height, 0)
                }
            }
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width),
                      value.predictedEndTranslation.height > 200 else { return }
                onClose()
            }
    }
}

private struct PhotoLightboxPage: View {
    let photo: Image
    @Binding var zoom: CGFloat
    let maxZoom: CGFloat

    @State private var offset = CGSize.zero
    @State private var fittedSize = CGSize.zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var pan = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let liveZoom = PhotoLightboxMath.clampedZoom(zoom * pinch, maxZoom: maxZoom)
            let moved = CGSize(width: offset.width + pan.width, height: offset.height + pan.height)

            photo
                .resizable()
                .scaledToFit()
                .onGeometryChange(for: CGSize.self) { $0.size } action: { fittedSize = $0 }
                .frame(width: size.width, height: size.height)
                .scaleEffect(liveZoom)
                .offset(PhotoLightboxMath.clampedOffset(moved, zoom: liveZoom, photo: fittedSize, in: size))
                .frame(width: size.width, height: size.height)
                .contentShape(.rect)
                .gesture(TapGesture(count: 2).onEnded { toggleZoom() })
                .simultaneousGesture(pinchGesture(in: size))
                .gesture(panGesture(in: size), including: zoom > 1 ? .all : .subviews)
                .accessibilityAction(named: zoom > 1 ? "Zoom out" : "Zoom in") { toggleZoom() }
        }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                zoom = PhotoLightboxMath.clampedZoom(zoom * value.magnification, maxZoom: maxZoom)
                offset = PhotoLightboxMath.clampedOffset(offset, zoom: zoom, photo: fittedSize, in: size)
            }
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($pan) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let moved = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
                offset = PhotoLightboxMath.clampedOffset(moved, zoom: zoom, photo: fittedSize, in: size)
            }
    }

    private func toggleZoom() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.15)) {
            zoom = zoom > 1 ? 1 : PhotoLightboxMath.clampedZoom(2.5, maxZoom: maxZoom)
            offset = .zero
        }
    }
}

// MARK: - Demo

struct PhotoLightboxDemo: View {
    @State private var selection = 0
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let photos = [
        demoPhoto([.indigo, .pink, .orange], hill: .purple, label: "Sunset"),
        demoPhoto([.cyan, .teal, .white], hill: .green, label: "Spring valley"),
        demoPhoto([.black, .indigo, .blue], hill: .black, label: "Night sky"),
        demoPhoto([.orange, .yellow, .white], hill: .brown, label: "Desert"),
    ]

    private var animation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(photos.indices, id: \.self) { index in
                        thumbnail(index)
                    }
                }
                .padding(16)
            }

            if isOpen {
                PhotoLightbox(photos: photos, selection: $selection) {
                    withAnimation(animation) { isOpen = false }
                }
                .transition(.opacity)
            }
        }
    }

    private func thumbnail(_ index: Int) -> some View {
        Button {
            selection = index
            withAnimation(animation) { isOpen = true }
        } label: {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    photos[index]
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open photo \(index + 1)")
    }
}

private func demoPhoto(_ sky: [Color], hill: Color, label: String) -> Image {
    let size = CGSize(width: 900, height: 1200)
    return Image(size: size, label: Text(label)) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: sky), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )
        context.fill(Path(ellipseIn: CGRect(x: 540, y: 220, width: 200, height: 200)), with: .color(.white.opacity(0.85)))

        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: size.height))
        ridge.addLine(to: CGPoint(x: 0, y: 760))
        ridge.addCurve(to: CGPoint(x: size.width, y: 660), control1: CGPoint(x: 300, y: 480), control2: CGPoint(x: 600, y: 1020))
        ridge.addLine(to: CGPoint(x: size.width, y: size.height))
        ridge.closeSubpath()
        context.fill(ridge, with: .color(hill))
    }
}

#Preview {
    PhotoLightboxDemo()
}
