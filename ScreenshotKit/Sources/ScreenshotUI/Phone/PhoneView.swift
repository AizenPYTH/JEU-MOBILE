#if os(iOS)
import SwiftUI
import CaseEngine

/// The seized phone — the whole screen. Only three game elements sit on the fictional OS: the
/// timer tag hanging under the camera island, the pause button, and the dossier bar at the thumb
/// (« DOSSIER #00N · n pièces versées · CARNET »). A piece just filed flies into the bar (§F-07).
struct PhoneView: View {
    let session: GameSession
    let onNotebook: () -> Void
    let onQuit: () -> Void
    /// Apps open from (and close back into) their icon, like on iOS.
    @Namespace private var appZoom
    /// The paper copy of the piece just filed, on its way to the dossier bar.
    @State private var flight: GameSession.FiledPiece?
    @State private var flightStage = FlightStage.hidden
    /// The dossier bar's red border, for 600 ms after each filing.
    @State private var barPulse = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    enum FlightStage { case hidden, shown, landed }

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        ZStack {
            DeskBackground()
            PhoneDevice { screen }
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.top, Theme.Spacing.s1)
                .padding(.bottom, Theme.Spacing.s2)
        }
        .environment(\.colorScheme, .light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .bottom)
        .onChange(of: session.lastFiled) { _, piece in
            if let piece { fly(piece) }
        }
    }

    /// Everything shown on the seized phone's glass.
    private var screen: some View {
        let filed = session.game.notebook.count
        // The counter moves when the flying copy lands in the bar.
        let shown = max(0, filed - (flight == nil ? 0 : 1))
        return ZStack(alignment: .top) {
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
            StatusBar(session: session, onQuit: onQuit)
                .background(session.path.isEmpty ? Color.clear : Theme.Colors.bgBase.opacity(0.94))
                .ignoresSafeArea(edges: .top)
                .zIndex(1)

            // Bottom: scrim gradient, the dossier bar, the home indicator.
            VStack(spacing: Theme.Spacing.s3) {
                Spacer()
                DossierBar(caseNumber: session.caseFile.number, shown: shown, filed: filed,
                           pulse: barPulse, onNotebook: onNotebook)
                    .padding(.horizontal, PhoneLayout.barMargin)
                HomeIndicator { session.goHome() }
            }
            .background(alignment: .bottom) {
                LinearGradient(colors: [.clear, Theme.Colors.bgBase.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 96 + PhoneLayout.barHeight)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)

            if let banner = session.banner {
                if banner.level == .urgent {
                    Theme.Colors.scrim.ignoresSafeArea()
                        .onTapGesture { session.dismissBanner() }
                        .transition(.opacity)
                }
                NotificationBanner(notification: banner, session: session)
                    .padding(.horizontal, 10)
                    .padding(.top, Theme.Size.statusBar + Theme.Spacing.s3)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }

            // Tips and confirmations: at the top, under the timer tag.
            if let toast = session.toast {
                ToastView(toast: toast)
                    .padding(.top, PhoneLayout.toastTop)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    .allowsHitTesting(false)
                    .zIndex(3)
            }

            if let flight {
                GeometryReader { geo in
                    let landed = flightStage == .landed
                    FiledPaperCopy(piece: flight, game: session.game)
                        .scaleEffect(landed ? 0.2 : 1)
                        .opacity(flightStage == .shown ? 1 : (landed ? 0.3 : 0))
                        .position(x: landed ? geo.size.width * 0.3 : geo.size.width / 2,
                                  y: landed ? geo.size.height - PhoneLayout.barCenterFromBottom : geo.size.height * 0.45)
                }
                .allowsHitTesting(false)
                .zIndex(4)
            }

            // Back from the background (or the pause sheet): « EN PAUSE » until the first tap.
            if session.isPaused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { session.resume() }
                    .accessibilityElement()
                    .accessibilityLabel(Text(L10n.t("a11y.resume")))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { session.resume() }
                    .zIndex(5)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Theme.Motion.springNotification, value: session.banner)
        .animation(Theme.Motion.emphasized(0.2), value: session.toast)
    }

    /// §F-07: the copy appears over the middle of the phone, shrinks and slides into the bar
    /// (420 ms, `paper`), then the bar pulses and its counter moves. Reduced motion: the pulse only.
    private func fly(_ piece: GameSession.FiledPiece) {
        guard !reduceMotion else {
            pulseBar()
            return
        }
        flightStage = .hidden
        flight = piece
        Task {
            // Let the filing sheet slide away first.
            try? await Task.sleep(for: .milliseconds(120))
            guard flight?.id == piece.id else { return }
            withAnimation(.easeOut(duration: 0.15)) { flightStage = .shown }
            try? await Task.sleep(for: .milliseconds(330))
            guard flight?.id == piece.id else { return }
            withAnimation(Trace.Motion.paper) { flightStage = .landed }
            try? await Task.sleep(for: .milliseconds(420))
            guard flight?.id == piece.id else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                flight = nil
                flightStage = .hidden
            }
            pulseBar()
        }
    }

    private func pulseBar() {
        withAnimation(.easeOut(duration: 0.12)) { barPulse = true }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeIn(duration: 0.2)) { barPulse = false }
        }
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

/// Layout of the game elements on the phone's glass.
enum PhoneLayout {
    /// The dossier bar (§F-05): 64 pt high, 12 pt from the edges, radius 10.
    static let barHeight: CGFloat = 64
    static let barMargin: CGFloat = 12
    static let barRadius: CGFloat = 10
    /// Centre of the bar from the bottom of the glass (home indicator 24 + 8, gap 8, half bar).
    static let barCenterFromBottom: CGFloat = 72
    /// Height of the glass the bar covers, plus a gap: a screen that does not scroll keeps its
    /// controls above it (home indicator 24 + 8, gap 8, bar 64, gap 8).
    static let barClearance: CGFloat = 112
    /// Top of the timer tag: it hangs just under the camera island.
    static let tagTop: CGFloat = 38
    /// Toasts sit under the timer tag.
    static let toastTop: CGFloat = 72
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

// MARK: - Status bar, timer tag, pause button

/// h 54: the pause button where the clock would be, the network and battery on the right, and a
/// 2 pt track of the time left. The timer tag hangs under the camera island, with the time an
/// action just cost next to it.
struct StatusBar: View {
    let session: GameSession
    let onQuit: () -> Void

    var body: some View {
        let level = session.timerLevel
        HStack(spacing: Theme.Spacing.s3) {
            QuitButton(action: onQuit)
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
        .padding(.leading, 14)
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
        .overlay(alignment: .top) {
            TimerTag(remaining: session.remainingSeconds,
                     critical: level != .normal || session.remainingSeconds <= 60,
                     paused: session.isPaused)
                .overlay(alignment: .bottomTrailing) {
                    // The time an action just cost (« −8 s »), beside the tag.
                    if let cost = session.lastCost {
                        Text(L10n.f("bar.cost", cost.seconds))
                            .font(Theme.Fonts.dataStrong)
                            .foregroundStyle(Theme.Colors.alertText)
                            .padding(.horizontal, Theme.Spacing.s3)
                            .frame(height: 22)
                            .background(Capsule().fill(Theme.Colors.alertTint))
                            .background(Capsule().fill(Theme.Colors.bgBase))
                            .fixedSize()
                            .alignmentGuide(.trailing) { d in d[.leading] - Theme.Spacing.s3 }
                            .alignmentGuide(.bottom) { d in d[.bottom] - 4 }
                            .id(cost.id)
                            .transition(.opacity)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, PhoneLayout.tagTop)
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
                .font(Theme.font(Theme.FontName.semibold, 11))
                .monospacedDigit()
            Image(systemName: level <= 10 ? "battery.0" : level <= 35 ? "battery.25" : "battery.50")
                .foregroundStyle(level <= 10 ? Theme.Colors.alertText : Theme.Colors.textPrimary)
        }
    }
}

/// The timer (§F-05): a paper label #ECE5D3, Plex Mono 13/700, tilted −1°, hanging under the camera
/// island. Under 01:00 it turns red (colour change in 400 ms, never blinking; the session ticks each
/// second and adds a light haptic under 00:10). Paused: outlined, « EN PAUSE ».
struct TimerTag: View {
    let remaining: Double
    let critical: Bool
    let paused: Bool

    private static let digits = Font.custom(Trace.FontName.monoBold, fixedSize: 13)
    private static let pausedLabel = Font.custom(Trace.FontName.monoBold, fixedSize: 9)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
        HStack(spacing: 6) {
            Text(PhoneFormat.countdown(remaining))
                .font(Self.digits)
                .monospacedDigit()
            if paused {
                Text(L10n.t("timer.paused"))
                    .font(Self.pausedLabel)
                    .tracking(1.2)
            }
        }
        .foregroundStyle(paused ? Trace.Colors.paper : (critical ? Trace.Colors.criticalText : Trace.Colors.ink))
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(shape.fill(paused ? Trace.Colors.desk.opacity(0.7) : (critical ? Trace.Colors.stamp : Trace.Colors.paper)))
        .overlay(shape.strokeBorder(Trace.Colors.paper, lineWidth: paused ? 1.5 : 0))
        .shadow(color: .black.opacity(paused ? 0 : 0.35), radius: 3, y: 2)
        .rotationEffect(.degrees(-1))
        .animation(.easeInOut(duration: 0.4), value: critical)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        // The digits for UI tests; VoiceOver reads the spoken form of the label first.
        .accessibilityValue(Text(PhoneFormat.countdown(remaining)))
        .accessibilityIdentifier("phone.timer")
    }

    /// « Temps restant : 4 minutes et 12 secondes » (+ « En pause »).
    private var accessibilityText: String {
        let spoken = L10n.f("a11y.timer", SpokenDuration.text(remaining))
        return paused ? spoken + ". " + L10n.t("timer.paused") : spoken
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

// MARK: - Dossier bar, pause button & home indicator

/// The dossier bar (§F-05), always on the phone: paper, 64 pt, radius 10. « DOSSIER #00N »,
/// « n pièces versées » and the CARNET button (outlined while the file is empty, full ink from the
/// first piece). A 2 pt red border pulses for 600 ms each time a piece lands in it.
struct DossierBar: View {
    let caseNumber: Int
    /// Pieces shown: the counter moves when the flying copy lands.
    let shown: Int
    /// Pieces really in the file (what VoiceOver says).
    let filed: Int
    let pulse: Bool
    let onNotebook: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PhoneLayout.barRadius, style: .continuous)
        let file = fileLabel(caseNumber)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(file)
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(Self.count(shown))
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onNotebook)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(file + ", " + Self.count(filed)))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onNotebook() }
            .accessibilityIdentifier("phone.bar")

            Button(action: onNotebook) {
                Text(L10n.t("carnet.title"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .buttonStyle(CTAButtonStyle(kind: shown == 0 ? .outline : .primary, onPaper: true, height: 44))
            .frame(width: 124)
            .accessibilityLabel(Text(L10n.f("a11y.carnet", filed)))
            .accessibilityIdentifier("phone.carnet")
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .frame(minHeight: PhoneLayout.barHeight)
        .paper(radius: PhoneLayout.barRadius)
        .overlay(shape.strokeBorder(Trace.Colors.stamp, lineWidth: 2).opacity(pulse ? 1 : 0).allowsHitTesting(false))
    }

    /// « Aucune pièce versée » / « 1 pièce versée » / « 3 pièces versées ».
    static func count(_ n: Int) -> String {
        n == 0 ? L10n.t("bar.noPieces") : L10n.f("dossier.piecesCount", n)
    }
}

/// « Mettre l'enquête en pause » (top left, where a phone shows its clock): asks first, in a sheet.
struct QuitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pause.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.Colors.bgBubbleIn.opacity(0.88)))
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Theme.Colors.line2, lineWidth: 1))
                .frame(width: Theme.Size.hit, height: Theme.Size.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("pause.a11y")))
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
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(filled ? Theme.Colors.textOnLight : Color.black.opacity(0.08)))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
#endif
