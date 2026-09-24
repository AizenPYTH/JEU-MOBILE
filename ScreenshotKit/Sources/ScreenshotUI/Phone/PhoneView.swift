#if os(iOS)
import SwiftUI
import CaseEngine

/// The seized phone — the whole screen. Only two game elements sit on top of the fictional OS:
/// the timer (in place of the clock) and the "Carnet · Indice" capsule (at the thumb).
struct PhoneView: View {
    let session: GameSession
    let onNotebook: () -> Void
    let onHints: () -> Void
    let onTimer: () -> Void
    let onQuit: () -> Void
    /// Apps open from (and close back into) their icon, like on iOS.
    @Namespace private var appZoom

    var body: some View {
        ZStack {
            DeskBackground()
            PhoneDevice { screen }
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.top, Theme.Spacing.s1)
                .padding(.bottom, Theme.Spacing.s2)
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .bottom)
    }

    /// Everything shown on the seized phone's glass.
    private var screen: some View {
        ZStack(alignment: .top) {
            Theme.Colors.bgBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // Room for the status bar, which is drawn on top: the phone screens' backgrounds
                // extend to the top edge and would otherwise cover the timer.
                Color.clear.frame(height: Theme.Size.statusBar)
                NavigationStack(path: Binding(get: { session.path }, set: { session.setPath($0) })) {
                    HomeScreen(session: session, zoom: appZoom)
                        .navigationDestination(for: PhoneRoute.self) { route in
                            destination(route)
                                .phoneAppStyle()
                        }
                }
                .tint(Theme.Colors.textPrimary)
            }
            .ignoresSafeArea(edges: .top)

            // On the home screen the wallpaper shows through the status bar, like a real phone.
            StatusBar(session: session, onTimer: onTimer)
                .background(session.path.isEmpty ? Color.clear : Theme.Colors.bgBase.opacity(0.94))
                .ignoresSafeArea(edges: .top)
                .zIndex(1)

            // Bottom: scrim gradient 96 pt, capsule, home indicator.
            VStack(spacing: Theme.Spacing.s3) {
                Spacer()
                HStack(spacing: Theme.Spacing.s3) {
                    QuitButton(action: onQuit)
                    CarnetBar(count: session.game.notebook.count, hintAvailable: session.game.nextHint != nil,
                              onNotebook: onNotebook, onHints: onHints)
                }
                HomeIndicator { session.goHome() }
            }
            .background(alignment: .bottom) {
                LinearGradient(colors: [.clear, Theme.Colors.bgBase.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 96 + Theme.Size.carnetBar)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)

            if session.timerLevel == .critical {
                CriticalVignette().allowsHitTesting(false)
            }

            if let banner = session.banner {
                if banner.level == .urgent {
                    Theme.Colors.scrim.ignoresSafeArea()
                        .onTapGesture { session.dismissBanner() }
                        .transition(.opacity)
                }
                NotificationBanner(notification: banner, session: session)
                    .padding(.horizontal, 10)
                    .padding(.top, Theme.Size.statusBar + Theme.Spacing.s3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }

            if let toast = session.toast {
                VStack {
                    Spacer()
                    ToastView(toast: toast)
                        .padding(.bottom, Theme.Spacing.bottomInset)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .allowsHitTesting(false)
                .zIndex(3)
            }
        }
        .animation(Theme.Motion.springNotification, value: session.banner)
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

/// Common look of every phone screen: dark base, no list chrome, room for the notebook capsule.
struct PhoneAppStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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
    func phoneAppStyle() -> some View { modifier(PhoneAppStyle()) }

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

// MARK: - The device

/// The seized phone as an object: dark metal frame, black bezel, camera island, side buttons,
/// a faint reflection on the glass and a soft shadow that separates it from the background.
/// It is the phone being searched, not a marketing mockup: the screen stays the whole game.
struct PhoneDevice<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        let outer = RoundedRectangle(cornerRadius: Theme.Size.deviceRadius, style: .continuous)
        let screenRadius = Theme.Size.deviceRadius - Theme.Size.deviceFrame - Theme.Size.deviceBezel
        let glass = RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
        content
            .clipShape(glass)
            .overlay(alignment: .top) {
                CameraIsland().padding(.top, 11).allowsHitTesting(false)
            }
            .overlay {
                glass.fill(LinearGradient(colors: [Theme.Colors.deviceGlare, .clear],
                                          startPoint: .topLeading, endPoint: UnitPoint(x: 0.55, y: 0.3)))
                    .allowsHitTesting(false)
            }
            .padding(Theme.Size.deviceBezel)
            .background(RoundedRectangle(cornerRadius: screenRadius + Theme.Size.deviceBezel, style: .continuous)
                .fill(Theme.Colors.deviceBezel))
            .padding(Theme.Size.deviceFrame)
            .background(outer.fill(LinearGradient(colors: [Theme.Colors.deviceFrameTop, Theme.Colors.deviceFrameBottom],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(outer.strokeBorder(LinearGradient(colors: [Theme.Colors.deviceEdge, Theme.Colors.deviceEdge.opacity(0.15)],
                                                       startPoint: .top, endPoint: .bottom), lineWidth: 1))
            .background(alignment: .topLeading) { SideButtons(leading: true) }
            .background(alignment: .topTrailing) { SideButtons(leading: false) }
            .shadow(color: .black.opacity(0.6), radius: 24, y: 14)
    }
}

/// Pill-shaped camera island at the top of the screen.
struct CameraIsland: View {
    var body: some View {
        Capsule()
            .fill(Theme.Colors.deviceBezel)
            .frame(width: Theme.Size.island.width, height: Theme.Size.island.height)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(Theme.Colors.deskGlow)
                    .overlay(Circle().strokeBorder(Theme.Colors.line2, lineWidth: 1))
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 12)
            }
            .accessibilityHidden(true)
    }
}

/// Action + volume buttons on the left edge, power on the right.
struct SideButtons: View {
    let leading: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.s4) {
            if leading {
                button(height: 26)
                button(height: 50)
                button(height: 50)
            } else {
                button(height: 80)
            }
        }
        .padding(.top, leading ? 118 : 170)
        .offset(x: leading ? -2.5 : 2.5)
        .accessibilityHidden(true)
    }

    private func button(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Theme.Colors.deviceButton)
            .frame(width: 3, height: height)
    }
}

/// Behind the phone: near-black with a cold glow, so the device reads as an object.
struct DeskBackground: View {
    var body: some View {
        ZStack {
            Theme.Colors.ink0
            RadialGradient(colors: [Theme.Colors.deskGlow, Theme.Colors.ink0], center: .center, startRadius: 40, endRadius: 520)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Status bar with the timer

/// h 54. The timer pill replaces the clock: normal · low (≤ 01:00, amber, breathing halo) ·
/// critical (≤ 00:10, red, opacity 1 ↔ .72). Never blinks. A 2 pt track shows the time left.
struct StatusBar: View {
    let session: GameSession
    let onTimer: () -> Void

    var body: some View {
        let level = session.timerLevel
        HStack(spacing: Theme.Spacing.s3) {
            Button(action: onTimer) {
                TimerPill(remaining: session.remainingSeconds, level: level)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.f("a11y.timer", PhoneFormat.countdown(session.remainingSeconds))))
            .accessibilityHint(Text(L10n.t("a11y.timerHint")))
            .accessibilityIdentifier("phone.timer")

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
        .overlay(alignment: .bottomLeading) {
            // The time an action just cost, under the timer (never hidden by the camera island).
            if let cost = session.lastCost {
                Text(L10n.f("bar.cost", cost.seconds))
                    .font(Theme.Fonts.dataStrong)
                    .foregroundStyle(Theme.Colors.alertText)
                    .padding(.horizontal, Theme.Spacing.s3)
                    .frame(height: 22)
                    .background(Capsule().fill(Theme.Colors.alertTint))
                    .background(Capsule().fill(Theme.Colors.bgBase))
                    .id(cost.id)
                    .offset(y: 26)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .allowsHitTesting(false)
            }
        }
        .padding(.leading, 26)
        .padding(.trailing, 30)
        .padding(.top, Theme.Spacing.s3)
        .frame(height: Theme.Size.statusBar)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.Colors.line1)
                    Rectangle()
                        .fill(level == .critical ? Theme.Colors.alert : level == .low ? Theme.Colors.signal : Theme.Colors.line3)
                        .frame(width: geo.size.width * session.timeProgress)
                }
            }
            .frame(height: Theme.Size.progressTrack)
            .offset(y: 4)
            .accessibilityHidden(true)
        }
        .animation(Theme.Motion.standard(Theme.Motion.fast), value: session.lastCost)
    }
}

/// The seized phone's battery: it was low when the police handed it over, and drains while you
/// search it (a quiet reminder that time is running out). Percentage next to the icon, red under 10 %.
struct BatteryIndicator: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            Text("\(level)")
                .font(.custom(Theme.FontName.semibold, fixedSize: 11))
                .monospacedDigit()
            Image(systemName: level <= 10 ? "battery.0" : level <= 35 ? "battery.25" : "battery.50")
                .foregroundStyle(level <= 10 ? Theme.Colors.alertText : Theme.Colors.textPrimary)
        }
    }
}

struct TimerPill: View {
    let remaining: Double
    let level: GameSession.TimerLevel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let color: Color = level == .critical ? Theme.Colors.alertText : level == .low ? Theme.Colors.signal : Theme.Colors.textPrimary
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: Theme.Size.timerDot, height: Theme.Size.timerDot)
            Text(PhoneFormat.countdown(remaining))
                .font(level == .critical ? Theme.Fonts.timerCritical : Theme.Fonts.timer)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .frame(height: Theme.Size.timerPill)
        .background(Capsule().fill(level == .normal ? Theme.Colors.bgRaised : (level == .low ? Theme.Colors.signalTint : Theme.Colors.alertTint)))
        .phaseAnimator(reduceMotion || level == .normal ? [1.0] : [1.0, level == .critical ? 0.72 : 0.9]) { view, value in
            view
                .opacity(level == .critical ? value : 1)
                .shadow(color: level == .low ? Theme.Colors.signal.opacity((1 - value) * 2.5) : .clear, radius: 3)
        } animation: { _ in
            .easeInOut(duration: level == .critical ? 0.5 : 1)
        }
    }
}

/// Red inner vignette in the last 10 seconds.
struct CriticalVignette: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .strokeBorder(Theme.Colors.alert.opacity(0.2), lineWidth: 90)
            .blur(radius: 60)
            .ignoresSafeArea()
            .phaseAnimator(reduceMotion ? [1.0] : [1.0, 0.6]) { view, value in
                view.opacity(value)
            } animation: { _ in .easeInOut(duration: 0.5) }
    }
}

// MARK: - Notebook capsule & home indicator

/// Capsule h 46, r 23, translucent: "◆ Carnet · n" and "Indice".
struct CarnetBar: View {
    let count: Int
    let hintAvailable: Bool
    let onNotebook: () -> Void
    let onHints: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onNotebook) {
                HStack(spacing: Theme.Spacing.s3) {
                    Text("◆").foregroundStyle(count > 0 ? Theme.Colors.signal : Theme.Colors.textTertiary)
                    Text(L10n.t("carnet.title")).foregroundStyle(Theme.Colors.textPrimary)
                    Text("\(count)")
                        .font(Theme.Fonts.dataStrong)
                        .foregroundStyle(count > 0 ? Theme.Colors.signal : Theme.Colors.textSecondary)
                        .contentTransition(.numericText())
                        .animation(Theme.Motion.emphasized(0.2), value: count)
                }
                .padding(.horizontal, Theme.Spacing.s5)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.f("a11y.carnet", count)))
            .accessibilityIdentifier("phone.carnet")

            Rectangle().fill(Theme.Colors.line2).frame(width: 1, height: 22)

            Button(action: onHints) {
                HStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: "lightbulb")
                    Text(L10n.t("bar.hint"))
                    if hintAvailable {
                        Circle().fill(Theme.Colors.signal).frame(width: 6, height: 6)
                    }
                }
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.s5)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("phone.hints")
        }
        .font(Theme.Fonts.calloutStrong)
        .frame(height: Theme.Size.carnetBar)
        .background(Capsule().fill(Theme.Colors.bgBubbleIn.opacity(0.88)))
        .background(.ultraThinMaterial, in: Capsule())
        .elevation1(Capsule())
        // A small bounce each time the notebook gains (or loses) an item: "it went there".
        .phaseAnimator([1.0, 1.07, 1.0], trigger: count) { view, scale in
            view.scaleEffect(scale)
        } animation: { _ in .spring(duration: 0.22, bounce: 0.4) }
    }
}

/// "Quitter l'enquête": a round button next to the notebook capsule (the investigation is saved).
struct QuitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: Theme.Size.carnetBar, height: Theme.Size.carnetBar)
                .background(Circle().fill(Theme.Colors.bgBubbleIn.opacity(0.88)))
                .background(.ultraThinMaterial, in: Circle())
                .elevation1(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("quit.a11y")))
        .accessibilityIdentifier("phone.quit")
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
                    Button("◆ " + L10n.t("pin.add")) {
                        if let ref = notification.opens { session.togglePin(ref) }
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
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(filled ? Theme.Colors.textOnLight : Color.black.opacity(0.08)))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
#endif
