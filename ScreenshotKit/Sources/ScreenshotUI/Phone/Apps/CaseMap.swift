#if os(iOS)
import SwiftUI
import MapKit
import CaseEngine

/// The phone's map: a real, explorable map (pinch, pan, double tap, rotate, scale) with the places
/// of the case as pins, a route drawn when a track is open, and "me" as a blue dot. Places the
/// player has not come across yet stay off the map (`Investigation.knownPlaces`).
/// Built on MapKit (the system map), dark, without the real city's shops and points of interest.
struct CaseMap: View {
    struct Marker: Identifiable {
        let id: String
        let name: String
        let kind: Place.Kind
        let coordinate: CLLocationCoordinate2D
        /// Numbered stop on an open route.
        let step: Int?
    }

    let markers: [Marker]
    /// The route of an open track, in time order.
    var route: [CLLocationCoordinate2D] = []
    /// The phone's last known position.
    var me: CLLocationCoordinate2D? = nil
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position, interactionModes: .all) {
            if route.count > 1 {
                MapPolyline(coordinates: route)
                    .stroke(Theme.Colors.info, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [9, 7]))
            }
            ForEach(markers) { marker in
                Annotation(marker.name, coordinate: marker.coordinate, anchor: .bottom) {
                    PlacePin(kind: marker.kind, step: marker.step)
                        .accessibilityElement()
                        .accessibilityLabel(Text(marker.name))
                        .accessibilityIdentifier("map.pin.\(marker.id)")
                }
            }
            if let me {
                Annotation(L10n.t("location.me"), coordinate: me, anchor: .center) {
                    MeDot().accessibilityIdentifier("map.me")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .accessibilityIdentifier("location.map")
    }

    /// Markers for the given places (those with coordinates), numbered along a route if given.
    static func markers(for places: [Place], route: [TrackPoint] = []) -> [Marker] {
        places.compactMap { place in
            guard let lat = place.latitude, let lon = place.longitude else { return nil }
            let step = route.firstIndex { $0.place == place.id }.map { $0 + 1 }
            return Marker(id: place.id, name: place.name, kind: place.kind,
                          coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), step: step)
        }
    }

    static func coordinate(of placeID: String, in places: [Place]) -> CLLocationCoordinate2D? {
        guard let place = places.first(where: { $0.id == placeID }), let lat = place.latitude, let lon = place.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

/// A map pin: a coloured disc with the kind of place (or the stop number on a route) and a tip.
struct PlacePin: View {
    let kind: Place.Kind
    var step: Int? = nil

    var body: some View {
        VStack(spacing: -3) {
            ZStack {
                Circle().fill(step == nil ? Theme.Colors.mapPin : Theme.Colors.info)
                Circle().strokeBorder(Theme.Colors.textPrimary, lineWidth: 2)
                if let step {
                    Text("\(step)").font(.custom(Theme.FontName.monoBold, fixedSize: 13)).foregroundStyle(Theme.Colors.textPrimary)
                } else {
                    Image(systemName: Self.symbol(kind)).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .frame(width: 32, height: 32)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(step == nil ? Theme.Colors.mapPin : Theme.Colors.info)
        }
        .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
    }

    static func symbol(_ kind: Place.Kind) -> String {
        switch kind {
        case .home: "house.fill"
        case .bar: "wineglass.fill"
        case .work: "briefcase.fill"
        case .parking: "parkingsign"
        case .street: "signpost.right.fill"
        case .district: "building.2.fill"
        case .road: "road.lanes"
        case .industrial: "shippingbox.fill"
        case .park: "tree.fill"
        case .station: "tram.fill"
        case .shop: "storefront.fill"
        }
    }
}

/// "Me": a blue dot with a soft halo, like any phone's map.
struct MeDot: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.Colors.info.opacity(0.22)).frame(width: 44, height: 44)
            Circle().fill(Theme.Colors.textPrimary).frame(width: 20, height: 20)
            Circle().fill(Theme.Colors.info).frame(width: 14, height: 14)
        }
        .accessibilityLabel(Text(L10n.t("location.me")))
    }
}
#endif
