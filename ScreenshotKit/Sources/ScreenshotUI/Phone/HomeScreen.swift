#if os(iOS)
import SwiftUI
import CaseEngine

/// Home screen of the seized phone: date and clock widget, apps grid, dock.
struct HomeScreen: View {
    let session: GameSession

    private var gridApps: [AppID] { AppID.allCases.filter { !AppID.dock.contains($0) } }

    var body: some View {
        let game = session.game
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.xxs) {
                Text(PhoneFormat.longDayCapitalized(game.phoneNow))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary.opacity(0.85))
                Text(PhoneFormat.time(game.phoneNow))
                    .font(Theme.Fonts.lockClock)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
            }
            .padding(.top, Theme.Spacing.l)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.m), count: 4),
                      spacing: Theme.Spacing.xl) {
                ForEach(gridApps, id: \.self) { app in
                    AppIconButton(app: app, badge: badge(for: app, in: game), locked: game.access(to: app) == .locked) {
                        session.launch(app)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)

            Spacer(minLength: 0)

            HStack {
                ForEach(AppID.dock, id: \.self) { app in
                    AppIconButton(app: app, badge: badge(for: app, in: game), locked: false, showsLabel: false) {
                        session.launch(app)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Theme.Spacing.m)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.phone, style: .continuous))
            .padding(.horizontal, Theme.Spacing.s)
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

/// Dark, subtle wallpaper (no picture: a soft gradient and a faint glow).
struct Wallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1320), Color(hex: 0x05070B)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: 0x1D3A5C).opacity(0.55), .clear], center: .topTrailing, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Color(hex: 0x3A1D2F).opacity(0.35), .clear], center: .bottomLeading, startRadius: 10, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}

struct AppIconGlyph: View {
    let app: AppID
    var size: CGFloat = Theme.Size.appIcon

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
            .fill(LinearGradient(colors: Theme.appTint(app), startPoint: .top, endPoint: .bottom))
            .overlay(
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(app.symbolColor)
            )
            .frame(width: size, height: size)
    }
}

struct AppIconButton: View {
    let app: AppID
    let badge: Int
    let locked: Bool
    var showsLabel = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                AppIconGlyph(app: app)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(Theme.Fonts.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Capsule().fill(Theme.Colors.alert))
                                .offset(x: 6, y: -6)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(Theme.Fonts.caption2)
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(.black.opacity(0.7)))
                                .offset(x: 4, y: 4)
                        }
                    }
                if showsLabel {
                    Text(app.title)
                        .font(Theme.Fonts.appLabel)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(badge > 0 ? L10n.f("a11y.appBadge", app.title, badge) : app.title))
    }
}
#endif
