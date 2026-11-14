// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import MapKit
import SwiftUI

nonisolated struct MapRouteTrackerPoint: Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated enum MapRouteTrackerMath {
    static let earthRadius = 6_371_000.0

    /// The meters between two points, over the surface of the Earth.
    static func distance(from start: MapRouteTrackerPoint, to end: MapRouteTrackerPoint) -> Double {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let latitude = endLatitude - startLatitude
        let longitude = (end.longitude - start.longitude) * .pi / 180
        let chord = sin(latitude / 2) * sin(latitude / 2) + cos(startLatitude) * cos(endLatitude) * sin(longitude / 2) * sin(longitude / 2)
        return 2 * earthRadius * asin(min(sqrt(chord), 1))
    }

    /// The meters from the start of the route to each of its points.
    static func distances(along route: [MapRouteTrackerPoint]) -> [Double] {
        var total = 0.0
        return route.indices.map { index in
            if index > 0 { total += distance(from: route[index - 1], to: route[index]) }
            return total
        }
    }

    /// The point that is `progress` of the way along the route, from 0 at its start to 1 at its end.
    static func point(at progress: Double, on route: [MapRouteTrackerPoint]) -> MapRouteTrackerPoint? {
        split(route, at: progress).done.last
    }

    /// The route cut where `progress` falls: what is done, and what is left. Both have the cut point.
    static func split(_ route: [MapRouteTrackerPoint], at progress: Double) -> (done: [MapRouteTrackerPoint], left: [MapRouteTrackerPoint]) {
        guard let first = route.first else { return ([], []) }
        let distances = distances(along: route)
        let target = (progress.isFinite ? min(max(progress, 0), 1) : 0) * (distances.last ?? 0)
        // The first point the target has not passed yet. The cut is between it and the one before.
        guard let next = distances.indices.dropFirst().first(where: { distances[$0] >= target }) else {
            return ([first], route)
        }

        let length = distances[next] - distances[next - 1]
        let fraction = length > 0 ? (target - distances[next - 1]) / length : 0
        let cut = MapRouteTrackerPoint(
            latitude: route[next - 1].latitude + (route[next].latitude - route[next - 1].latitude) * fraction,
            longitude: route[next - 1].longitude + (route[next].longitude - route[next - 1].longitude) * fraction
        )
        return (Array(route[..<next]) + [cut], [cut] + Array(route[next...]))
    }
}

/// A route on a map with a marker that travels along it, like an order on its way: the part
/// already done is solid, the rest is dotted and the camera can follow the marker.
///
/// Set `progress` from 0 to 1 as the trip advances. The route is yours: take it from
/// `MKDirections` or from your own data.
struct MapRouteTracker: View {
    let route: [MapRouteTrackerPoint]
    /// How much of the route is done, from 0 to 1.
    var progress: Double
    var symbol = "bicycle"
    var color = Color.blue
    var markerTitle = "Courier"
    var destinationTitle = "Destination"
    /// Whether the camera travels with the marker. Otherwise it shows the whole route.
    var followsMarker = true
    /// How far above the marker the camera stays while it follows it, in meters.
    var followDistance = 2200.0

    private let lineWidth: CGFloat = 6

    @State private var position = MapCameraPosition.automatic
    @ScaledMetric(relativeTo: .body) private var markerSize = 38.0

    var body: some View {
        let parts = MapRouteTrackerMath.split(route, at: progress)

        Map(position: $position) {
            if parts.left.count > 1 {
                MapPolyline(coordinates: parts.left.map(\.coordinate))
                    .stroke(color.opacity(0.45), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: [1, lineWidth * 2]))
            }
            if parts.done.count > 1 {
                MapPolyline(coordinates: parts.done.map(\.coordinate))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
            if let destination = route.last {
                Marker(destinationTitle, systemImage: "flag.checkered", coordinate: destination.coordinate)
                    .tint(color)
            }
            if let current = parts.done.last {
                Annotation(markerTitle, coordinate: current.coordinate) {
                    Image(systemName: symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(color)
                        .frame(width: markerSize, height: markerSize)
                        .background(.white, in: .circle)
                        .overlay { Circle().strokeBorder(color, lineWidth: 2) }
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .accessibilityElement()
                        .accessibilityLabel(markerTitle)
                        .accessibilityValue(min(max(progress, 0), 1).formatted(.percent.precision(.fractionLength(0))))
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onChange(of: progress, initial: true) { follow() }
        .onChange(of: followsMarker) { follow() }
    }

    private func follow() {
        guard followsMarker, let current = MapRouteTrackerMath.point(at: progress, on: route) else {
            if !followsMarker { position = .automatic }
            return
        }
        position = .camera(MapCamera(centerCoordinate: current.coordinate, distance: followDistance))
    }
}

// MARK: - Demo

struct MapRouteTrackerDemo: View {
    private let route = [
        MapRouteTrackerPoint(latitude: 38.7158, longitude: -9.1420),
        MapRouteTrackerPoint(latitude: 38.7175, longitude: -9.1433),
        MapRouteTrackerPoint(latitude: 38.7193, longitude: -9.1448),
        MapRouteTrackerPoint(latitude: 38.7212, longitude: -9.1464),
        MapRouteTrackerPoint(latitude: 38.7232, longitude: -9.1481),
        MapRouteTrackerPoint(latitude: 38.7253, longitude: -9.1500),
    ]
    private let tripSeconds = 12.0
    private let tripMinutes = 9.0

    @State private var progress = 0.0
    @State private var isMoving = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MapRouteTracker(route: route, progress: progress, color: .indigo, followsMarker: !reduceMotion)
            .safeAreaInset(edge: .bottom) {
                card
            }
            .task(id: isMoving) {
                guard isMoving else { return }
                let clock = ContinuousClock()
                var last = clock.now
                while !Task.isCancelled, progress < 1 {
                    try? await Task.sleep(for: .milliseconds(33))
                    let now = clock.now
                    progress = min(progress + (now - last) / .seconds(tripSeconds), 1)
                    last = now
                }
                if progress >= 1 { isMoving = false }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress < 1 ? "Arriving in \(Int(((1 - progress) * tripMinutes).rounded(.up))) min" : "Your order is here")
                        .font(.headline)
                        .contentTransition(.numericText())
                    Text(progress < 1 ? "Alex is bringing your order" : "Delivered by Alex")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(progress < 1 ? (isMoving ? "Pause" : "Resume") : "Restart", systemImage: progress < 1 ? (isMoving ? "pause.fill" : "play.fill") : "arrow.counterclockwise") {
                    if progress >= 1 {
                        progress = 0
                        isMoving = true
                    } else {
                        isMoving.toggle()
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                // The regular size of an icon in a circle is too small to hit.
                .controlSize(.large)
            }

            ProgressView(value: progress)
                .accessibilityLabel("Trip progress")
        }
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .tint(.indigo)
    }
}

#Preview {
    MapRouteTrackerDemo()
}
