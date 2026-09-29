#if os(iOS)
import SwiftUI
import CaseEngine

/// Screen 03 (handoff UX V3 §6-03) — the phone's home screen: light, the owner's wallpaper,
/// « Téléphone d'Alex Moreau » for 3 s, then a 4-column grid of every app (fixed order) and the
/// search pill. The fictional time and battery are in the status bar above it. In case #001, the
/// first time, the Messages icon pulses twice and a BEN bubble says « Commencez par les
/// messages. » until the first tap on an app (§7).
struct HomeScreen: View {
    let session: GameSession
    let zoom: Namespace.ID

    /// The Messages icon, in the home screen's space (the tip points at it).
    @State private var messagesIcon: CGRect = .zero
    /// « Téléphone de … » is shown for 3 s when the phone is first put in hand.
    @State private var ownerShown = true
    @State private var messagesPulse = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// The apps of the grid, in the handoff's order (§5 PhoneAppIcon), then the extra ones.
    static let gridApps: [AppID] = [.messages, .phone, .photos, .location, .calendar, .notes,
                                    .mail, .contacts, .browser, .notifications, .settings, .trash]

    var body: some View {
        let game = session.game
        let exploring = session.coach.active == .explore
        let columns = dynamicTypeSize.isAccessibilitySize ? 3 : 4
        VStack(spacing: 0) {
            Text(ownerLine(game))
                .font(Theme.font(Theme.FontName.medium, 13))
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(ownerShown ? 1 : 0)
                .padding(.top, Theme.Spacing.s4)
                .padding(.bottom, Theme.Spacing.s6)
                .accessibilityHidden(!ownerShown)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.s4), count: columns),
                      spacing: Theme.Spacing.s6) {
                ForEach(Self.gridApps, id: \.self) { app in
                    AppTile(app: app, badge: badge(for: app, in: game), locked: game.access(to: app) == .locked,
                            spotlight: exploring && app == .messages,
                            pulse: app == .messages && messagesPulse) {
                        launch(app)
                    }
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(homeSpace)) } action: { frame in
                        if app == .messages { messagesIcon = frame }
                    }
                    .appZoomSource(app, in: zoom)
                }
            }
            .padding(.horizontal, Theme.Spacing.s6)

            Spacer(minLength: Theme.Spacing.s5)

            // Search the whole phone, like the system search pill.
            Button { session.open(.search) } label: {
                HStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: "magnifyingglass")
                    Text(L10n.t("search.pill"))
                }
                .font(Theme.Fonts.calloutStrong)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.s5)
                .frame(minHeight: Theme.Size.hit)
                .background(Capsule().fill(Theme.Colors.bgRaised.opacity(0.85)))
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("phone.search")
            // Above the home indicator.
            .padding(.bottom, PhoneLayout.barClearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named(homeSpace))
        .overlay {
            if exploring && messagesIcon != .zero {
                exploreBubble
            }
        }
        .animation(.easeOut(duration: 0.2), value: exploring)
        .background(Wallpaper(style: session.game.device.wallpaper ?? .night))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { session.coach.homeAppeared() }
        // Leaving the home screen (an app, the search, a notification) answers the tip too.
        .onDisappear { session.coach.appOpened() }
        .task {
            // « Téléphone de … »: 3 s, then gone.
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.3)) { ownerShown = false }
        }
        .task(id: exploring) {
            // The Messages icon pulses twice (scale 1 → 1.04) while the tip is up.
            guard exploring, !(systemReduceMotion || appReduceMotion) else { return }
            try? await Task.sleep(for: .milliseconds(400))
            for _ in 0..<2 {
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.35)) { messagesPulse = true }
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeInOut(duration: 0.35)) { messagesPulse = false }
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    /// « Téléphone d'Alex Moreau »: the owner's full name, or the phone's label.
    private func ownerLine(_ game: Investigation) -> String {
        let owner = game.device.contacts.first { $0.isOwner == true } ?? game.device.contacts.first { $0.id == ownerContactID }
        guard let name = owner?.name, !name.isEmpty else { return game.device.label }
        let elided = name.first.map { "AEIOUYHÂÉÈÊÎÔÛaeiouyh".contains($0) } ?? false
        return L10n.f(elided ? "home.ownerElided" : "home.owner", name)
    }

    private func launch(_ app: AppID) {
        session.coach.appOpened()
        session.launch(app)
    }

    /// The tip, just under the Messages icon, its arrow pointing up at it. Taps go through it
    /// (only its × takes them).
    private var exploreBubble: some View {
        GeometryReader { geo in
            let width = min(homeBubbleWidth, geo.size.width - 24)
            let x = min(max(messagesIcon.midX - width / 2, 12), max(12, geo.size.width - 12 - width))
            CoachBubble(bubble: .explore, arrow: .top, arrowOffset: messagesIcon.midX - (x + width / 2)) {
                session.coach.dismiss()
            }
            .frame(width: width)
            .padding(.leading, x)
            .padding(.top, messagesIcon.maxY + 14)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
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

/// The home screen's coordinate space (the tip finds the Messages icon in it).
private let homeSpace = "phone.home.space"
private let homeBubbleWidth: CGFloat = 260

/// Wallpaper (§6-03): the phone is light — a pale base tinted by the owner's two soft lights, so
/// each case's phone keeps its own look (`Device.wallpaper`) and dark text stays readable on it.
struct Wallpaper: View {
    var style: Device.Wallpaper = .night

    static func palette(_ style: Device.Wallpaper) -> Theme.WallpaperPalette {
        switch style {
        case .night: Theme.Wallpapers.night
        case .ice: Theme.Wallpapers.ice
        case .shore: Theme.Wallpapers.shore
        case .gold: Theme.Wallpapers.gold
        case .storm: Theme.Wallpapers.storm
        case .dusk: Theme.Wallpapers.dusk
        }
    }

    var body: some View {
        let palette = Self.palette(style)
        ZStack {
            Theme.Colors.bgSurface
            GeometryReader { geo in
                Circle().fill(palette.lightA)
                    .frame(width: geo.size.width * 1.1)
                    .blur(radius: 90)
                    .opacity(wallpaperLightOpacity)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.15)
                Circle().fill(palette.lightB)
                    .frame(width: geo.size.width)
                    .blur(radius: 100)
                    .opacity(wallpaperLightOpacity)
                    .position(x: geo.size.width * 0.95, y: geo.size.height * 0.7)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// How much of the owner's colours tints the light wallpaper.
private let wallpaperLightOpacity: Double = 0.45

/// An app on the home screen: PhoneAppIcon (62 pt), its name in 12 pt, the unread badge in
/// `alert` (critical), a lock on a locked app.
struct AppTile: View {
    let app: AppID
    let badge: Int
    let locked: Bool
    var showsLabel = true
    var calendarDay: Moment? = nil
    /// The icon a tip points at (ben ring).
    var spotlight = false
    /// The tip's pulse (scale 1 → 1.04).
    var pulse = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                PhoneAppIcon(app: app, calendarDay: calendarDay)
                    .overlay {
                        if spotlight { CoachRing(radius: phoneTileRingRadius) }
                    }
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text(verbatim: "\(badge)")
                                .font(Theme.font(Theme.FontName.semibold, 13))
                                .monospacedDigit()
                                .foregroundStyle(Theme.Colors.textOnLight)
                                .padding(.horizontal, 5)
                                .frame(minWidth: Theme.Size.badge + 2, minHeight: Theme.Size.badge + 2)
                                .background(Capsule().fill(Theme.Colors.alert))
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
                    .opacity(locked ? 0.6 : 1)
                    .scaleEffect(pulse ? 1.04 : 1)
                if showsLabel {
                    Text(app.title)
                        .font(Theme.font(Theme.FontName.regular, 12))
                        .foregroundStyle(Theme.Colors.textPrimary.opacity(locked ? 0.6 : 1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(badge > 0 ? L10n.f("a11y.appBadge", app.title, badge) : app.title))
        .accessibilityIdentifier("app.\(app.rawValue)")
    }
}

/// The tip's ring around a 62 pt icon (its radius is 15).
private let phoneTileRingRadius: CGFloat = 15
#endif
