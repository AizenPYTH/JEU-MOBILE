#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Ouverture du téléphone (Dossier → téléphone)

/// From the case file to the phone (handoff UX V3 §2 « on entre dans un appareil lumineux »), in
/// one second at most: the dark BEN gives way to the light phone (fade + scale 0.96 → 1, 350 ms;
/// reduced motion: a 200 ms fade). No evidence bag, no texture, no story shot. #001 opens straight
/// on the home screen; #002–#005 show their lock screen (the owner's wallpaper, the fictional time)
/// until the player swipes up or taps. The clock is not running here — the caller starts it in
/// `onDone`. A tap skips ahead: nothing here holds the player.
struct CaseOpeningView: View {
    let session: GameSession
    let onDone: () -> Void

    private enum Stage: Int, Comparable {
        /// The BEN, dark.
        case dark
        /// The phone is in hand (locked for #002–#005).
        case phone
        /// The lock screen goes away.
        case unlocking

        static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var stage: Stage = .dark
    @State private var finished = false
    /// Swipe up on the lock screen (#002–#005).
    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    /// #001 is the first case: no lock screen.
    private var autoUnlock: Bool { session.caseFile.number == 1 }
    private var device: Device { session.game.device }
    private var time: Moment { session.phoneTime }
    private var waitingForPlayer: Bool { stage == .phone && !autoUnlock }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Trace.Colors.bg.ignoresSafeArea()
                lockScreen(height: geo.size.height)
                    .opacity(stage >= .phone ? 1 : 0)
                    .scaleEffect(stage >= .phone || noMotion ? 1 : openingScale)
                    .accessibilityHidden(true)
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

    // MARK: The lock screen (inside the phone: Theme tokens, light)

    private func lockScreen(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Wallpaper(style: device.wallpaper ?? .night)
            lockContent
                .offset(y: noMotion ? 0 : (stage == .unlocking ? -height : drag))
                .opacity(stage == .unlocking ? 0 : 1)
        }
        .environment(\.colorScheme, .light)
    }

    private var lockContent: some View {
        VStack(spacing: Theme.Spacing.s2) {
            statusIcons
            if !autoUnlock {
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
            }
            Spacer(minLength: 0)
            if !autoUnlock {
                VStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: "chevron.up").font(Theme.Fonts.calloutStrong)
                    Text(L10n.t("opening.swipe")).font(Theme.Fonts.callout)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.bottom, Theme.Spacing.s5)
                .opacity(waitingForPlayer ? 1 : 0)
                Capsule()
                    .fill(Theme.Colors.textPrimary)
                    .frame(width: Theme.Size.homeIndicator.width, height: Theme.Size.homeIndicator.height)
                    .padding(.bottom, Theme.Spacing.s3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The phone's own time, network and battery, where its status bar has them.
    private var statusIcons: some View {
        let level = session.batteryLevel
        return HStack(spacing: 5) {
            Text(PhoneFormat.time(time)).monospacedDigit()
            Spacer()
            Image(systemName: "cellularbars")
            Image(systemName: "wifi")
            Text(verbatim: "\(level)").monospacedDigit()
            Image(systemName: level <= 10 ? "battery.0" : level <= 35 ? "battery.25" : "battery.50")
                .foregroundStyle(level <= 10 ? Theme.Colors.alertText : Theme.Colors.textPrimary)
        }
        .font(Theme.Fonts.calloutStrong)
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, openingStatusMargin)
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
                    if value.translation.height < -openingSwipeDistance
                        || value.predictedEndTranslation.height < -2 * openingSwipeDistance {
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

    /// Dark → the light phone (350 ms; reduced motion: 200 ms fade). #001 then hands over at once;
    /// #002–#005 wait on their lock screen.
    private func run() async {
        guard stage == .dark, !finished else { return }
        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }
        AudioDirector.shared.play(.unlock, volume: 0.5)
        withAnimation(noMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.35)) { advance(to: .phone) }
        try? await Task.sleep(for: .milliseconds(noMotion ? 200 : 350))
        guard !Task.isCancelled else { return }
        if autoUnlock { finish() }
    }

    private func advance(to next: Stage) {
        if stage < next { stage = next }
    }

    /// A tap during the fade jumps to its end (and opens #001); on the lock screen, it unlocks.
    private func skipAhead() {
        guard !finished else { return }
        if stage < .phone {
            advance(to: .phone)
            if autoUnlock { finish() }
        } else if stage == .phone {
            startUnlock()
        }
    }

    private func startUnlock() {
        Task { await unlock() }
    }

    /// The lock screen slides up (300 ms; reduced motion: a 200 ms fade), then the phone.
    private func unlock() async {
        guard stage == .phone, !finished else { return }
        if autoUnlock { finish(); return }
        AudioDirector.shared.play(.unlock, volume: 0.7)
        Haptics.light()
        let duration = noMotion ? 0.2 : 0.3
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
}

/// The phone grows from 0.96 as it lights up.
private let openingScale: CGFloat = 0.96
/// Side margins of the lock screen's status bar.
private let openingStatusMargin: CGFloat = 30
/// Swipe up this far (or fling twice as far) to unlock.
private let openingSwipeDistance: CGFloat = 60
#endif
