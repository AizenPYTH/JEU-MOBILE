#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Ouverture de dossier (briefing → téléphone)

/// From the case file to the phone (final handoff §F-04 « Transition », §J « Ouverture de
/// dossier », 1.8 s at most): the sealed evidence bag slides onto the desk and the phone comes out
/// of it, then the view closes in on its screen, framed like the phone of the investigation. #001
/// (the tutorial) unlocks by itself; #002–#005 keep their lock screen until the player taps or
/// swipes up. Not a cinematic: no story shot, no text beat. The clock is not running here — the
/// caller starts it in `onDone`. A tap during the slide skips ahead: nothing here holds the player.
struct CaseOpeningView: View {
    let session: GameSession
    let onDone: () -> Void

    private enum Stage: Int, Comparable {
        /// Below the desk, out of sight.
        case arriving
        /// The bag lies on the desk, the phone inside.
        case onDesk
        /// The bag is pulled away: the phone alone.
        case unbagged
        /// Close-up: the phone as the player will hold it, locked.
        case phone
        /// The lock screen goes away.
        case unlocking

        static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var stage: Stage = .arriving
    /// The desk (paper world) behind the bag; it gives way to the phone's dark background.
    @State private var deskVisible = true
    /// Reduced motion: the phone fades out and back in instead of moving.
    @State private var shown = false
    @State private var finished = false
    /// Swipe up on the lock screen (#002–#005).
    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    /// #001 is the tutorial: its lock screen is skipped.
    private var autoUnlock: Bool { session.caseFile.number == 1 }
    private var device: Device { session.game.device }
    private var time: Moment { session.phoneTime }
    private var waitingForPlayer: Bool { stage == .phone && !autoUnlock }
    private var groupOpacity: Double { noMotion ? (shown ? 1 : 0) : 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DeskBackground()
                DeskBackdrop()
                    .opacity(deskVisible ? 1 : 0)
                phoneGroup(height: geo.size.height)
                sealTag
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.28 + tagDrop(geo.size.height))
                    .opacity(stage <= .onDesk ? groupOpacity : 0)
                if waitingForPlayer {
                    unlockArea
                        .transition(.opacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { skipAhead() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("opening.view")
        .task { await run() }
    }

    // MARK: The phone in its bag

    /// The phone (full size, framed like the investigation's) and its bag, scaled down while it
    /// lies on the desk.
    private func phoneGroup(height: CGFloat) -> some View {
        let bagged = stage < .phone
        let tilt: Double = stage == .arriving ? Metrics.arrivingTilt : (bagged ? Metrics.deskTilt : 0)
        return ZStack {
            PhoneDevice { lockScreen(height: height) }
            evidenceBag
                .offset(y: stage >= .unbagged && !noMotion ? height : 0)
                .opacity(stage <= .onDesk ? 1 : 0)
        }
        .padding(.horizontal, Theme.Spacing.s3)
        .padding(.top, Theme.Spacing.s1)
        .padding(.bottom, Theme.Spacing.s2)
        .scaleEffect(bagged ? Metrics.baggedScale : 1)
        .rotationEffect(.degrees(noMotion ? 0 : tilt))
        .offset(y: stage == .arriving && !noMotion ? height : 0)
        .opacity(groupOpacity)
        .accessibilityHidden(true)
    }

    /// A clear plastic bag with its red tamper strip.
    private var evidenceBag: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.bagRadius, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [Trace.Colors.label.opacity(0.18), Trace.Colors.label.opacity(0.05),
                                          Trace.Colors.label.opacity(0.14)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(shape.strokeBorder(Trace.Colors.label.opacity(0.35), lineWidth: Metrics.bagStroke))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Trace.Colors.stamp.opacity(0.9))
                    .frame(height: Metrics.sealStrip)
                    .padding(.top, Metrics.sealStripTop)
            }
            .padding(-Metrics.bagMargin)
            .allowsHitTesting(false)
    }

    /// The paper tag tied to the bag: « SCELLÉ N° 00N-01 » and the phone's label (case data).
    private var sealTag: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L10n.f("opening.seal", shownNumber(session.caseFile.number) + "-01"))
                .font(Trace.Fonts.kicker)
                .tracking(1.4)
                .foregroundStyle(Trace.Colors.stamp)
            Text(device.label)
                .font(Trace.Fonts.fieldValue)
                .foregroundStyle(Trace.Colors.kraftInk)
        }
        .padding(.vertical, 8)
        .padding(.leading, 24)
        .padding(.trailing, 12)
        .background(Trace.Colors.paperAged)
        .overlay(alignment: .leading) {
            Circle()
                .strokeBorder(Trace.Colors.kraftLabel, lineWidth: 1.5)
                .frame(width: 9, height: 9)
                .padding(.leading, 8)
        }
        .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
        .fixedSize()
        .rotationEffect(.degrees(-6))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The tag travels with the bag: in from below, then away with it.
    private func tagDrop(_ height: CGFloat) -> CGFloat {
        guard !noMotion else { return 0 }
        switch stage {
        case .arriving: return height
        case .onDesk: return 0
        default: return height * Metrics.baggedScale
        }
    }

    // MARK: The lock screen (inside the phone: Theme tokens)

    private func lockScreen(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Wallpaper(style: device.wallpaper ?? .night)
            lockContent
                .offset(y: noMotion ? 0 : (stage == .unlocking ? -height : drag))
                .opacity(stage == .unlocking ? 0 : 1)
        }
    }

    private var lockContent: some View {
        VStack(spacing: Theme.Spacing.s2) {
            statusIcons
            Image(systemName: "lock.fill")
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.top, Theme.Spacing.s3)
            Text(PhoneFormat.longDayCapitalized(time))
                .font(Theme.Fonts.calloutStrong)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.top, Theme.Spacing.s3)
            Text(PhoneFormat.time(time))
                .font(Theme.Fonts.homeClock)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer(minLength: 0)
            if !autoUnlock {
                VStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: "chevron.up").font(Theme.Fonts.calloutStrong)
                    Text(L10n.t("opening.swipe")).font(Theme.Fonts.callout)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.bottom, Theme.Spacing.s5)
                .opacity(waitingForPlayer ? 1 : 0)
            }
            Capsule()
                .fill(Theme.Colors.textPrimary)
                .frame(width: Metrics.homeIndicator.width, height: Metrics.homeIndicator.height)
                .padding(.bottom, Theme.Spacing.s3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Network and battery, where the phone's status bar has them.
    private var statusIcons: some View {
        let level = session.batteryLevel
        return HStack(spacing: 5) {
            Spacer()
            Image(systemName: "cellularbars")
            Image(systemName: "wifi")
            Text(verbatim: "\(level)").monospacedDigit()
            Image(systemName: level <= 10 ? "battery.0" : level <= 35 ? "battery.25" : "battery.50")
                .foregroundStyle(level <= 10 ? Theme.Colors.alertText : Theme.Colors.textPrimary)
        }
        .font(Theme.Fonts.calloutStrong)
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.trailing, Metrics.statusTrailing)
        .padding(.top, Theme.Spacing.s3)
        .frame(height: Theme.Size.statusBar)
    }

    /// #002–#005: the whole screen unlocks the phone (tap, or swipe up). VoiceOver: « Déverrouiller ».
    private var unlockArea: some View {
        Button {
            startUnlock()
        } label: {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    guard !noMotion, stage == .phone else { return }
                    drag = min(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height < -Metrics.swipeDistance
                        || value.predictedEndTranslation.height < -2 * Metrics.swipeDistance {
                        startUnlock()
                    } else {
                        withAnimation(Trace.Motion.paper) { drag = 0 }
                    }
                }
        )
        .accessibilityLabel(Text(L10n.t("opening.unlock")))
        .accessibilityValue(Text(PhoneFormat.time(time) + ", " + PhoneFormat.longDayCapitalized(time)))
        .accessibilityIdentifier("opening.unlock")
    }

    // MARK: Sequence

    /// Bag on the desk (0.55 s) → bag pulled away (0.3 s) → close-up (0.35 s) → unlock (#001, 0.6 s).
    /// Reduced motion: fades only, same order, shorter.
    private func run() async {
        guard stage == .arriving, !finished else { return }
        AudioDirector.shared.play(.paper, volume: 0.6)
        if noMotion {
            advance(to: .onDesk)
            withAnimation(.easeOut(duration: 0.2)) { shown = true }
            guard await hold(0.6) else { return }
            if stage < .phone {
                withAnimation(.easeIn(duration: 0.15)) { shown = false }
                guard await hold(0.15) else { return }
                advance(to: .phone)
                withAnimation(.easeOut(duration: 0.2)) {
                    shown = true
                    deskVisible = false
                }
                guard await hold(0.2) else { return }
            }
        } else {
            withAnimation(.easeOut(duration: 0.5)) { advance(to: .onDesk) }
            guard await hold(0.55) else { return }
            Haptics.paper()
            AudioDirector.shared.play(.paper, volume: 0.35)
            withAnimation(.easeIn(duration: 0.3)) { advance(to: .unbagged) }
            guard await hold(0.3) else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                advance(to: .phone)
                deskVisible = false
            }
            guard await hold(0.35) else { return }
        }
        if autoUnlock {
            await unlock()
            // Never hold the player on this screen.
            if !finished && stage != .unlocking { finish() }
        }
    }

    /// Sleeps; false if the view went away meanwhile.
    private func hold(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
    }

    private func advance(to next: Stage) {
        if stage < next { stage = next }
    }

    /// A tap before the close-up jumps to it (and unlocks #001); on the lock screen, it unlocks.
    private func skipAhead() {
        guard !finished else { return }
        if stage < .phone {
            if noMotion {
                advance(to: .phone)
                withAnimation(.easeOut(duration: 0.2)) {
                    shown = true
                    deskVisible = false
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    advance(to: .phone)
                    deskVisible = false
                }
            }
            if autoUnlock { startUnlock() }
        } else if stage == .phone {
            startUnlock()
        }
    }

    private func startUnlock() {
        Task { await unlock() }
    }

    /// The lock screen goes (0.6 s for #001, 0.3 s after the player's gesture), then the phone.
    private func unlock() async {
        guard stage == .phone, !finished else { return }
        AudioDirector.shared.play(.unlock, volume: 0.7)
        Haptics.light()
        let duration = noMotion ? 0.2 : (autoUnlock ? 0.6 : 0.3)
        withAnimation(noMotion ? Animation.easeOut(duration: duration) : Animation.easeIn(duration: duration)) {
            stage = .unlocking
            drag = 0
        }
        try? await Task.sleep(for: .seconds(duration))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onDone()
    }

    // MARK: Metrics

    private enum Metrics {
        /// Scale of the phone while it lies in its bag on the desk.
        static let baggedScale: CGFloat = 0.52
        static let arrivingTilt: Double = -7
        static let deskTilt: Double = -3
        /// Bag sizes are drawn at the phone's full size, then scaled with it.
        static let bagMargin: CGFloat = 44
        static let bagRadius: CGFloat = 70
        static let bagStroke: CGFloat = 3
        static let sealStrip: CGFloat = 34
        static let sealStripTop: CGFloat = 70
        static let homeIndicator = CGSize(width: 134, height: 5)
        static let statusTrailing: CGFloat = 30
        static let swipeDistance: CGFloat = 60
    }
}
#endif
