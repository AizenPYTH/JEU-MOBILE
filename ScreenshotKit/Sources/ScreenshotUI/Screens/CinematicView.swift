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
        case .phoneOnTable: PhoneOnTableShot(shot: shot, caseFile: caseFile)
        case .unlock: UnlockShot(shot: shot, caseFile: caseFile, session: session)
        }
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
        for name in ambience { audio.loop(name, volume: name == "sirens" ? 0.45 : 0.55) }
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

/// The seized phone lying on a table (evidence tag next to it), its lock screen lighting up when
/// the notification arrives, the phone buzzing against the wood.
private struct PhoneOnTableShot: View {
    let shot: IntroShot
    let caseFile: CaseFile

    var body: some View {
        ShotClock { t in
            let arrived = shot.notification.map { t >= $0.at } ?? false
            let buzzing = shot.notification.map { t >= $0.at && t < $0.at + 1.1 } ?? false
            ZStack {
                TableSurface()
                if let label = shot.label {
                    EvidenceTag(text: label)
                        .rotationEffect(.degrees(-8))
                        .offset(x: -110, y: 250)
                }
                PhoneDevice {
                    LockScreen(time: caseFile.phoneStartTime, notification: arrived ? shot.notification : nil, lit: arrived || t > 0.6)
                }
                .frame(width: 300, height: 620)
                .rotation3DEffect(.degrees(52), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                .rotationEffect(.degrees(-9))
                .offset(x: buzzing ? sin(t * 90) * 2 : 0, y: 40)
                .scaleEffect(0.86)
                .shadow(color: .black.opacity(0.6), radius: 30, y: 30)
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
            .animation(.interpolatingSpring(mass: 1, stiffness: 260, damping: 22), value: arrived)
        }
        .accessibilityIdentifier("cinematic.shot.phone")
    }
}

/// Dark wood under a desk lamp.
private struct TableSurface: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A1D14), Color(hex: 0x120C08)], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                var rng = SeededRandom(seed: "table")
                for _ in 0..<40 {
                    let y = rng.next() * size.height
                    var grain = Path()
                    grain.move(to: CGPoint(x: 0, y: y))
                    grain.addCurve(to: CGPoint(x: size.width, y: y + (rng.next() - 0.5) * 40),
                                   control1: CGPoint(x: size.width * 0.3, y: y + (rng.next() - 0.5) * 30),
                                   control2: CGPoint(x: size.width * 0.7, y: y + (rng.next() - 0.5) * 30))
                    context.stroke(grain, with: .color(.black.opacity(0.18)), lineWidth: 1 + rng.next() * 2)
                }
            }
            RadialGradient(colors: [Color(hex: 0xFFD9A0).opacity(0.28), .clear], center: UnitPoint(x: 0.45, y: 0.35), startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
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

/// The seized phone's lock screen: time, date, a notification.
struct LockScreen: View {
    let time: Moment
    let notification: IntroNotification?
    var lit = true

    var body: some View {
        ZStack(alignment: .top) {
            Wallpaper()
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
                if let notification {
                    HStack(alignment: .top, spacing: Theme.Spacing.s3) {
                        AppTileGlyph(app: notification.app, size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(notification.title).font(Theme.Fonts.notificationTitle)
                                Spacer()
                                Text(L10n.t("notif.now")).font(Theme.Fonts.dataSmall).opacity(0.6)
                            }
                            Text(notification.body).font(Theme.Fonts.notificationBody).lineLimit(2)
                        }
                    }
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.s3)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous).fill(Theme.Colors.bgBubbleIn.opacity(0.85)))
                    .padding(.horizontal, Theme.Spacing.s3)
                    .padding(.top, Theme.Spacing.s8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
        }
        .overlay(Color.black.opacity(lit ? 0 : 0.92))
        .animation(.easeOut(duration: 0.5), value: lit)
    }
}

// MARK: - Unlock (picked up, unlocked, the game's phone)

/// The phone rises from the table to the player's hands (the game's exact framing), the lock
/// screen slides away, and the real phone — status bar, home screen, notebook — is there.
private struct UnlockShot: View {
    let shot: IntroShot
    let caseFile: CaseFile
    let session: GameSession

    var body: some View {
        ShotClock { t in
            let rise = min(1, t / 1.1)
            let eased = 1 - pow(1 - rise, 3)
            let unlocked = min(1, max(0, (t - 1.2) / 0.5))
            ZStack {
                TableSurface().opacity(1 - eased)
                DeskBackground().opacity(eased)
                // The game's phone, exactly where it will be.
                PhoneView(session: session, onNotebook: {}, onHints: {}, onTimer: {}, onQuit: {})
                    .allowsHitTesting(false)
                    .opacity(unlocked)
                // The lock screen on the same device frame, sliding away.
                PhoneDevice {
                    LockScreen(time: caseFile.phoneStartTime, notification: nil)
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
#endif
