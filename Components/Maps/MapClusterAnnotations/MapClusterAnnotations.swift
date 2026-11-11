// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import MapKit
import SwiftUI

nonisolated struct MapClusterAnnotationsPlace: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var systemImage: String = "mappin"
    var latitude: Double
    var longitude: Double
}

nonisolated enum MapClusterAnnotationsLogic {
    /// Places that fall in the same cell of a grid over the map, drawn as one.
    struct Cluster: Identifiable, Equatable, Sendable {
        let places: [MapClusterAnnotationsPlace]
        let latitude: Double
        let longitude: Double

        var id: String { places.map(\.id).joined(separator: "|") }
    }

    /// Groups the places by the cell they fall in. A cell is one of `divisions` across what
    /// the map shows, so the groups split as the map zooms in and join as it zooms out.
    /// A group sits at the middle of its places, and the groups keep the order of the places.
    static func clusters(
        of places: [MapClusterAnnotationsPlace],
        latitudeDelta: Double,
        longitudeDelta: Double,
        divisions: Int = 6
    ) -> [Cluster] {
        let divisions = Double(max(divisions, 1))
        let cellLatitude = latitudeDelta / divisions
        let cellLongitude = longitudeDelta / divisions
        guard cellLatitude.isFinite, cellLongitude.isFinite, cellLatitude > 0, cellLongitude > 0 else {
            return places.map { Cluster(places: [$0], latitude: $0.latitude, longitude: $0.longitude) }
        }

        var order: [String] = []
        var cells: [String: [MapClusterAnnotationsPlace]] = [:]
        for place in places where place.latitude.isFinite && place.longitude.isFinite {
            let key = "\(Int((place.latitude / cellLatitude).rounded(.down))):\(Int((place.longitude / cellLongitude).rounded(.down)))"
            if cells[key] == nil { order.append(key) }
            cells[key, default: []].append(place)
        }

        return order.compactMap { key in
            guard let members = cells[key], !members.isEmpty else { return nil }
            let count = Double(members.count)
            return Cluster(
                places: members,
                latitude: members.map(\.latitude).reduce(0, +) / count,
                longitude: members.map(\.longitude).reduce(0, +) / count
            )
        }
    }

    /// The region that shows every place of a group with room around them.
    static func region(fitting places: [MapClusterAnnotationsPlace], room: Double = 1.8, smallest: Double = 0.004) -> MKCoordinateRegion? {
        let latitudes = places.map(\.latitude).filter(\.isFinite)
        let longitudes = places.map(\.longitude).filter(\.isFinite)
        guard let south = latitudes.min(), let north = latitudes.max(),
              let west = longitudes.min(), let east = longitudes.max() else { return nil }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (south + north) / 2, longitude: (west + east) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: min(max((north - south) * room, smallest), 180),
                longitudeDelta: min(max((east - west) * room, smallest), 360)
            )
        )
    }
}

/// A map where places that are close together are drawn as one bubble with their count.
/// Zooming in splits a bubble into its places, and a tap on it flies there.
///
/// A tap on a place sets `selection` and shows its name. With Reduce Motion on, the camera
/// does not fly.
struct MapClusterAnnotations: View {
    let places: [MapClusterAnnotationsPlace]
    @Binding var selection: MapClusterAnnotationsPlace.ID?
    var tint: Color = .indigo

    @State private var position = MapCameraPosition.automatic
    @State private var span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    @ScaledMetric(relativeTo: .body) private var pinSize = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let shadow = Color.black.opacity(0.25)

    private var clusters: [MapClusterAnnotationsLogic.Cluster] {
        MapClusterAnnotationsLogic.clusters(of: places, latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
    }

    var body: some View {
        Map(position: $position) {
            ForEach(clusters) { cluster in
                Annotation(
                    cluster.places.count == 1 ? cluster.places[0].name : "",
                    coordinate: CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude)
                ) {
                    if cluster.places.count == 1 {
                        pin(cluster.places[0])
                    } else {
                        bubble(cluster)
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        // The groups are made again when the map comes to rest, not on every frame of a pinch.
        .onMapCameraChange(frequency: .onEnd) { context in
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                span = context.region.span
            }
        }
        .onAppear {
            guard let region = MapClusterAnnotationsLogic.region(fitting: places, room: 1.3) else { return }
            position = .region(region)
            span = region.span
        }
    }

    private func pin(_ place: MapClusterAnnotationsPlace) -> some View {
        let isSelected = selection == place.id

        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                selection = isSelected ? nil : place.id
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: place.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MapClusterAnnotationsContrastingForeground(background: isSelected ? tint : .white))
                    .frame(width: pinSize * 0.75, height: pinSize * 0.75)
                    .background(isSelected ? tint : .white, in: .circle)
                    .shadow(color: shadow, radius: 5, y: 2)

                if isSelected {
                    Text(place.name)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: .capsule)
                        .fixedSize()
                        .transition(.opacity)
                }
            }
            .frame(minWidth: pinSize, minHeight: pinSize, alignment: .top)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(place.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .transition(.scale.combined(with: .opacity))
    }

    private func bubble(_ cluster: MapClusterAnnotationsLogic.Cluster) -> some View {
        Button {
            guard let region = MapClusterAnnotationsLogic.region(fitting: cluster.places) else { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.7)) {
                position = .region(region)
            }
        } label: {
            Text(cluster.places.count, format: .number)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(MapClusterAnnotationsContrastingForeground(background: tint))
                .frame(width: pinSize, height: pinSize)
                .background(tint.gradient, in: .circle)
                .overlay { Circle().stroke(.white, lineWidth: 3) }
                .shadow(color: shadow, radius: 6, y: 3)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("^[\(cluster.places.count) place](inflect: true)"))
        .accessibilityHint("Zooms in to show them")
        .transition(.scale.combined(with: .opacity))
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct MapClusterAnnotationsContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct MapClusterAnnotationsDemo: View {
    private let places = [
        MapClusterAnnotationsPlace(id: "prado", name: "Prado Museum", systemImage: "building.columns.fill", latitude: 40.4138, longitude: -3.6921),
        MapClusterAnnotationsPlace(id: "thyssen", name: "Thyssen Museum", systemImage: "building.columns.fill", latitude: 40.4160, longitude: -3.6949),
        MapClusterAnnotationsPlace(id: "retiro", name: "Retiro Park", systemImage: "tree.fill", latitude: 40.4153, longitude: -3.6845),
        MapClusterAnnotationsPlace(id: "sol", name: "Puerta del Sol", systemImage: "star.fill", latitude: 40.4169, longitude: -3.7035),
        MapClusterAnnotationsPlace(id: "mayor", name: "Plaza Mayor", systemImage: "star.fill", latitude: 40.4155, longitude: -3.7074),
        MapClusterAnnotationsPlace(id: "palace", name: "Royal Palace", systemImage: "crown.fill", latitude: 40.4180, longitude: -3.7143),
        MapClusterAnnotationsPlace(id: "debod", name: "Temple of Debod", systemImage: "sun.horizon.fill", latitude: 40.4240, longitude: -3.7178),
        MapClusterAnnotationsPlace(id: "bernabeu", name: "Bernabéu Stadium", systemImage: "sportscourt.fill", latitude: 40.4531, longitude: -3.6883),
        MapClusterAnnotationsPlace(id: "matadero", name: "Matadero", systemImage: "theatermasks.fill", latitude: 40.3917, longitude: -3.6976),
    ]

    @State private var selection: String?

    var body: some View {
        MapClusterAnnotations(places: places, selection: $selection)
            .safeAreaInset(edge: .top) {
                VStack(spacing: 2) {
                    Text("Madrid in a day")
                        .font(.headline)
                    Text(selection.flatMap { id in places.first { $0.id == id }?.name } ?? "Tap a bubble to zoom in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: .capsule)
                .padding(.top, 8)
            }
    }
}

#Preview {
    MapClusterAnnotationsDemo()
}
