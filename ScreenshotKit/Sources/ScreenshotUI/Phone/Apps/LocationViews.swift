#if os(iOS)
import SwiftUI
import CaseEngine

/// Location: the owner's history and friends sharing their position, on a stylised city map.
struct LocationView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let tracks = game.device.tracks
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                CityMap(places: game.device.places, tracks: [], highlight: nil)
                    .frame(height: Theme.Size.mapHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                    .padding(.horizontal, Theme.Spacing.l)

                VStack(spacing: 0) {
                    ForEach(tracks) { track in
                        Button {
                            session.open(.track(track.id))
                        } label: {
                            HStack(spacing: Theme.Spacing.m) {
                                Avatar(contact: game.contact(track.contact))
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text(track.contact == ownerContactID ? L10n.t("location.me") : game.name(of: track.contact))
                                        .font(Theme.Fonts.headline)
                                    Text(subtitle(track, game))
                                        .font(Theme.Fonts.subheadline)
                                        .foregroundStyle(track.sharingStoppedAt != nil ? Theme.Colors.warning : Theme.Colors.textSecondary)
                                }
                                Spacer()
                                Text(L10n.f("common.cost", session.rules.timeCosts.openTrack))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .padding(.vertical, Theme.Spacing.m)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.Colors.separator)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
            }
            .padding(.vertical, Theme.Spacing.m)
        }
        .navigationTitle(AppID.location.title)
    }

    private func subtitle(_ track: LocationTrack, _ game: Investigation) -> String {
        if track.sharingStoppedAt != nil { return L10n.t("location.stopped") }
        guard let last = track.points.max(by: { $0.at < $1.at }) else { return "" }
        return L10n.f("location.lastSeen", game.index.place(last.place)?.name ?? "", PhoneFormat.dayAndTime(last.at))
    }
}

/// One person's movements: route on the map + precise timeline.
struct TrackView: View {
    let trackID: String
    let session: GameSession

    var body: some View {
        let game = session.game
        if let track = game.index.track(trackID) {
            let points = track.points.sorted { $0.at < $1.at }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    CityMap(places: game.device.places, tracks: [track], highlight: nil)
                        .frame(height: Theme.Size.mapHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))

                    if let stopped = track.sharingStoppedAt {
                        Label(L10n.f("location.stoppedAt", game.name(of: track.contact), PhoneFormat.dayAndTime(stopped)),
                              systemImage: "location.slash.fill")
                            .font(Theme.Fonts.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Colors.warning)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(points.enumerated()), id: \.element.id) { offset, point in
                            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                                VStack(spacing: 0) {
                                    Text("\(offset + 1)")
                                        .font(Theme.Fonts.caption2.weight(.bold))
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .background(Circle().fill(Theme.Colors.accent))
                                    if offset < points.count - 1 {
                                        Rectangle().fill(Theme.Colors.separator).frame(width: 2).frame(minHeight: 28)
                                    }
                                }
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text("\(PhoneFormat.shortDay(point.at)) · \(PhoneFormat.time(point.at))")
                                        .font(Theme.Fonts.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                    Text(game.index.place(point.place)?.name ?? point.place)
                                        .font(Theme.Fonts.subheadline)
                                    if let note = point.note {
                                        Text(note)
                                            .font(Theme.Fonts.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                }
                                .padding(.bottom, Theme.Spacing.m)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.l)
            }
            .navigationTitle(track.contact == ownerContactID ? L10n.t("location.me") : game.name(of: track.contact))
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.track, track.id), session: session)
        }
    }
}

/// Stylised dark city map: a river, a street grid, places and routes. Clear, not geographic.
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
                    var grid = Path()
                    let step: CGFloat = 26
                    var x: CGFloat = 0
                    while x < size.width { grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                    var y: CGFloat = 0
                    while y < size.height { grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                    context.stroke(grid, with: .color(Theme.Colors.mapStreet), lineWidth: 1)
                    var river = Path()
                    river.move(to: CGPoint(x: 0, y: size.height * 0.55))
                    river.addCurve(to: CGPoint(x: size.width, y: size.height * 0.95),
                                   control1: CGPoint(x: size.width * 0.35, y: size.height * 0.35),
                                   control2: CGPoint(x: size.width * 0.6, y: size.height * 1.05))
                    context.stroke(river, with: .color(Theme.Colors.mapRiver), lineWidth: 16)
                    for track in tracks {
                        let points = track.points.sorted { $0.at < $1.at }.compactMap { point in
                            places.first { $0.id == point.place }.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                        }
                        guard let first = points.first else { continue }
                        var route = Path()
                        route.move(to: first)
                        points.dropFirst().forEach { route.addLine(to: $0) }
                        context.stroke(route, with: .color(Theme.Colors.accent.opacity(0.8)),
                                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 4]))
                    }
                }
                ForEach(places) { place in
                    let visited = tracks.contains { $0.points.contains { $0.place == place.id } }
                    VStack(spacing: 2) {
                        Circle()
                            .fill(visited ? Theme.Colors.accent : Theme.Colors.textTertiary)
                            .frame(width: visited ? 10 : 6, height: visited ? 10 : 6)
                        Text(place.name)
                            .font(.system(size: 9, weight: visited ? .semibold : .regular))
                            .foregroundStyle(visited ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .position(x: place.x * size.width, y: place.y * size.height + 8)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
