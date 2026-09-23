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

            // Search the whole phone (screen 11), like the system search pill.
            Button { session.open(.search) } label: {
                HStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: "magnifyingglass")
                    Text(L10n.t("search.pill"))
                }
                .font(Theme.Fonts.calloutStrong)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.s5)
                .frame(height: 36)
                .background(Capsule().fill(Theme.Colors.bgRaised.opacity(0.7)))
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("phone.search")
            .padding(.bottom, Theme.Spacing.s4)

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

/// Wallpaper: a deep night gradient with two soft, blurred lights — dark, but clearly a phone's
/// lock/home screen, not an empty black surface.
struct Wallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.Colors.wallpaperTop, Theme.Colors.wallpaperBottom], startPoint: .top, endPoint: .bottom)
            GeometryReader { geo in
                Circle().fill(Theme.Colors.wallpaperLightA)
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 70)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.2)
                Circle().fill(Theme.Colors.wallpaperLightB)
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 80)
                    .position(x: geo.size.width * 0.95, y: geo.size.height * 0.62)
            }
            LinearGradient(colors: [.clear, Theme.Colors.wallpaperBottom.opacity(0.7)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .padding(.horizontal, 5)
                                .frame(minWidth: Theme.Size.badge, minHeight: Theme.Size.badge)
                                .background(Capsule().fill(Theme.Colors.alert))
                                .overlay(Capsule().strokeBorder(Theme.Colors.wallpaperBottom.opacity(0.6), lineWidth: 1))
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
                    .saturation(locked ? 0.2 : 1)
                    .opacity(locked ? 0.6 : 1)
                if showsLabel {
                    Text(app.title)
                        .font(Theme.Fonts.tabLabel)
                        .foregroundStyle(Theme.Colors.textPrimary.opacity(locked ? 0.6 : 1))
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(badge > 0 ? L10n.f("a11y.appBadge", app.title, badge) : app.title))
        .accessibilityIdentifier("app.\(app.rawValue)")
    }
}
#endif
