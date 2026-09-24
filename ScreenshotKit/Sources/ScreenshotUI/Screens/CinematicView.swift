#if os(iOS)
import SwiftUI
import CaseEngine

/// Plays a case's opening sequence (`IntroScene`): shot after shot, with their ambience, sound cues
/// and voiced lines, then hands over to the phone. The last shot ends on the exact frame of the
/// game's phone, so the phone the player holds is the one they just saw picked up.
/// Generic: every shot kind is data (text, place, notification…); nothing is specific to a case.
struct CinematicView: View {
    let scene: IntroScene
    let caseFile: CaseFile
    /// The investigation about to start (its phone is the last frame).
    let session: GameSession
    let onFinish: () -> Void

    @State private var index = 0
    @State private var done = false
    @State private var scheduled: [Task<Void, Never>] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.Colors.ink0.ignoresSafeArea()
            if index < scene.shots.count {
                shotView(scene.shots[index])
                    .id(index)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Hidden on the last shot: the phone is already in the player's hands.
            if scene.shots.indices.contains(index), scene.shots[index].kind != .unlock {
            Button(action: finish) {
                HStack(spacing: 4) {
                    Text(L10n.t("cinematic.skip"))
                    Image(systemName: "chevron.forward.2")
                }
                .font(Theme.Fonts.calloutStrong)
                .foregroundStyle(Theme.Colors.textPrimary.opacity(0.85))
                .padding(.horizontal, Theme.Spacing.s4)
                .frame(height: 36)
                .background(Capsule().fill(Color.black.opacity(0.45)))
                .overlay(Capsule().strokeBorder(Theme.Colors.line2))
            }
            .buttonStyle(.plain)
            .padding(.trailing, Theme.Spacing.s5)
            .padding(.top, Theme.Spacing.s3)
            .accessibilityIdentifier("cinematic.skip")
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task { await run() }
        .onDisappear { cancelScheduled() }
    }

    @ViewBuilder
    private func shotView(_ shot: IntroShot) -> some View {
        switch shot.kind {
        case .title: TitleShot(shot: shot)
        case .broadcast: BroadcastShot(shot: shot, reduceMotion: reduceMotion)
        case .scene: SceneShot(shot: shot, reduceMotion: reduceMotion)
        case .phoneOnTable: PhoneOnTableShot(shot: shot, caseFile: caseFile)
        case .unlock: UnlockShot(shot: shot, caseFile: caseFile, session: session, surface: lastSurface)
        }
    }

    /// The surface of the last phone shot (the unlock starts from there).
    private var lastSurface: IntroShot.Surface {
        scene.shots.last { $0.kind == .phoneOnTable }?.surface ?? .wood
    }

    // MARK: Timeline

    private func run() async {
        for (i, shot) in scene.shots.enumerated() {
            guard !done else { return }
            withAnimation(.easeInOut(duration: 0.45)) { index = i }
            start(shot)
            try? await Task.sleep(for: .seconds(shot.seconds))
        }
        finish()
    }

    /// Ambience of the shot (others fade out), its cues and voiced lines at their offsets.
    private func start(_ shot: IntroShot) {
        let audio = AudioDirector.shared
        let ambience = Set(shot.ambience ?? [])
        audio.stopAmbience(keeping: ambience)
        for name in ambience { audio.loop(name, volume: AudioDirector.ambienceVolume(name)) }
        for cue in shot.cues ?? [] {
            schedule(after: cue.at) {
                audio.play(cue.sound)
                if cue.sound == "vibrate" { Haptics.urgent() }
            }
        }
        for line in shot.lines ?? [] where line.voiced == true {
            schedule(after: line.at) { audio.speak(line.text) }
        }
    }

    private func schedule(after seconds: Double, _ action: @escaping @MainActor () -> Void) {
        let task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            action()
        }
        scheduled.append(task)
    }

    private func cancelScheduled() {
        scheduled.forEach { $0.cancel() }
        scheduled.removeAll()
    }

    private func finish() {
        guard !done else { return }
        done = true
        cancelScheduled()
        AudioDirector.shared.stopAll()
        onFinish()
    }
}

/// Seconds since the view appeared, redrawn every frame (drives the shots' own motion).
private struct ShotClock<Content: View>: View {
    @State private var start = Date()
    let content: (Double) -> Content

    init(@ViewBuilder content: @escaping (Double) -> Content) {
        self.content = content
    }

    var body: some View {
        TimelineView(.animation) { context in
            content(max(0, context.date.timeIntervalSince(start)))
        }
    }
}

// MARK: - Title (black screen, text)

private struct TitleShot: View {
    let shot: IntroShot

    var body: some View {
        ShotClock { t in
            VStack(spacing: Theme.Spacing.s4) {
                ForEach(Array((shot.lines ?? []).enumerated()), id: \.offset) { offset, line in
                    Text(line.text)
                        .font(offset == 0 ? Theme.Fonts.overline : Theme.Fonts.narrative)
                        .tracking(offset == 0 ? Theme.Tracking.overline : 0)
                        .foregroundStyle(offset == 0 ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(t >= line.at ? 1 : 0)
                        .animation(.easeOut(duration: 0.8), value: t >= line.at)
                }
            }
            .padding(Theme.Spacing.marginGame)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityIdentifier("cinematic.shot.title")
    }
}

// MARK: - Broadcast (a live report in front of the place)

private struct BroadcastShot: View {
    let shot: IntroShot
    let reduceMotion: Bool

    var body: some View {
        ShotClock { t in
            let shake = reduceMotion ? CGSize.zero : CGSize(width: sin(t * 1.3) * 4 + sin(t * 3.1) * 1.5, height: cos(t * 0.9) * 3)
            let current = (shot.lines ?? []).last { $0.at <= t }
            ZStack {
                GeneratedPhoto(scene: shot.scene ?? "parking_night", seed: "intro.broadcast", style: .night)
                    .scaleEffect(1.18 + t * 0.004)
                    .offset(shake)
                    .rotationEffect(.degrees(reduceMotion ? 0 : sin(t * 0.7) * 0.6))
                    .ignoresSafeArea()
                // Police lights bouncing off the walls.
                let pulse = (sin(t * 7) + 1) / 2
                RadialGradient(colors: [Theme.Colors.alert.opacity(0.35 * pulse), .clear], center: UnitPoint(x: 0.2, y: 0.35), startRadius: 0, endRadius: 320)
                    .blendMode(.screen).ignoresSafeArea()
                RadialGradient(colors: [Theme.Colors.info.opacity(0.35 * (1 - pulse)), .clear], center: UnitPoint(x: 0.85, y: 0.3), startRadius: 0, endRadius: 320)
                    .blendMode(.screen).ignoresSafeArea()
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: Theme.Spacing.s3) {
                        Text(shot.channel ?? "INFO")
                            .font(.custom(Theme.FontName.monoBold, fixedSize: 13))
                            .foregroundStyle(Theme.Colors.textOnLight)
                            .padding(.horizontal, 8).frame(height: 24)
                            .background(Theme.Colors.textPrimary)
                        HStack(spacing: 5) {
                            Circle().fill(Theme.Colors.textPrimary).frame(width: 7, height: 7)
                                .opacity(Int(t * 2) % 2 == 0 ? 1 : 0.3)
                            Text(L10n.t("cinematic.live")).font(.custom(Theme.FontName.monoBold, fixedSize: 12))
                        }
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.horizontal, 8).frame(height: 24)
                        .background(Theme.Colors.alert)
                        if let label = shot.label {
                            Text(label).font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.leading, Theme.Spacing.s5)
                    Spacer()
                    if let current {
                        Text(current.text)
                            .font(Theme.Fonts.bodyLarge)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .shadow(color: .black, radius: 3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Theme.Spacing.marginGame)
                            .padding(.bottom, Theme.Spacing.s5)
                            .id(current.at)
                            .transition(.opacity)
                            .accessibilityIdentifier("cinematic.subtitle")
                    }
                    // Lower third.
                    VStack(alignment: .leading, spacing: 2) {
                        if let location = shot.location {
                            Text(location.uppercased()).font(.custom(Theme.FontName.monoSemibold, fixedSize: 11)).tracking(1.2)
                                .foregroundStyle(Theme.Colors.alertText)
                        }
                        if let headline = shot.headline {
                            Text(headline).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textOnLight)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.s4).padding(.vertical, Theme.Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.textPrimary.opacity(0.95))
                    if let ticker = shot.ticker {
                        GeometryReader { geo in
                            let width = CGFloat(ticker.count) * 7.5 + geo.size.width
                            Text(ticker + "     •     " + ticker)
                                .font(.custom(Theme.FontName.mono, fixedSize: 12))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .fixedSize()
                                .offset(x: geo.size.width - CGFloat(t * 60).truncatingRemainder(dividingBy: width))
                        }
                        .frame(height: 26)
                        .background(Theme.Colors.alert.opacity(0.9))
                        .clipped()
                    }
                }
                .padding(.bottom, 30)
            }
            .animation(.easeInOut(duration: 0.3), value: current?.at)
        }
        .accessibilityIdentifier("cinematic.shot.broadcast")
    }
}

// MARK: - The phone on a table

/// The phone lying where it was found (a table, a metro bench, a car seat…), its lock screen
/// lighting up as notifications arrive, the phone buzzing against the surface.
private struct PhoneOnTableShot: View {
    let shot: IntroShot
    let caseFile: CaseFile

    var body: some View {
        ShotClock { t in
            let notifications = shot.allNotifications
            let arrived = notifications.filter { t >= $0.at }
            let buzzing = notifications.contains { t >= $0.at && t < $0.at + ($0.call == true ? 2.2 : 1.1) }
            ZStack {
                SurfaceView(surface: shot.surface ?? .wood)
                PhoneDevice {
                    LockScreen(time: caseFile.phoneStartTime, notifications: arrived, lit: !arrived.isEmpty || t > 0.6,
                               wallpaper: caseFile.devices.first?.wallpaper ?? .night)
                }
                .frame(width: 300, height: 620)
                .rotation3DEffect(.degrees(52), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                .rotationEffect(.degrees(-9))
                .offset(x: buzzing ? sin(t * 90) * 2 : 0, y: 40)
                .scaleEffect(0.86)
                .shadow(color: .black.opacity(0.6), radius: 30, y: 30)
                // The tag lies on the surface in front of the phone.
                if let label = shot.label {
                    EvidenceTag(text: label)
                        .rotationEffect(.degrees(-6))
                        .offset(x: -70, y: 330)
                }
                if let caption = shot.lines?.last(where: { $0.at <= t }) {
                    VStack {
                        Spacer()
                        Text(caption.text)
                            .font(Theme.Fonts.narrativeSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .shadow(color: .black, radius: 4)
                            .padding(.bottom, 70)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.interpolatingSpring(mass: 1, stiffness: 260, damping: 22), value: arrived.count)
        }
        .accessibilityIdentifier("cinematic.shot.phone")
    }
}

/// What the phone lies on. Colours here are set dressing, like the generated photos.
struct SurfaceView: View {
    let surface: IntroShot.Surface

    var body: some View {
        ZStack {
            switch surface {
            case .wood: woodTable
            case .bench: metroBench
            case .glass: glassTable
            case .carSeat: carSeat
            case .sofa: sofa
            case .marble: marble
            }
        }
        .ignoresSafeArea()
    }

    /// Dark wood under a desk lamp.
    private var woodTable: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A1D14), Color(hex: 0x120C08)], startPoint: .top, endPoint: .bottom)
            grain(seed: "table", color: .black.opacity(0.18), count: 40, curvy: true)
            RadialGradient(colors: [Color(hex: 0xFFD9A0).opacity(0.28), .clear], center: UnitPoint(x: 0.45, y: 0.35), startRadius: 0, endRadius: 420)
        }
    }

    /// Perforated steel slats of a metro bench under cold fluorescent light.
    private var metroBench: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2B3844), Color(hex: 0x0E1318)], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 3)), with: .color(.black.opacity(0.35)))
                    var x: CGFloat = 6
                    while x < size.width {
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y + 14, width: 4, height: 4)), with: .color(.black.opacity(0.4)))
                        x += 12
                    }
                    y += 34
                }
            }
            RadialGradient(colors: [Color(hex: 0xD8FFF0).opacity(0.22), .clear], center: UnitPoint(x: 0.5, y: 0.1), startRadius: 0, endRadius: 460)
        }
    }

    /// A glass bedside or coffee table in morning light, rings left by glasses.
    private var glassTable: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x6E6254), Color(hex: 0x2E2822)], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                var rng = SeededRandom(seed: "glass")
                for _ in 0..<6 {
                    let r = 26 + rng.next() * 18
                    let x = rng.next() * size.width, y = rng.next() * size.height
                    context.stroke(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 1.6)), with: .color(.white.opacity(0.12)), lineWidth: 2)
                }
            }
            LinearGradient(colors: [Color(hex: 0xFFF1D2).opacity(0.3), .clear], startPoint: .topTrailing, endPoint: .center)
        }
    }

    /// The passenger seat of a car at night, rain light moving on the fabric.
    private var carSeat: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1A1C1F), Color(hex: 0x08090A)], startPoint: .top, endPoint: .bottom)
            grain(seed: "seat", color: .white.opacity(0.03), count: 60, curvy: false)
            // Seat stitching.
            VStack(spacing: 120) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Color.black.opacity(0.5)).frame(height: 2)
                }
            }
            RadialGradient(colors: [Color(hex: 0xFF9A1F).opacity(0.18), .clear], center: UnitPoint(x: 0.9, y: 0.2), startRadius: 0, endRadius: 360)
            RadialGradient(colors: [Color(hex: 0x6FA8E0).opacity(0.12), .clear], center: UnitPoint(x: 0.1, y: 0.8), startRadius: 0, endRadius: 360)
        }
    }

    private var sofa: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x4A4640), Color(hex: 0x1F1D1A)], startPoint: .top, endPoint: .bottom)
            grain(seed: "sofa", color: .black.opacity(0.12), count: 80, curvy: false)
        }
    }

    /// White marble with grey veins, warm party light.
    private var marble: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xD9D4CB), Color(hex: 0x8C867C)], startPoint: .top, endPoint: .bottom)
            grain(seed: "marble", color: Color(hex: 0x6E685E).opacity(0.35), count: 14, curvy: true)
            RadialGradient(colors: [Color(hex: 0xFFD48A).opacity(0.3), .clear], center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: 480)
            LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
        }
    }

    private func grain(seed: String, color: Color, count: Int, curvy: Bool) -> some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: seed)
            for _ in 0..<count {
                let y = rng.next() * size.height
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                if curvy {
                    line.addCurve(to: CGPoint(x: size.width, y: y + (rng.next() - 0.5) * 40),
                                  control1: CGPoint(x: size.width * 0.3, y: y + (rng.next() - 0.5) * 30),
                                  control2: CGPoint(x: size.width * 0.7, y: y + (rng.next() - 0.5) * 30))
                } else {
                    line.addLine(to: CGPoint(x: size.width, y: y + (rng.next() - 0.5) * 4))
                }
                context.stroke(line, with: .color(color), lineWidth: 1 + rng.next() * 2)
            }
        }
    }
}

/// A police evidence tag.
private struct EvidenceTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom(Theme.FontName.monoSemibold, fixedSize: 11))
            .foregroundStyle(Color(hex: 0x2A2118))
            .multilineTextAlignment(.leading)
            .padding(10)
            .background(Color(hex: 0xE9DDC0))
            .overlay(alignment: .topLeading) {
                Circle().strokeBorder(Color(hex: 0x8C7A5A), lineWidth: 1.5).frame(width: 9, height: 9).padding(4)
            }
            .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
    }
}

/// The seized phone's lock screen: time, date, notifications (the latest on top) or a ringing call.
struct LockScreen: View {
    let time: Moment
    var notifications: [IntroNotification] = []
    var lit = true
    var wallpaper: Device.Wallpaper = .night

    var body: some View {
        let ringing = notifications.last.flatMap { $0.call == true ? $0 : nil }
        ZStack(alignment: .top) {
            Wallpaper(style: wallpaper)
            VStack(spacing: Theme.Spacing.s2) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.top, 56)
                Text(PhoneFormat.longDayCapitalized(time))
                    .font(.custom(Theme.FontName.medium, fixedSize: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.s3)
                Text(PhoneFormat.time(time))
                    .font(Theme.Fonts.homeClock)
                    .foregroundStyle(Theme.Colors.textPrimary)
                VStack(spacing: Theme.Spacing.s2) {
                    ForEach(Array(notifications.filter { $0.call != true }.reversed().prefix(3).enumerated()), id: \.offset) { _, notification in
                        NotificationCard(notification: notification)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.top, Theme.Spacing.s8)
                Spacer()
                if let ringing {
                    IncomingCall(caller: ringing.title)
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .overlay(Color.black.opacity(lit ? 0 : 0.92))
        .animation(.easeOut(duration: 0.5), value: lit)
    }
}

/// A banner on the lock screen.
private struct NotificationCard: View {
    let notification: IntroNotification

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            AppTileGlyph(app: notification.app, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(notification.title).font(Theme.Fonts.notificationTitle).lineLimit(1)
                    Spacer()
                    Text(L10n.t("notif.now")).font(Theme.Fonts.dataSmall).opacity(0.6)
                }
                Text(notification.body).font(Theme.Fonts.notificationBody).lineLimit(2)
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(Theme.Spacing.s3)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous).fill(Theme.Colors.bgBubbleIn.opacity(0.85)))
    }
}

/// A call ringing on the locked phone: the caller, and the two round buttons nobody presses.
private struct IncomingCall: View {
    let caller: String

    var body: some View {
        VStack(spacing: Theme.Spacing.s5) {
            VStack(spacing: Theme.Spacing.s1) {
                Text(caller).font(Theme.Fonts.title2).foregroundStyle(Theme.Colors.textPrimary)
                Text(L10n.t("cinematic.incomingCall")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            }
            HStack(spacing: 90) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Theme.Colors.alert))
                Image(systemName: "phone.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Theme.Colors.clear))
            }
            .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

// MARK: - Unlock (picked up, unlocked, the game's phone)

/// The phone rises from where it lay to the player's hands (the game's exact framing), the lock
/// screen slides away, and the real phone — status bar, home screen, notebook — is there.
private struct UnlockShot: View {
    let shot: IntroShot
    let caseFile: CaseFile
    let session: GameSession
    /// What the phone lay on in the previous shot.
    let surface: IntroShot.Surface

    var body: some View {
        ShotClock { t in
            let rise = min(1, t / 1.1)
            let eased = 1 - pow(1 - rise, 3)
            let unlocked = min(1, max(0, (t - 1.2) / 0.5))
            ZStack {
                SurfaceView(surface: surface).opacity(1 - eased)
                DeskBackground().opacity(eased)
                // The game's phone, exactly where it will be.
                PhoneView(session: session, onNotebook: {}, onHints: {}, onTimer: {}, onQuit: {})
                    .allowsHitTesting(false)
                    .opacity(unlocked)
                // The lock screen on the same device frame, sliding away.
                PhoneDevice {
                    LockScreen(time: caseFile.phoneStartTime, wallpaper: caseFile.devices.first?.wallpaper ?? .night)
                        .offset(y: -unlocked * 700)
                }
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.top, Theme.Spacing.s1)
                .padding(.bottom, Theme.Spacing.s2)
                .opacity(1 - unlocked)
                .rotation3DEffect(.degrees(52 * (1 - eased)), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                .rotationEffect(.degrees(-9 * (1 - eased)))
                .scaleEffect(0.62 + 0.38 * eased)
                .offset(y: 60 * (1 - eased))
            }
            .onChange(of: unlocked >= 0.01) { _, started in
                if started { AudioDirector.shared.play(.unlock); Haptics.selection() }
            }
        }
        .accessibilityIdentifier("cinematic.shot.unlock")
    }
}

// MARK: - A place, filmed

/// A place: the picture of `scene`, a slow camera move, an effect (a train pulling in, the lights
/// going out, rain, hazard lights, the morning sun), and its lines — the first one as a location
/// title, announcements (with a speaker) as subtitles, the others as the narrator's voice.
private struct SceneShot: View {
    let shot: IntroShot
    let reduceMotion: Bool

    var body: some View {
        ShotClock { t in
            let lines = shot.lines ?? []
            let title = lines.first.flatMap { $0.speaker == nil ? $0 : nil }
            let spoken = lines.filter { $0.speaker != nil }.last { $0.at <= t }
            let narration = lines.dropFirst(title == nil ? 0 : 1).filter { $0.speaker == nil }.last { $0.at <= t }
            let motion = reduceMotion ? 0 : t
            ZStack {
                GeneratedPhoto(scene: shot.scene ?? "street_night", seed: "intro.\(shot.scene ?? "")",
                               style: PhotoPainter.defaultStyle(for: shot.scene ?? ""))
                    .scaleEffect(scale(motion))
                    .offset(offset(motion))
                    .offset(shake(t))
                    .ignoresSafeArea()
                effectLayer(t)
                // Letterbox and vignette: this is film, not the phone.
                LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    if let title, t >= title.at {
                        Text(title.text)
                            .font(Theme.Fonts.overline)
                            .tracking(Theme.Tracking.overline)
                            .foregroundStyle(Theme.Colors.textPrimary.opacity(0.9))
                            .padding(.top, 70)
                            .padding(.horizontal, Theme.Spacing.marginGame)
                            .transition(.opacity)
                    }
                    Spacer()
                    if let spoken {
                        Text(spoken.text)
                            .font(Theme.Fonts.bodyLarge)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .shadow(color: .black, radius: 3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Theme.Spacing.marginGame)
                            .padding(.bottom, Theme.Spacing.s3)
                            .id(spoken.at)
                            .transition(.opacity)
                    }
                    if let narration {
                        Text(narration.text)
                            .font(Theme.Fonts.narrative)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .shadow(color: .black, radius: 4)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Theme.Spacing.marginGame)
                            .id(narration.at)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 90)
            }
            .animation(.easeInOut(duration: 0.6), value: (spoken?.at ?? -1) + (narration?.at ?? -1) + (title.map { t >= $0.at ? 1.0 : 0.0 } ?? 0))
        }
        .accessibilityIdentifier("cinematic.shot.scene")
    }

    private func scale(_ t: Double) -> Double {
        switch shot.camera ?? .still {
        case .push: 1.08 + t * 0.018
        case .pull: 1.3 - t * 0.02
        case .panLeft, .panRight: 1.18
        case .drift: 1.12 + sin(t * 0.4) * 0.02
        case .still: 1.06
        }
    }

    private func offset(_ t: Double) -> CGSize {
        switch shot.camera ?? .still {
        case .panLeft: CGSize(width: CGFloat(30 - t * 9), height: 0)
        case .panRight: CGSize(width: CGFloat(-30 + t * 9), height: 0)
        case .drift: CGSize(width: CGFloat(sin(t * 0.5) * 8), height: CGFloat(cos(t * 0.35) * 5))
        default: .zero
        }
    }

    /// A handheld wobble, and the ground shaking as a train pulls in.
    private func shake(_ t: Double) -> CGSize {
        guard !reduceMotion else { return .zero }
        var s = CGSize(width: CGFloat(sin(t * 1.3) * 1.5), height: CGFloat(cos(t * 1.1) * 1.2))
        if shot.effect == .trainArrival, t > 1.2, t < 3.6 {
            s.width += CGFloat(sin(t * 55) * 2.5)
            s.height += CGFloat(cos(t * 47) * 2)
        }
        return s
    }

    @ViewBuilder
    private func effectLayer(_ t: Double) -> some View {
        if let effect = shot.effect {
            effectView(effect, t)
        }
    }

    @ViewBuilder
    private func effectView(_ effect: IntroShot.Effect, _ t: Double) -> some View {
        switch effect {
        case .trainArrival:
            // Headlights grow out of the tunnel, then the lit carriages sweep past.
            let approach = min(1, max(0, (t - 0.2) / 1.2))
            ZStack {
                RadialGradient(colors: [Color.white.opacity(0.85 * approach), .clear], center: UnitPoint(x: 0.12, y: 0.5),
                               startRadius: 0, endRadius: CGFloat(80 + 260 * approach))
                    .blendMode(.screen)
                if t > 1.3 {
                    TrainCarriages(progress: min(1, (t - 1.3) / 2.2))
                }
            }
            .ignoresSafeArea()
        case .blackout:
            // Lights flicker and die; after a moment, the red emergency lights.
            let flicker = t > 0.3 && t < 0.7 ? (Int(t * 20) % 2 == 0 ? 0.9 : 0.2) : 0
            let dark = t >= 0.7 ? 1.0 : flicker
            ZStack {
                Color.black.opacity(dark * (t > 2.2 ? 0.86 : 1))
                if t > 2.2 {
                    RadialGradient(colors: [Theme.Colors.alert.opacity(0.35), .clear], center: UnitPoint(x: 0.15, y: 0.2), startRadius: 0, endRadius: 300)
                    RadialGradient(colors: [Theme.Colors.clear.opacity(0.25), .clear], center: UnitPoint(x: 0.85, y: 0.3), startRadius: 0, endRadius: 120)
                }
            }
            .ignoresSafeArea()
        case .rain:
            RainLayer(t: t).ignoresSafeArea()
        case .hazard:
            let on = Int(t * 2) % 2 == 0
            RadialGradient(colors: [Color(hex: 0xFF9A1F).opacity(on ? 0.35 : 0.05), .clear], center: UnitPoint(x: 0.7, y: 0.66),
                           startRadius: 0, endRadius: 300)
                .blendMode(.screen)
                .ignoresSafeArea()
        case .sunlight:
            LinearGradient(colors: [Color(hex: 0xFFE7B8).opacity(0.35), .clear], startPoint: UnitPoint(x: 0.1 + t * 0.03, y: 0),
                           endPoint: UnitPoint(x: 0.7 + t * 0.03, y: 1))
                .blendMode(.screen)
                .ignoresSafeArea()
        }
    }
}

/// Lit carriages sweeping across the frame.
private struct TrainCarriages: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let length = w * 3
            HStack(spacing: 6) {
                ForEach(0..<9, id: \.self) { _ in
                    ZStack {
                        Rectangle().fill(Color(hex: 0x1C2226))
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xEFF7EF).opacity(0.85))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, h * 0.06)
                    }
                    .frame(width: length / 9 - 6)
                }
            }
            .frame(width: length, height: h * 0.34)
            .position(x: w + length / 2 - (w + length) * progress, y: h * 0.52)
            .blur(radius: 1.5)
        }
    }
}

/// Rain running down a windscreen.
private struct RainLayer: View {
    let t: Double

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: "rain")
            for _ in 0..<140 {
                let x = rng.next() * size.width
                let speed = 80 + rng.next() * 220
                let y = (rng.next() * size.height + CGFloat(t) * speed).truncatingRemainder(dividingBy: size.height + 40) - 20 as CGFloat
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y))
                drop.addLine(to: CGPoint(x: x - 2, y: y + 10 + rng.next() * 14))
                context.stroke(drop, with: .color(.white.opacity(0.18 + rng.next() * 0.2)), lineWidth: 1)
            }
            for _ in 0..<40 {
                let r = 1.5 + rng.next() * 3
                let x = rng.next() * size.width, y = rng.next() * size.height
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2.4)), with: .color(.white.opacity(0.14)))
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
