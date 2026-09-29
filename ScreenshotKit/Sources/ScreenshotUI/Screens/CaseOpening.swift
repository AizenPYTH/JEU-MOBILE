#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Le scellé (Dossier → téléphone), screen 03

/// EvidenceSeal (handoff V4 §3, screen 03): the passage from the case file to the phone. On the
/// lamp-lit desk, the seized phone lies SWITCHED OFF in a clear evidence bag (its dark screen only
/// shows the time it was last on), with the paper tag « SCELLÉ N° 001-01 » and its owner; under
/// it, what the case file already says (the place of the case, the last time the phone was on),
/// and the one button « Ouvrir le scellé ». No phone unlock code is mentioned: no case provides
/// one (the codes of locked apps are clues to find, never given here).
///
/// « Ouvrir le scellé » (V4 §5, 900 ms): the tag peels off (0 → 8°, fades), the view zooms on the
/// phone's screen to the full frame, the screen lights up on the owner's wallpaper, then `onDone`
/// — the caller starts the clock there (it never runs before). Reduced motion: a 200 ms fade.
///
/// The seal is shown once per case (`SealStore`); later, the phone opens at once (200 ms fade).
struct CaseOpeningView: View {
    let session: GameSession
    let onDone: () -> Void

    /// The seal of this case was opened before: straight to the phone (read once, when the screen
    /// appears: opening the seal must not switch this screen to the short path mid-animation).
    @State private var alreadyOpened: Bool
    @State private var opening = false
    /// The tag has peeled off.
    @State private var peeled = false
    /// The view is zoomed on the phone's screen.
    @State private var zoomed = false
    /// The phone's wallpaper covers the screen.
    @State private var lit = false
    @State private var finished = false
    /// The phone's screen in the view (measured before the zoom only).
    @State private var screenFrame: CGRect = .zero
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(session: GameSession, onDone: @escaping () -> Void) {
        self.session = session
        self.onDone = onDone
        _alreadyOpened = State(initialValue: SealStore.isOpened(session.caseFile.id))
    }

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    private var device: Device { session.game.device }
    /// The phone's own time: the last time it was on.
    private var time: Moment { session.phoneTime }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TraceDesk()
                if !alreadyOpened {
                    stage(size: geo.size)
                }
                // The phone lights up: its wallpaper fills the screen, then the phone itself.
                Wallpaper(style: device.wallpaper ?? .night)
                    .opacity(lit ? 1 : 0)
                    .environment(\.colorScheme, .light)
            }
            .coordinateSpace(.named(sealSpace))
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("opening.view")
        .task {
            guard alreadyOpened else { return }
            await straightToPhone()
        }
    }

    // MARK: The stage

    /// Everything on the desk; zoomed on the phone's screen when the seal opens.
    private func stage(size: CGSize) -> some View {
        let phoneWidth = Self.phoneWidth(for: size)
        let zoom = zoomTransform(in: size)
        return VStack(spacing: 0) {
            Text(fileLabel(session.caseFile.number))
                .fieldLabel(Trace.Colors.ivory2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: Trace.Height.hit)
                .opacity(zoomed ? 0 : 1)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            seal(phoneWidth: phoneWidth)
            facts
                .padding(.top, sealTagDrop + 28)
                .opacity(zoomed ? 0 : 1)
            Spacer(minLength: 16)
            Button(L10n.t("opening.openSeal")) { open() }
                .buttonStyle(CTAButtonStyle(kind: .primary))
                .opacity(zoomed ? 0 : 1)
                .accessibilityIdentifier("opening.unlock")
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(width: size.width, height: size.height)
        .scaleEffect(zoomed ? zoom.scale : 1, anchor: zoom.anchor)
        .offset(zoomed ? zoom.offset : .zero)
    }

    /// The clear bag, the switched-off phone inside it, and the tag hanging from its bottom edge.
    private func seal(phoneWidth: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            bag(phoneWidth: phoneWidth)
            tag
                .offset(y: sealTagDrop)
                .rotationEffect(.degrees(peeled && !noMotion ? sealTagPeelAngle : 0), anchor: .topLeading)
                .offset(y: peeled && !noMotion ? 12 : 0)
                .opacity(peeled ? 0 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(sealAccessibilityLabel))
        .accessibilityAddTraits(.isImage)
    }

    private func bag(phoneWidth: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: sealBagRadius, style: .continuous)
        return phone(width: phoneWidth)
            .padding(.horizontal, sealBagSide)
            .padding(.top, sealBagTop)
            .padding(.bottom, sealBagBottom)
            .background(shape.fill(Trace.Colors.sealBag))
            .overlay(shape.strokeBorder(Trace.Colors.ivory.opacity(sealRuleOpacity), lineWidth: 1))
            .overlay(alignment: .top) {
                // The bag's zip: a double rule across its mouth.
                VStack(spacing: 3) {
                    Rectangle().frame(height: 1)
                    Rectangle().frame(height: 1)
                }
                .foregroundStyle(Trace.Colors.ivory.opacity(sealRuleOpacity))
                .padding(.horizontal, 10)
                .padding(.top, 16)
                .opacity(zoomed ? 0 : 1)
            }
            .overlay {
                // The plastic's sheen over the phone (decorative).
                LinearGradient(colors: [Trace.Colors.ivory.opacity(0.10), .clear, Trace.Colors.ivory.opacity(0.05)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(shape)
                    .opacity(zoomed ? 0 : 1)
                    .allowsHitTesting(false)
            }
    }

    /// The seized phone, switched off: a dark screen with only the time it was last on.
    private func phone(width: CGFloat) -> some View {
        let screenRadius = zoomed ? 0 : sealScreenRadius
        return RoundedRectangle(cornerRadius: sealScreenRadius + sealBezel, style: .continuous)
            .fill(Trace.Colors.graphite)
            .overlay(
                RoundedRectangle(cornerRadius: sealScreenRadius + sealBezel, style: .continuous)
                    .strokeBorder(Trace.Colors.line, lineWidth: 1)
            )
            .overlay {
                RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                    .fill(Trace.Colors.bgDeep)
                    .overlay(alignment: .top) {
                        VStack(spacing: 2) {
                            Text(PhoneFormat.longDayCapitalized(time))
                                .font(Theme.font(Theme.FontName.medium, max(8, width * 0.065)))
                            Text(PhoneFormat.time(time))
                                .font(Theme.font(Theme.FontName.light, max(22, width * 0.26)))
                                .monospacedDigit()
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(Trace.Colors.ivory2.opacity(sealScreenTextOpacity))
                        .padding(.horizontal, 8)
                        .padding(.top, width * 0.28)
                        .opacity(zoomed ? 0 : 1)
                    }
                    .padding(sealBezel)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(sealSpace)) } action: { frame in
                        if !opening { screenFrame = frame }
                    }
            }
            .frame(width: width, height: width * sealPhoneRatio)
            .accessibilityHidden(true)
    }

    /// The paper tag: « SCELLÉ N° 001-01 » in red, the owner, the model.
    private var tag: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Trace.Colors.photoBorder)
                .overlay(Circle().strokeBorder(Trace.Colors.kraftDark, lineWidth: 1))
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(sealNumber)
                    .font(Trace.Fonts.data)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.red)
                Text(ownerName)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.ink)
                Text(device.model)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.leading, 12)
        .padding(.trailing, 18)
        .padding(.vertical, 10)
        .frame(minWidth: sealTagMinWidth, alignment: .leading)
        .background(
            Rectangle()
                .fill(Trace.Colors.paperCard)
                .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
        )
    }

    /// What the case file already says: the place of the case, the time the phone was last on.
    private var facts: some View {
        VStack(spacing: 6) {
            if let dossier = session.caseFile.dossier {
                Text(dossier.place + ", " + dossier.city)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ivory)
            }
            Text(L10n.f("seal.lastOn", PhoneFormat.longDay(time) + ", " + PhoneFormat.time(time)))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ivory2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Words

    /// « SCELLÉ N° 001-01 » (case number, then the device: one phone per case for now).
    private var sealNumber: String { L10n.f("opening.seal", shownNumber(session.caseFile.number) + "-01") }

    private var ownerName: String {
        device.contacts.first { $0.isOwner == true || $0.id == ownerContactID }?.name ?? device.label
    }

    private var sealAccessibilityLabel: String {
        [sealNumber, ownerName, device.model].joined(separator: ", ")
    }

    // MARK: Geometry

    /// The phone's width: 40 % of the screen, at most 170 pt, smaller on a short screen.
    private static func phoneWidth(for size: CGSize) -> CGFloat {
        let byHeight = (size.height - sealOtherContent) / sealPhoneRatio
        return max(sealPhoneMinWidth, min(size.width * 0.4, sealPhoneMaxWidth, byHeight))
    }

    /// Scale and offset that bring the phone's screen to the full frame.
    private func zoomTransform(in size: CGSize) -> (scale: CGFloat, anchor: UnitPoint, offset: CGSize) {
        guard screenFrame.width > 0, screenFrame.height > 0, size.width > 0, size.height > 0 else {
            return (1, .center, .zero)
        }
        // A little beyond the frame: the screen also covers the safe areas around it.
        let scale = max(size.width / screenFrame.width, size.height / screenFrame.height) * sealZoomOvershoot
        let anchor = UnitPoint(x: screenFrame.midX / size.width, y: screenFrame.midY / size.height)
        let offset = CGSize(width: size.width / 2 - screenFrame.midX, height: size.height / 2 - screenFrame.midY)
        return (scale, anchor, offset)
    }

    // MARK: Sequence

    /// « Ouvrir le scellé »: remembered for this case, then 900 ms to the lit phone.
    private func open() {
        guard !opening, !finished else { return }
        opening = true
        SealStore.markOpened(session.caseFile.id)
        AudioDirector.shared.play(.paper, volume: 0.6)
        Haptics.light()
        guard !noMotion, screenFrame != .zero else {
            withAnimation(.easeInOut(duration: 0.2)) { lit = true }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                finish()
            }
            return
        }
        withAnimation(.easeIn(duration: 0.25)) { peeled = true }
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.6)) { zoomed = true }
            try? await Task.sleep(for: .milliseconds(350))
            AudioDirector.shared.play(.unlock, volume: 0.5)
            withAnimation(.easeOut(duration: 0.3)) { lit = true }
            try? await Task.sleep(for: .milliseconds(400))
            finish()
        }
    }

    /// A case whose seal was already opened: the phone lights up at once (200 ms).
    private func straightToPhone() async {
        withAnimation(.easeOut(duration: 0.2)) { lit = true }
        try? await Task.sleep(for: .milliseconds(200))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onDone()
    }
}

/// The cases whose seal the player has opened (the seal is shown once per case). Cleared by the UI
/// tests' reset (`UITestHooks`).
enum SealStore {
    static let key = "conclude.sealOpened.v1"

    static func isOpened(_ caseID: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: key) ?? []).contains(caseID)
    }

    static func markOpened(_ caseID: String) {
        var ids = UserDefaults.standard.stringArray(forKey: key) ?? []
        guard !ids.contains(caseID) else { return }
        ids.append(caseID)
        UserDefaults.standard.set(ids, forKey: key)
    }
}

/// The seal's coordinate space (the zoom finds the phone's screen in it).
private let sealSpace = "opening.seal.space"
/// The phone: height = 2.05 × width, 96…170 pt wide; room kept for the rest of the screen.
private let sealPhoneRatio: CGFloat = 2.05
private let sealPhoneMinWidth: CGFloat = 96
private let sealPhoneMaxWidth: CGFloat = 170
private let sealOtherContent: CGFloat = 430
private let sealBezel: CGFloat = 5
private let sealZoomOvershoot: CGFloat = 1.12
private let sealScreenRadius: CGFloat = 18
private let sealScreenTextOpacity: Double = 0.6
/// The bag: radius 14, ivory rule at 28 %, room around the phone (more at the bottom for the tag).
private let sealBagRadius: CGFloat = 14
private let sealRuleOpacity: Double = 0.28
private let sealBagSide: CGFloat = 26
private let sealBagTop: CGFloat = 40
private let sealBagBottom: CGFloat = 44
/// The tag hangs this far below the bag; it peels off to 8°.
private let sealTagDrop: CGFloat = 26
private let sealTagPeelAngle: Double = 8
private let sealTagMinWidth: CGFloat = 190
#endif
