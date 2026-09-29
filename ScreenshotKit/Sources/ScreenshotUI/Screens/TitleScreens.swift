#if os(iOS)
import SwiftUI
import CaseEngine

// « Qui enquête ? » (UX V3 §7 step 2, V4 « Dossier lisible » look). The title screens of the final
// V3 handoff (02 Titre, 02b Titre-reprise) are no longer routed to since the UX V3 (the first launch
// opens on 00 · Première impression, FirstImpression.swift) and have been removed.

/// Sizes of « Qui enquête ? » (V4 §2–§3).
private enum WhoLayout {
    static let margin: CGFloat = 20
    /// Two prints side by side, 20 pt apart; stacked (accessibility sizes) at most 240 pt wide.
    static let printGap: CGFloat = 20
    static let stackedPrintWidth: CGFloat = 240
    /// A print: 6 pt white border (12 pt under the name), the portrait at 4:5.
    static let printBorder: CGFloat = 6
    static let portraitRatio: CGFloat = 0.8
    /// The chosen print: straight, lifted 6 pt, red rule 2 pt, red pin 14 pt. The other: tilted,
    /// at 55 %.
    static let lift: CGFloat = 6
    static let rule: CGFloat = 2
    static let pin: CGFloat = 14
    static let dimmed: Double = 0.55
    /// Tilts of the print not chosen (≤ 1.5°, V4 §2).
    static let tiltElise: Double = -1.2
    static let tiltVincent: Double = 1.2
    /// Photo A / B (from the profile): 72 pt prints.
    static let appearancePrint: CGFloat = 72
}

// MARK: - Qui enquête ?

/// « Qui enquête ? » (UX V3 §7 step 2, simplified): one choice screen and its confirmation. On the
/// desk, the two investigators of the BEN as stapled prints (portrait, name in Newsreader on the
/// white margin), the current one preselected (Élise on a first launch). The chosen print lies
/// straight, lifted, pinned in red with a red rule and « ✓ CHOISIE » under it; the other is slightly
/// tilted, at 55 %. No service number, no rank here. Opened from the profile (`allowsAppearance`), it
/// also offers the photo A / B of the chosen investigator, and saves instead of continuing.
struct WhoInvestigatesScreen: View {
    let initial: PlayerIdentity
    let allowsAppearance: Bool
    let onContinue: (PlayerIdentity) -> Void
    let onBack: () -> Void

    @State private var selected: PlayerID
    @State private var appearance: Appearance
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(initial: PlayerIdentity, allowsAppearance: Bool,
         onContinue: @escaping (PlayerIdentity) -> Void, onBack: @escaping () -> Void) {
        self.initial = initial
        self.allowsAppearance = allowsAppearance
        self.onContinue = onContinue
        self.onBack = onBack
        _selected = State(initialValue: initial.id)
        _appearance = State(initialValue: initial.appearance)
    }

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    private var stacked: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BackLink(title: L10n.t("common.back"), identifier: "who.back", action: onBack)
                Spacer()
            }
            .padding(.horizontal, Trace.Spacing.l)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    prints
                        .padding(.top, Trace.Spacing.xxl + Trace.Spacing.s)
                    if allowsAppearance {
                        appearancePicker
                            .padding(.top, Trace.Spacing.xxl)
                    }
                    Text(L10n.t("who.note"))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ivoryMid)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Trace.Spacing.xxl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WhoLayout.margin)
                .padding(.bottom, Trace.Spacing.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(allowsAppearance ? L10n.t("who.save") : L10n.f("who.continueWith", selected.firstName)) {
                onContinue(PlayerIdentity(id: selected, appearance: appearance))
            }
            .buttonStyle(CTAButtonStyle(kind: .primary))
            .accessibilityIdentifier("who.continue")
            .padding(.horizontal, WhoLayout.margin)
            .padding(.top, Trace.Spacing.s)
            .padding(.bottom, Trace.Spacing.s)
        }
        .background(DeskBackdrop())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.t("who.title"))
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(allowsAppearance ? L10n.t("who.subtitleEdit") : L10n.t("who.subtitle"))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ivoryMid)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Trace.Spacing.s)
    }

    /// Two prints side by side; one under the other at accessibility text sizes.
    @ViewBuilder
    private var prints: some View {
        if stacked {
            VStack(spacing: Trace.Spacing.xxl) {
                choice(.elise)
                choice(.vincent)
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: .top, spacing: WhoLayout.printGap) {
                choice(.elise)
                choice(.vincent)
            }
        }
    }

    private func choice(_ id: PlayerID) -> some View {
        let isChosen = id == selected
        // Appearance A on the prints; the chosen photo when it can be changed here.
        let shown = PlayerIdentity(id: id, appearance: allowsAppearance && isChosen ? appearance : .a)
        return Button {
            choose(id)
        } label: {
            VStack(spacing: Trace.Spacing.m) {
                InvestigatorPrint(identity: shown, chosen: isChosen,
                                  tilt: id == .elise ? WhoLayout.tiltElise : WhoLayout.tiltVincent,
                                  still: noMotion)
                // « ✓ CHOISIE »: never the colour or the pin alone. Its room is kept when hidden.
                Text(L10n.t(id.isFeminine ? "who.chosenF" : "who.chosenM"))
                    .fieldLabel(Trace.Colors.redOnDesk)
                    .opacity(isChosen ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: stacked ? WhoLayout.stackedPrintWidth : .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: "\(id.fullName), \(id.title.lowercased())"))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.\(id.rawValue)")
    }

    private func choose(_ id: PlayerID) {
        guard id != selected else { return }
        Haptics.selection()
        selected = id
    }

    /// « Apparence »: photo A or B of the chosen investigator (from the profile only).
    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("who.appearance"), color: Trace.Colors.ivory2)
            HStack(alignment: .top, spacing: Trace.Spacing.xl) {
                appearanceOption(.a)
                appearanceOption(.b)
            }
        }
    }

    private func appearanceOption(_ look: Appearance) -> some View {
        let isChosen = look == appearance
        let letter = look.rawValue.uppercased()
        return Button {
            guard look != appearance else { return }
            Haptics.selection()
            appearance = look
        } label: {
            VStack(spacing: Trace.Spacing.s) {
                PlayerPrint(identity: PlayerIdentity(id: selected, appearance: look), width: WhoLayout.appearancePrint,
                            border: 4)
                    .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: WhoLayout.rule).opacity(isChosen ? 1 : 0))
                Text(verbatim: letter)
                    .font(Trace.Fonts.data)
                    .foregroundStyle(isChosen ? Trace.Colors.ivory : Trace.Colors.ivory2)
            }
            .opacity(isChosen ? 1 : WhoLayout.dimmed)
            .animation(.easeInOut(duration: 0.2), value: isChosen)
            .frame(minWidth: Trace.Height.hit, minHeight: Trace.Height.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.f("who.appearanceOption", letter)))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.appearance.\(look.rawValue)")
    }
}

/// One investigator as a print laid on the desk (V4 §3, like a PinnedSuspect): the 4:5 portrait
/// (or initials), the name in Newsreader and the title in Plex Mono on the white margin, a staple.
/// Chosen: straight, lifted 6 pt, a 2 pt red rule and a red pin (260 ms). Not chosen: tilted
/// (≤ 1.5°, none with « Augmenter le contraste »), at 55 %. Reduced motion: only the opacity fades.
private struct InvestigatorPrint: View {
    let identity: PlayerIdentity
    let chosen: Bool
    let tilt: Double
    let still: Bool

    /// « ENQUÊTRICE » as printed on the margin.
    private var titleText: String { identity.id.title.uppercased() }

    var body: some View {
        PhotoPrint(border: WhoLayout.printBorder) {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(WhoLayout.portraitRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        GeometryReader { geo in
                            PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                                               width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .clipped()
                Text(verbatim: identity.id.fullName)
                    .font(Trace.Fonts.personName)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Trace.Spacing.m)
                    .padding(.horizontal, 2)
                Text(titleText)
                    .fieldLabel(Trace.Colors.ink2)
                    .padding(.top, 2)
                    .padding(.horizontal, 2)
            }
        }
        .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: WhoLayout.rule).opacity(chosen ? 1 : 0))
        .overlay(alignment: .topLeading) {
            Staple()
                .padding(.leading, Trace.Spacing.l)
                .offset(y: -4)
        }
        .overlay(alignment: .top) {
            Pin(color: Trace.Colors.red, size: WhoLayout.pin)
                .offset(y: -WhoLayout.pin / 2)
                .scaleEffect(chosen || still ? 1 : 1.2)
                .opacity(chosen ? 1 : 0)
        }
        .modifier(TiltModifier(degrees: chosen ? 0 : tilt))
        .offset(y: chosen && !still ? -WhoLayout.lift : 0)
        .animation(still ? nil : .easeOut(duration: 0.26), value: chosen)
        .opacity(chosen ? 1 : WhoLayout.dimmed)
        .animation(.easeInOut(duration: 0.2), value: chosen)
        .accessibilityHidden(true)
    }
}
#endif
