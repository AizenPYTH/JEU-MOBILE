#if os(iOS)
import SwiftUI
import MapKit
import CaseEngine

/// Location: the map of the case (real and explorable when the places have coordinates, the
/// stylised city otherwise) and, below it, who shared their position with this phone.
struct LocationView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let tracks = game.device.tracks
        let known = game.knownPlaces
        let hasRealMap = game.device.places.contains { $0.latitude != nil }
        VStack(spacing: 0) {
            Group {
                if hasRealMap {
                    CaseMap(markers: CaseMap.markers(for: known), me: me(in: game))
                } else {
                    CityMap(places: known, tracks: [], highlight: nil)
                }
            }
            .overlay(alignment: .topLeading) {
                Label(L10n.f("n.places", known.count), systemImage: "mappin")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.s3)
                    .frame(height: 28)
                    .background(Capsule().fill(Theme.Colors.mapLabelHalo))
                    .padding(Theme.Spacing.s4)
                    .allowsHitTesting(false)
            }
            .frame(maxHeight: .infinity)

            // Bottom card, like a maps app: who shared their position with this phone.
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(Theme.Colors.line3).frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Theme.Spacing.s3)
                Text(L10n.t("location.people"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.marginList)
                    .padding(.top, Theme.Spacing.s3)
                Text(L10n.t("location.peopleHelp"))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.marginList)
                    .padding(.bottom, Theme.Spacing.s2)
                ScrollView {
                    VStack(spacing: 0) {
                        if tracks.isEmpty {
                            EmptyStateView(title: L10n.t("empty.locationTitle"), message: L10n.t("empty.locationMessage"))
                        }
                        ForEach(tracks) { track in
                            Button {
                                session.open(.track(track.id))
                            } label: {
                                TrackRow(track: track, game: game, cost: session.rules.timeCosts.openTrack)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("track.\(track.id)")
                            RowDivider(leading: 76)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.bottomInset)
                }
            }
            .frame(height: 300)
            .background(UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet, style: .continuous)
                .fill(Theme.Colors.bgSurface)
                .ignoresSafeArea(edges: .bottom))
        }
        .appRoot(.location, subtitle: L10n.t("location.subtitle"), session: session)
    }

    /// The phone's own last position (from the owner's track).
    private func me(in game: Investigation) -> CLLocationCoordinate2D? {
        guard let track = game.device.tracks.first(where: { $0.contact == ownerContactID }),
              let last = track.points.max(by: { $0.at < $1.at }) else { return nil }
        return CaseMap.coordinate(of: last.place, in: game.device.places)
    }
}

struct TrackRow: View {
    let track: LocationTrack
    let game: Investigation
    let cost: Int

    var body: some View {
        let stopped = track.sharingStoppedAt != nil
        HStack(spacing: Theme.Spacing.s4) {
            Avatar(contact: game.contact(track.contact))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: stopped ? "location.slash.fill" : "location.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(stopped ? Theme.Colors.signal : Theme.Colors.info))
                        .overlay(Circle().strokeBorder(Theme.Colors.bgSurface, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(track.contact == ownerContactID ? L10n.t("location.me") : game.name(of: track.contact))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(stopped ? Theme.Colors.signal : Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: Theme.Spacing.s3)
            CostTag(seconds: cost)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .padding(.vertical, Theme.Spacing.s4)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        if track.sharingStoppedAt != nil { return L10n.t("location.stopped") }
        guard let last = track.points.max(by: { $0.at < $1.at }) else { return "" }
        return L10n.f("location.lastSeen", game.index.place(last.place)?.name ?? "", PhoneFormat.dayAndTime(last.at))
    }
}

/// One person's movements: the route on the map (numbered stops, zoomable) + the precise timeline.
struct TrackView: View {
    let trackID: String
    let session: GameSession

    var body: some View {
        let game = session.game
        if let track = game.index.track(trackID) {
            let points = track.points.sorted { $0.at < $1.at }
            let places = game.device.places
            let stops = places.filter { place in points.contains { $0.place == place.id } }
            VStack(spacing: 0) {
                Group {
                    if places.contains(where: { $0.latitude != nil }) {
                        CaseMap(markers: CaseMap.markers(for: stops, route: points),
                                route: points.compactMap { CaseMap.coordinate(of: $0.place, in: places) })
                    } else {
                        CityMap(places: places, tracks: [track], highlight: nil)
                    }
                }
                .frame(height: Theme.Size.mapHeight)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                        if let stopped = track.sharingStoppedAt {
                            Label(L10n.f("location.stoppedAt", game.name(of: track.contact), PhoneFormat.dayAndTime(stopped)),
                                  systemImage: "location.slash.fill")
                                .font(Theme.Fonts.callout.weight(.medium))
                                .foregroundStyle(Theme.Colors.signal)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(points.enumerated()), id: \.element.id) { offset, point in
                                TrackStopRow(number: offset + 1, point: point, placeName: game.index.place(point.place)?.name ?? point.place,
                                             last: offset == points.count - 1)
                            }
                        }
                    }
                    .padding(Theme.Spacing.s5)
                    .padding(.bottom, Theme.Spacing.bottomInset)
                }
            }
            .navigationTitle(track.contact == ownerContactID ? L10n.t("location.me") : game.name(of: track.contact))
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.track, track.id), session: session)
        }
    }
}

/// A stop on a route: its number (as on the map), day and time, place, note.
struct TrackStopRow: View {
    let number: Int
    let point: TrackPoint
    let placeName: String
    let last: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(Theme.Fonts.dataSmall.weight(.bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Theme.Colors.info))
                if !last {
                    Rectangle().fill(Theme.Colors.line2).frame(width: 2).frame(minHeight: 28)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text("\(PhoneFormat.shortDay(point.at)) · \(PhoneFormat.time(point.at))")
                    .font(Theme.Fonts.callout.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(placeName).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
                if let note = point.note {
                    Text(note).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.bottom, Theme.Spacing.s4)
        }
    }
}

/// Stylised city map that reads as a map at a glance: blocks between streets, two main roads,
/// a river, parks, red pins on places, a blue dashed route. Clear, not geographic.
struct CityMap: View {
    let places: [Place]
    let tracks: [LocationTrack]
    let highlight: String?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.Colors.mapBackground))
                    // City blocks.
                    let step: CGFloat = 38
                    var y: CGFloat = 4
                    while y < size.height {
                        var x: CGFloat = 4
                        while x < size.width {
                            context.fill(Path(roundedRect: CGRect(x: x, y: y, width: step - 8, height: step - 8), cornerRadius: 3),
                                         with: .color(Theme.Colors.mapBlock))
                            x += step
                        }
                        y += step
                    }
                    // Parks.
                    for rect in [CGRect(x: size.width * 0.06, y: size.height * 0.08, width: size.width * 0.22, height: size.height * 0.2),
                                 CGRect(x: size.width * 0.7, y: size.height * 0.12, width: size.width * 0.2, height: size.height * 0.16)] {
                        context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(Theme.Colors.mapPark))
                    }
                    // River.
                    var river = Path()
                    river.move(to: CGPoint(x: 0, y: size.height * 0.55))
                    river.addCurve(to: CGPoint(x: size.width, y: size.height * 0.95),
                                   control1: CGPoint(x: size.width * 0.35, y: size.height * 0.35),
                                   control2: CGPoint(x: size.width * 0.6, y: size.height * 1.05))
                    context.stroke(river, with: .color(Theme.Colors.mapRiver), lineWidth: 22)
                    // Main roads.
                    var roads = Path()
                    roads.move(to: CGPoint(x: size.width * 0.42, y: 0))
                    roads.addQuadCurve(to: CGPoint(x: size.width * 0.5, y: size.height), control: CGPoint(x: size.width * 0.58, y: size.height * 0.5))
                    roads.move(to: CGPoint(x: 0, y: size.height * 0.3))
                    roads.addLine(to: CGPoint(x: size.width, y: size.height * 0.42))
                    context.stroke(roads, with: .color(Theme.Colors.mapMainRoad), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    // Routes.
                    for track in tracks {
                        let points = track.points.sorted { $0.at < $1.at }.compactMap { point in
                            places.first { $0.id == point.place }.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                        }
                        guard let first = points.first else { continue }
                        var route = Path()
                        route.move(to: first)
                        points.dropFirst().forEach { route.addLine(to: $0) }
                        context.stroke(route, with: .color(Theme.Colors.info),
                                       style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round, dash: [7, 5]))
                    }
                }
                ForEach(places) { place in
                    let visited = tracks.contains { $0.points.contains { $0.place == place.id } }
                    VStack(spacing: 1) {
                        if visited || tracks.isEmpty {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Theme.Colors.textPrimary, Theme.Colors.mapPin)
                        } else {
                            Circle().fill(Theme.Colors.textTertiary).frame(width: 7, height: 7)
                        }
                        Text(Self.shortName(place.name))
                            .font(.custom(Theme.FontName.semibold, fixedSize: 10))
                            .foregroundStyle(visited || tracks.isEmpty ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Theme.Colors.mapLabelHalo))
                    }
                    .position(x: min(max(place.x * size.width, 48), size.width - 48), y: place.y * size.height)
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    /// "Parking du Quai 9 — zone portuaire" → "Parking du Quai 9" (the full name is in the lists).
    static func shortName(_ name: String) -> String {
        name.components(separatedBy: " — ").first ?? name
    }
}
#endif
