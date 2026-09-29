#if os(iOS)
import SwiftUI
import CaseEngine

/// The seized phone (handoff UX V3 §2, §6-03): a real, light phone that fills the screen above the
/// BEN's investigation bar — no device mock around it. Its fictional status bar (the phone's own
/// time and battery), its apps, its notifications and the home indicator; the EvidenceBadge of the
/// element the player touched is drawn here, above every app screen. The investigation bar, the
/// EvidenceSheet and the Carnet belong to the shell (`InvestigationView`).
struct PhoneView: View {
    let session: GameSession
    /// Apps open from (and close back into) their icon, like on iOS.
    @Namespace private var appZoom
    /// Where the selected element is (its badge is drawn by `EvidenceBadgeLayer`).
    @State private var badgeAnchor = EvidenceBadgeAnchor()
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        GeometryReader { geo in
            let top = max(geo.safeAreaInsets.top, PhoneLayout.minStatusBar)
            screen(statusBar: top)
                .ignoresSafeArea(edges: .top)
        }
        .environment(\.colorScheme, .light)
        .environment(badgeAnchor)
    }

    /// Everything shown on the phone's glass.
    private func screen(statusBar: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // On the home screen the wallpaper shows through the status bar, like a real phone.
            if session.path.isEmpty {
                Wallpaper(style: session.game.device.wallpaper ?? .night)
            } else {
                Theme.Colors.bgBase
            }

            VStack(spacing: 0) {
                // Room for the status bar, which is drawn on top.
                Color.clear.frame(height: statusBar)
                NavigationStack(path: Binding(get: { session.path }, set: { session.setPath($0) })) {
                    HomeScreen(session: session, zoom: appZoom)
                        .navigationDestination(for: PhoneRoute.self) { route in
                            destination(route)
                                .phoneAppStyle(session)
                        }
                }
                .tint(Theme.Colors.textPrimary)
            }

            StatusBar(session: session)
                .frame(height: statusBar)
                .background(session.path.isEmpty ? Color.clear : Theme.Colors.bgBase.opacity(0.94))
                .zIndex(1)

            // The selected element's « + Verser au dossier ».
            EvidenceBadgeLayer(session: session, anchor: badgeAnchor, topInset: statusBar,
                               bottomInset: PhoneLayout.barClearance)
                .zIndex(2)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HomeIndicator { session.goHome() }
            }
            .zIndex(2)

            if let banner = session.banner {
                if banner.level == .urgent {
                    Theme.Colors.scrim
                        .onTapGesture { session.dismissBanner() }
                        .transition(.opacity)
                        .zIndex(3)
                }
                NotificationBanner(notification: banner, session: session)
                    .padding(.horizontal, 10)
                    .padding(.top, statusBar + Theme.Spacing.s2)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .zIndex(4)
            }

            // Short confirmations (« Retirée du dossier »…): at the top, under the status bar.
            if let toast = session.toast {
                ToastView(toast: toast)
                    .padding(.top, statusBar + Theme.Spacing.s3)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    .allowsHitTesting(false)
                    .zIndex(5)
            }

            // Back from the background (or the pause sheet): « En pause » until the first tap.
            if session.isPaused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { session.resume() }
                    .accessibilityElement()
                    .accessibilityLabel(Text(L10n.t("a11y.resume")))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { session.resume() }
                    .zIndex(6)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Theme.Motion.springNotification, value: session.banner)
        .animation(Theme.Motion.emphasized(0.2), value: session.toast)
    }

    @ViewBuilder
    private func destination(_ route: PhoneRoute) -> some View {
        switch route {
        case .app(let app): AppContainer(app: app, session: session).appZoomDestination(app, in: appZoom)
        case .search: GlobalSearchView(session: session)
        case .conversation(let id, let focus): ConversationView(conversationID: id, focus: focus, session: session)
        case .contact(let id): ContactDetailView(contactID: id, session: session)
        case .photo(let id): PhotoDetailView(photoID: id, session: session)
        case .track(let id): TrackView(trackID: id, session: session)
        case .calendarEvent(let id): CalendarEventView(eventID: id, session: session)
        case .note(let id): NoteView(noteID: id, session: session)
        case .mail(let id): MailView(mailID: id, session: session)
        case .browserEntry(let id): BrowserPageView(entryID: id, session: session)
        }
    }
}

/// Layout of the game elements on the phone.
enum PhoneLayout {
    /// The fictional status bar's height when the device has no top inset (no notch).
    static let minStatusBar: CGFloat = 28
    /// Height of the phone's own home indicator zone at the bottom of the glass, plus a gap: a
    /// screen that does not scroll keeps its controls above it (indicator 24 + 8, gap 8).
    static let barClearance: CGFloat = 40
}

/// Routes an app to its screen, or to its lock screen.
struct AppContainer: View {
    let app: AppID
    let session: GameSession

    var body: some View {
        Group {
            if session.game.access(to: app) == .locked {
                AppLockView(app: app, session: session)
            } else {
                switch app {
                case .messages: MessagesListView(session: session)
                case .phone: CallsView(session: session)
                case .photos: PhotosGridView(session: session)
                case .location: LocationView(session: session)
                case .calendar: CalendarListView(session: session)
                case .notes: NotesListView(session: session)
                case .browser: BrowserHistoryView(session: session)
                case .mail: MailListView(session: session)
                case .contacts: ContactsListView(session: session)
                case .trash: TrashView(session: session)
                case .settings: SettingsView(session: session)
                case .notifications: NotificationsView(session: session)
                }
            }
        }
        .background(Theme.Colors.bgBase.ignoresSafeArea())
    }
}

/// Common look of every phone screen: light base, no list chrome, room for the home indicator.
/// A tap anywhere on the screen hides the EvidenceBadge of the selected element (§6-04).
struct PhoneAppStyle: ViewModifier {
    var session: GameSession? = nil

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture().onEnded { session?.clearSelectionAfterTap() })
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.bgBase.ignoresSafeArea())
            .contentMargins(.bottom, Theme.Spacing.bottomInset, for: .scrollContent)
            .toolbarBackground(Theme.Colors.bgBase.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .listRowBackground(Theme.Colors.bgRaised)
            .font(Theme.Fonts.body)
    }
}

extension View {
    func phoneAppStyle(_ session: GameSession? = nil) -> some View { modifier(PhoneAppStyle(session: session)) }

    /// The app icon an app zooms out of (iOS 18+; a plain push before).
    @ViewBuilder
    func appZoomSource(_ app: AppID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: app, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func appZoomDestination(_ app: AppID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: app, in: namespace))
        } else {
            self
        }
    }
}

// MARK: - Status bar

/// The seized phone's status bar: its own time (the fiction's, which moves with the time spent),
/// the network and its battery. Dark on light, like a real phone. The time is « phone.clock ».
struct StatusBar: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Text(PhoneFormat.time(session.phoneTime))
                .font(Theme.font(Theme.FontName.semibold, 16))
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityLabel(Text(PhoneFormat.time(session.phoneTime)))
                .accessibilityIdentifier("phone.clock")
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                BatteryIndicator(level: session.batteryLevel)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.Colors.textPrimary)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 30)
        .padding(.top, Theme.Spacing.s2)
        .frame(maxHeight: .infinity)
    }
}

/// The seized phone's battery: it was low when the police handed it over, and drains while you
/// search it (a quiet reminder that time is running out). Percentage next to the icon, red under 10 %.
struct BatteryIndicator: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            Text("\(level)")
                .font(Theme.font(Theme.FontName.semibold, 11))
                .monospacedDigit()
            Image(systemName: level <= 10 ? "battery.0" : level <= 35 ? "battery.25" : "battery.50")
                .foregroundStyle(level <= 10 ? Theme.Colors.alertText : Theme.Colors.textPrimary)
        }
    }
}

/// A countdown as VoiceOver should say it, in the interface language: « 4 minutes et 12 secondes ».
enum SpokenDuration {
    static func text(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = total >= 60 ? [.minute, .second] : [.second]
        formatter.zeroFormattingBehavior = total == 0 ? .default : .dropAll
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "fr")
        formatter.calendar = calendar
        return formatter.string(from: TimeInterval(total)) ?? PhoneFormat.countdown(seconds)
    }
}

/// 134 × 5 at the very bottom: tap (or swipe up) to go back to the phone's home screen.
struct HomeIndicator: View {
    let action: () -> Void

    var body: some View {
        Capsule()
            .fill(Theme.Colors.textPrimary)
            .frame(width: Theme.Size.homeIndicator.width, height: Theme.Size.homeIndicator.height)
            .frame(maxWidth: .infinity, minHeight: 24)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                if value.translation.height < -20 { action() }
            })
            .padding(.bottom, Theme.Spacing.s3)
            .accessibilityElement()
            .accessibilityLabel(Text(L10n.t("a11y.home")))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
            .accessibilityIdentifier("phone.home")
    }
}

// MARK: - Notification banner

/// r 22, e2, blur. Normal (4 s) · important (6 s, outlined) · urgent (inverted, stays, two actions).
struct NotificationBanner: View {
    let notification: PhoneNotification
    let session: GameSession

    private var urgent: Bool { notification.level == .urgent }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            if urgent {
                Text(L10n.t("notif.urgentContext"))
                    .overline(Theme.Colors.textOnLight.opacity(0.6))
            }
            HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                AppTileGlyph(app: notification.app, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(notification.title).font(Theme.Fonts.notificationTitle).lineLimit(1)
                        Spacer()
                        Text(L10n.t("notif.now")).font(Theme.Fonts.dataSmall).opacity(0.6)
                    }
                    Text(notification.body)
                        .font(urgent ? Theme.Fonts.body : Theme.Fonts.notificationBody)
                        .lineLimit(urgent ? 4 : 3)
                        .multilineTextAlignment(.leading)
                }
            }
            if urgent {
                HStack(spacing: Theme.Spacing.s3) {
                    Button(L10n.t("notif.open")) { session.open(notification) }
                        .buttonStyle(UrgentActionStyle(filled: true))
                        .accessibilityIdentifier("banner.open")
                    Button("+ " + L10n.t("pin.add")) {
                        if let ref = notification.opens { session.file(ref) }
                        session.dismissBanner()
                    }
                    .buttonStyle(UrgentActionStyle(filled: false))
                    .disabled(notification.opens == nil)
                }
            }
        }
        .foregroundStyle(urgent ? Theme.Colors.textOnLight : Theme.Colors.textPrimary)
        .padding(Theme.Spacing.s4)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous)
                .fill(urgent ? Theme.Colors.textPrimary : Theme.Colors.bgBubbleIn.opacity(0.9))
        )
        .background {
            if !urgent {
                RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous).fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous)
                .strokeBorder(notification.level == .important ? Theme.Colors.line3 : .clear, lineWidth: 1)
        )
        .elevation2()
        .contentShape(Rectangle())
        .onTapGesture { if !urgent { session.open(notification) } }
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            if value.translation.height < -10 { session.dismissBanner() }
        })
        .accessibilityElement(children: urgent ? .contain : .combine)
        .accessibilityAddTraits(urgent ? [] : .isButton)
        .accessibilityIdentifier("phone.banner")
    }
}

struct UrgentActionStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.calloutStrong)
            .foregroundStyle(filled ? Theme.Colors.textPrimary : Theme.Colors.textOnLight)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(filled ? Theme.Colors.textOnLight : Theme.Colors.line1))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
#endif
