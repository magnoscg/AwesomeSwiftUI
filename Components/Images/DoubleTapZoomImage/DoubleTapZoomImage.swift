// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum DoubleTapZoomImageMath {
    /// How far a zoomed image can move before showing an empty edge.
    static func clampedOffset(_ offset: CGSize, zoom: CGFloat, in size: CGSize) -> CGSize {
        let limit = CGSize(width: max((zoom - 1) * size.width / 2, 0), height: max((zoom - 1) * size.height / 2, 0))
        return CGSize(
            width: min(max(offset.width, -limit.width), limit.width),
            height: min(max(offset.height, -limit.height), limit.height)
        )
    }

    /// The offset that brings a tapped point as close to the center as the image's edges allow.
    static func offset(centering point: CGPoint, zoom: CGFloat, in size: CGSize) -> CGSize {
        let wanted = CGSize(width: (size.width / 2 - point.x) * zoom, height: (size.height / 2 - point.y) * zoom)
        return clampedOffset(wanted, zoom: zoom, in: size)
    }
}

/// An image that zooms in on the point you double tap and returns to fit on the next double tap.
///
/// While zoomed, a drag pans the image. At rest it leaves drags to the scroll view around it.
/// With Reduce Motion on, the zoom changes without animating.
struct DoubleTapZoomImage: View {
    let image: Image
    let label: LocalizedStringResource
    var zoom: CGFloat = 2.5
    /// Zooms in on this point without a touch, for demos. `nil` returns to fit.
    var programmaticZoom: UnitPoint? = nil

    @State private var isZoomed = false
    @State private var offset = CGSize.zero
    @GestureState private var translation = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetZoom: CGFloat { max(zoom, 1) }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let shown = CGSize(width: offset.width + translation.width, height: offset.height + translation.height)

            image
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .scaleEffect(isZoomed ? targetZoom : 1)
                .offset(isZoomed ? DoubleTapZoomImageMath.clampedOffset(shown, zoom: targetZoom, in: size) : .zero)
                .frame(width: size.width, height: size.height)
                .contentShape(.rect)
                .gesture(
                    SpatialTapGesture(count: 2).onEnded { value in
                        toggleZoom(at: value.location, in: size)
                    }
                )
                .gesture(pan(in: size), including: isZoomed ? .all : .subviews)
                .onChange(of: programmaticZoom) { _, target in
                    setZoom(target.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }, in: size)
                }
                .accessibilityLabel(label)
                .accessibilityValue(isZoomed ? "Zoomed in" : "Fit")
                .accessibilityAddTraits(.isImage)
                .accessibilityAction(named: isZoomed ? "Zoom out" : "Zoom in") {
                    toggleZoom(at: CGPoint(x: size.width / 2, y: size.height / 2), in: size)
                }
        }
        // A photo is not mirrored in right-to-left layouts, so neither is the geometry that moves it.
        .environment(\.layoutDirection, .leftToRight)
        .clipped()
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($translation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let moved = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
                offset = DoubleTapZoomImageMath.clampedOffset(moved, zoom: targetZoom, in: size)
            }
    }

    private func toggleZoom(at point: CGPoint, in size: CGSize) {
        setZoom(isZoomed ? nil : point, in: size)
    }

    private func setZoom(_ point: CGPoint?, in size: CGSize) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.15)) {
            offset = point.map { DoubleTapZoomImageMath.offset(centering: $0, zoom: targetZoom, in: size) } ?? .zero
            isZoomed = point != nil
        }
    }
}

// MARK: - Demo

struct DoubleTapZoomImageDemo: View {
    private let photo = demoPhoto()

    @State private var zoomTarget: UnitPoint?
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            DoubleTapZoomImage(image: photo, label: "City skyline at night", programmaticZoom: zoomTarget)
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 24))

            Label("Double tap anywhere", systemImage: "hand.tap.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await playZooms()
        }
    }

    // Only the demo plays by itself, because a real double tap needs a finger.
    private func playZooms() async {
        let targets: [UnitPoint?] = [UnitPoint(x: 0.75, y: 0.2), nil, UnitPoint(x: 0.3, y: 0.7), nil]
        while isAutoPlaying {
            for target in targets {
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled, isAutoPlaying else { return }
                zoomTarget = target
            }
        }
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 900, height: 1200)
    return Image(size: size, label: Text("City skyline at night")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [.black, .indigo, .purple]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 1200))
        )
        context.fill(Path(ellipseIn: CGRect(x: 620, y: 140, width: 150, height: 150)), with: .color(.white.opacity(0.9)))

        let heights: [CGFloat] = [520, 760, 440, 880, 620, 700, 480]
        for (column, height) in heights.enumerated() {
            let x = CGFloat(column) * 130 - 5
            let tower = CGRect(x: x, y: 1200 - height, width: 120, height: height)
            context.fill(Path(tower), with: .color(Color(white: 0.09)))

            for row in stride(from: tower.minY + 30, to: tower.maxY - 30, by: 64) {
                for offset in [CGFloat(18), 70] where (column + Int(row) / 64 + Int(offset)).isMultiple(of: 3) == false {
                    context.fill(Path(CGRect(x: x + offset, y: row, width: 32, height: 34)), with: .color(.yellow.opacity(0.8)))
                }
            }
        }
    }
}

#Preview {
    DoubleTapZoomImageDemo()
}
