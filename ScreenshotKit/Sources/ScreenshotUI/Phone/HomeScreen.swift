#if os(iOS)
import SwiftUI
import CaseEngine

/// Screen 08 — the phone's home screen: date + story time, "periodic table" app tiles, dock.
struct HomeScreen: View {
    let session: GameSession

    private var gridApps: [AppID] { AppID.allCases.filter { !AppID.dock.contains($0) } }

    var body: some View {
        let game = session.game
        let now = session.phoneTime
        VStack(spacing: 0) {
            VStack(spacing: Theme.Spacing.s1) {
                Text(PhoneFormat.longDayCapitalized(now))
                    .font(.custom(Theme.FontName.medium, fixedSize: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(PhoneFormat.time(now))
                    .accessibilityIdentifier("phone.clock")
                    .font(Theme.Fonts.homeClock)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(.top, Theme.Spacing.s7)
            .padding(.bottom, Theme.Spacing.s8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.s5), count: 4),
                      spacing: 22) {
                ForEach(gridApps, id: \.self) { app in
                    AppTile(app: app, badge: badge(for: app, in: game), locked: game.access(to: app) == .locked,
                            calendarDay: app == .calendar ? now : nil) {
                        session.launch(app)
                    }
                }
            }
            .padding(.horizontal, 22)

            Spacer(minLength: 0)

            HStack {
                ForEach(AppID.dock, id: \.self) { app in
                    AppTile(app: app, badge: badge(for: app, in: game), locked: false, showsLabel: false) {
                        session.launch(app)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, Theme.Spacing.s4)
            .padding(.horizontal, Theme.Spacing.s3)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.dock, style: .continuous).fill(Theme.Colors.bgRaised.opacity(0.6)))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.dock, style: .continuous))
            .padding(.horizontal, 14)
            .padding(.bottom, Theme.Spacing.bottomInset - Theme.Spacing.s5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Wallpaper())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func badge(for app: AppID, in game: Investigation) -> Int {
        switch app {
        case .messages: game.conversations.reduce(0) { $0 + $1.unread }
        case .phone: game.calls.filter { $0.direction == .missed && $0.at.dayNumber == game.phoneNow.dayNumber }.count
        case .mail: game.device.mails.filter { $0.unread == true }.count
        case .notifications: game.unreadNotificationsCount
        default: 0
        }
    }
}

/// Wallpaper placeholder: a very dark photo (striped placeholder until a real one exists).
struct Wallpaper: View {
    var body: some View {
        ZStack {
            Theme.Colors.ink0
            StripedPattern().opacity(0.6)
            LinearGradient(colors: [Theme.Colors.ink0.opacity(0.2), Theme.Colors.ink0.opacity(0.85)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

/// App tile 62 × 62, r 17, bg.raised + line: two letters (Geist 500 21). The Agenda tile is dynamic.
struct AppTileGlyph: View {
    let app: AppID
    var size: CGFloat = Theme.Size.appTile
    var calendarDay: Moment? = nil
    var onLight = false

    var body: some View {
        RoundedRectangle(cornerRadius: size * Theme.Radius.icon / Theme.Size.appTile, style: .continuous)
            .fill(onLight ? Theme.Colors.textOnLight : Theme.Colors.bgRaised)
            .overlay(
                RoundedRectangle(cornerRadius: size * Theme.Radius.icon / Theme.Size.appTile, style: .continuous)
                    .strokeBorder(Theme.Colors.line2, lineWidth: 1.5)
            )
            .overlay {
                if let day = calendarDay {
                    VStack(spacing: 0) {
                        Text(PhoneFormat.weekdayShort(day))
                            .font(.custom(Theme.FontName.monoSemibold, fixedSize: size * 0.16))
                            .foregroundStyle(Theme.Colors.alertText)
                        Text("\(day.day)")
                            .font(.custom(Theme.FontName.medium, fixedSize: size * 0.36))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                } else {
                    Text(Theme.tileLetters(app))
                        .font(.custom(Theme.FontName.medium, fixedSize: size * 0.34))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .frame(width: size, height: size)
    }
}

struct AppTile: View {
    let app: AppID
    let badge: Int
    let locked: Bool
    var showsLabel = true
    var calendarDay: Moment? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AppTileGlyph(app: app, calendarDay: calendarDay)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.custom(Theme.FontName.monoSemibold, fixedSize: 12))
                                .foregroundStyle(Theme.Colors.textOnLight)
                                .padding(.horizontal, 5)
                                .frame(minWidth: Theme.Size.badge, minHeight: Theme.Size.badge)
                                .background(Capsule().fill(Theme.Colors.signal))
                                .offset(x: 6, y: -6)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .padding(4)
                                .background(Circle().fill(Theme.Colors.bgSelected))
                                .offset(x: 4, y: 4)
                        }
                    }
                    .opacity(locked ? 0.45 : 1)
                if showsLabel {
                    Text(app.title)
                        .font(Theme.Fonts.tabLabel)
                        .foregroundStyle(Theme.Colors.textPrimary.opacity(locked ? 0.45 : 1))
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(badge > 0 ? L10n.f("a11y.appBadge", app.title, badge) : app.title))
        .accessibilityIdentifier("app.\(app.rawValue)")
    }
}
#endif
