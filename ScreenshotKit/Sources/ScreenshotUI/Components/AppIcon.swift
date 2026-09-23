#if os(iOS)
import SwiftUI
import CaseEngine

/// App icon of the seized phone. Original TRACE icons built on conventions every player knows
/// (green handset, blue bubbles, a calendar page with the day, a map with a pin, a lined note…),
/// with a light glass sheen. Same shape, radius and sheen for every app.
struct AppTileGlyph: View {
    let app: AppID
    var size: CGFloat = Theme.Size.appTile
    /// The calendar icon shows this day (like a real phone); nil shows a small month grid.
    var calendarDay: Moment? = nil

    private var radius: CGFloat { size * Theme.Radius.icon / Theme.Size.appTile }

    var body: some View {
        let colors = Theme.iconGradient(app)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom))
            glyph
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay {
            // Glass sheen on the upper half + a hairline edge.
            shape.fill(LinearGradient(colors: [Theme.Colors.iconSheen, Theme.Colors.iconSheen.opacity(0)],
                                      startPoint: .top, endPoint: .center))
                .allowsHitTesting(false)
        }
        .overlay(shape.strokeBorder(Theme.Colors.iconEdge, lineWidth: 0.75))
        .shadow(color: .black.opacity(0.35), radius: size * 0.06, y: size * 0.04)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyph: some View {
        let color = Theme.iconGlyph(app)
        switch app {
        case .calendar: CalendarIconFace(day: calendarDay, size: size)
        case .notes: NotesIconFace(size: size)
        case .location: MapIconFace(size: size)
        default:
            Image(systemName: Self.symbol(app))
                .font(.system(size: size * Self.scale(app), weight: .semibold))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
        }
    }

    static func symbol(_ app: AppID) -> String {
        switch app {
        case .messages: "bubble.left.and.bubble.right.fill"
        case .phone: "phone.fill"
        case .photos: "photo.stack.fill"
        case .browser: "globe"
        case .mail: "envelope.fill"
        case .contacts: "person.crop.circle.fill"
        case .trash: "trash.fill"
        case .settings: "gearshape.fill"
        case .notifications: "bell.badge.fill"
        case .calendar: "calendar"
        case .notes: "note.text"
        case .location: "map.fill"
        }
    }

    private static func scale(_ app: AppID) -> CGFloat {
        switch app {
        case .messages: 0.40
        case .contacts, .settings, .browser: 0.50
        default: 0.44
        }
    }
}

/// A calendar page: red band with the weekday, the day in large type.
private struct CalendarIconFace: View {
    let day: Moment?
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(day.map { PhoneFormat.weekdayShort($0) } ?? "")
                .font(.custom(Theme.FontName.semibold, fixedSize: size * 0.15))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: size * 0.28)
                .background(Theme.Colors.alert)
            Group {
                if let day {
                    Text("\(day.day)")
                        .font(.custom(Theme.FontName.medium, fixedSize: size * 0.44))
                        .foregroundStyle(Theme.iconGlyph(.calendar))
                } else {
                    // Month grid: 3 rows of dots, one in red.
                    VStack(spacing: size * 0.07) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: size * 0.07) {
                                ForEach(0..<4, id: \.self) { col in
                                    Circle()
                                        .fill(row == 1 && col == 2 ? Theme.Colors.alert : Theme.iconGlyph(.calendar).opacity(0.55))
                                        .frame(width: size * 0.08, height: size * 0.08)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// A lined note: amber band, three ruled lines.
private struct NotesIconFace: View {
    let size: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: size * 0.11) {
            Rectangle().fill(Theme.Colors.signal).frame(height: size * 0.22)
            ForEach(0..<3, id: \.self) { line in
                Capsule()
                    .fill(Theme.iconGlyph(.notes).opacity(0.35))
                    .frame(width: size * (line == 2 ? 0.42 : 0.66), height: size * 0.045)
                    .padding(.leading, size * 0.16)
            }
            Spacer(minLength: 0)
        }
    }
}

/// A folded city map: blocks, a main road, a river, and a red pin.
private struct MapIconFace: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Canvas { context, canvas in
                let w = canvas.width, h = canvas.height
                // Park.
                context.fill(Path(roundedRect: CGRect(x: w * 0.08, y: h * 0.1, width: w * 0.34, height: h * 0.3), cornerRadius: w * 0.05),
                             with: .color(Theme.Colors.iconMapPark))
                // River.
                var river = Path()
                river.move(to: CGPoint(x: 0, y: h * 0.78))
                river.addCurve(to: CGPoint(x: w, y: h * 0.62), control1: CGPoint(x: w * 0.35, y: h * 0.95), control2: CGPoint(x: w * 0.6, y: h * 0.5))
                context.stroke(river, with: .color(Theme.Colors.iconMapRiver), lineWidth: w * 0.1)
                // Streets.
                var streets = Path()
                streets.move(to: CGPoint(x: w * 0.55, y: 0)); streets.addLine(to: CGPoint(x: w * 0.55, y: h))
                streets.move(to: CGPoint(x: 0, y: h * 0.48)); streets.addLine(to: CGPoint(x: w, y: h * 0.48))
                context.stroke(streets, with: .color(Theme.Colors.iconMapStreet), lineWidth: w * 0.035)
                // Main road.
                var road = Path()
                road.move(to: CGPoint(x: 0, y: h * 0.2))
                road.addQuadCurve(to: CGPoint(x: w, y: h * 0.95), control: CGPoint(x: w * 0.7, y: h * 0.25))
                context.stroke(road, with: .color(Theme.Colors.iconMapRoad), lineWidth: w * 0.07)
            }
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: size * 0.36, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Theme.Colors.textPrimary, Theme.Colors.mapPin)
                .offset(x: size * 0.08, y: -size * 0.1)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
    }
}

#endif
