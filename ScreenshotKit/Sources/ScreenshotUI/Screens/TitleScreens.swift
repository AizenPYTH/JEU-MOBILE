#if os(iOS)
import SwiftUI
import CaseEngine

// Screens 02, 02b and 03 of the final handoff (§C, §F-02, §F-02b, §F-03): the title of the first
// launch, the title with an investigation in progress, and « Qui enquête ? ». Dark desk only: the
// logo banner never sits on a light background.

/// Layout of the title screens (390 × 844 reference, handoff §F « Gabarit commun »).
private enum TitleLayout {
    /// The logo banner: 330 pt wide, 112 pt from the top of the screen, 16 pt of breathing room.
    static let bannerWidth: CGFloat = 330
    static let bannerTop: CGFloat = 112
    static let bannerBreathing: CGFloat = 16
    /// Never under the ⚙ button, whatever the safe area.
    static let bannerMinTop: CGFloat = 52
    /// Side margins: 24 pt for the button, 28 pt for texts, 16 pt for sheets.
    static let buttonMargin: CGFloat = 24
    static let textMargin: CGFloat = 28
    static let sheetMargin: CGFloat = 16
    /// The main button sits at safeArea.bottom + 10.
    static let buttonBottom: CGFloat = 10
    static let iconSize: CGFloat = 44
    /// « Qui enquête ? »: two cards 14 pt apart; prints with a 6 pt white border.
    static let cardGap: CGFloat = 14
    static let cardPadding: CGFloat = 10
    static let printBorder: CGFloat = 6
    /// Print width when the cards stack (accessibility text sizes), and of the A / B choice.
    static let stackedPrint: CGFloat = 96
    static let appearancePrint: CGFloat = 72
    static let appearanceBorder: CGFloat = 4
    /// The chosen card is lifted by 6 pt.
    static let lift: CGFloat = 6
}

// MARK: - Shared frame of 02 and 02b

/// The desk, ⚙ top right, the logo banner, the content, and the actions pinned at
/// `safeArea.bottom + 10`. The content scrolls when it does not fit (accessibility text sizes).
private struct TitleFrame<Content: View, Actions: View>: View {
    let onSettings: () -> Void
    let content: Content
    let actions: Actions

    init(onSettings: @escaping () -> Void, @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        self.onSettings = onSettings
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        LogoWordmark(width: min(TitleLayout.bannerWidth, geo.size.width - 2 * TitleLayout.bannerBreathing))
                            .padding(.top, max(TitleLayout.bannerMinTop, TitleLayout.bannerTop - geo.safeAreaInsets.top))
                        content
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                actions
                    .padding(.horizontal, TitleLayout.buttonMargin)
                    .padding(.top, 10)
                    .padding(.bottom, TitleLayout.buttonBottom)
            }
        }
        .background(DeskBackdrop())
        .overlay(alignment: .topTrailing) {
            SettingsGearButton(action: onSettings)
                .padding(.trailing, 8)
        }
    }
}

/// ⚙ Paramètres, top right of 02 and 02b (44 × 44).
private struct SettingsGearButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Trace.Colors.boneMid)
                .frame(width: TitleLayout.iconSize, height: TitleLayout.iconSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("menu.settings")))
        .accessibilityIdentifier("title.settings")
    }
}

// MARK: - 02 · Titre

/// Screen 02 · Titre (first launch): the test of the first ten seconds. Exactly the banner, the
/// hook, the mission, the three verbs, [COMMENCER L'ENQUÊTE] and ⚙ — nothing else (criterion P-2).
struct TitleScreen: View {
    let onStart: () -> Void
    let onSettings: () -> Void

    var body: some View {
        TitleFrame(onSettings: onSettings) {
            VStack(spacing: 0) {
                Text(L10n.t("title.hook"))
                    .font(Trace.Fonts.tagline)
                    .foregroundStyle(Trace.Colors.bone)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 30)
                Text(L10n.t("title.mission"))
                    .font(Trace.Fonts.uiBody)
                    .foregroundStyle(Trace.Colors.boneMid)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
                VerbRow()
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, TitleLayout.textMargin)
        } actions: {
            Button(L10n.t("title.start"), action: onStart)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("title.start")
        }
    }
}

/// 01 EXPLORER · 02 VERSER AU DOSSIER · 03 CONCLURE: the whole game in three verbs (§D). Side by
/// side under a thin rule; stacked at accessibility text sizes.
private struct VerbRow: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    private struct Verb: Identifiable {
        let id: String
        let label: String
    }

    private var verbs: [Verb] {
        [Verb(id: "01", label: L10n.t("title.verb.explore")),
         Verb(id: "02", label: L10n.t("title.verb.file")),
         Verb(id: "03", label: L10n.t("title.verb.conclude"))]
    }

    var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout {
            ForEach(verbs) { verb in
                VStack(alignment: stacked ? .leading : .center, spacing: 6) {
                    Text(verbatim: verb.id)
                        .font(Trace.Fonts.kicker)
                        .tracking(1)
                        .foregroundStyle(Trace.Colors.stampOnDark)
                        .accessibilityHidden(true)
                    // One static text per verb for VoiceOver: « 01 EXPLORER ».
                    Text(verb.label)
                        .font(Trace.Fonts.monoStrong)
                        .tracking(1)
                        .foregroundStyle(Trace.Colors.bone)
                        .multilineTextAlignment(stacked ? .leading : .center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(Text(verbatim: "\(verb.id) \(verb.label)"))
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: stacked ? .leading : .center)
                .overlay(alignment: .top) {
                    Rectangle().fill(Trace.Colors.bone.opacity(0.3)).frame(height: 1.5)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: - 02b · Titre, reprise

/// Screen 02b · Titre, reprise: an investigation is in progress. The banner, the card of that
/// investigation (case, time left, pieces filed), [REPRENDRE L'ENQUÊTE] and « Aller au Bureau ».
struct TitleResumeScreen: View {
    let caseFile: CaseFile
    let remainingSeconds: Double
    let pieces: Int
    let onResume: () -> Void
    let onDesk: () -> Void
    let onSettings: () -> Void

    var body: some View {
        TitleFrame(onSettings: onSettings) {
            ResumeCard(caseFile: caseFile, remainingSeconds: remainingSeconds, pieces: pieces)
                .padding(.horizontal, TitleLayout.buttonMargin)
                .padding(.top, 40)
        } actions: {
            VStack(spacing: 6) {
                Button(L10n.t("title.toDesk"), action: onDesk)
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("title.desk")
                Button(L10n.t("home.resume"), action: onResume)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("title.resume")
            }
        }
    }
}

/// « ENQUÊTE EN COURS »: the paper card of the investigation left open.
private struct ResumeCard: View {
    let caseFile: CaseFile
    let remainingSeconds: Double
    let pieces: Int
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("title.inProgress"))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.stamp)
            Text(verbatim: "#\(shownNumber(caseFile.number)) · \(caseFile.title)")
                .font(Trace.Fonts.serifTitle(22))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1)
            layout {
                Text(L10n.f("title.remaining", PhoneFormat.countdown(remainingSeconds)))
                    .fixedSize(horizontal: false, vertical: true)
                if !stacked {
                    Text(verbatim: "·").accessibilityHidden(true)
                }
                Text(L10n.f("dossier.piecesCount", pieces))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(Trace.Fonts.fieldValue)
            .foregroundStyle(Trace.Colors.inkMid)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .rotationEffect(.degrees(-0.6))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 03 · Qui enquête ?

/// Screen 03 · Qui enquête ? The two investigators of the BEN, the current one preselected (Élise
/// on a first launch). The chosen card lifts (−6 pt, red rule, « ✓ CHOISIE »), the other dims to
/// 60 %. No service number, no rank here. Opened from the profile (`allowsAppearance`), it also
/// offers the photo A / B of the chosen investigator, and saves instead of continuing.
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
    /// 260 ms `paper` spring; a 200 ms fade with reduced motion.
    private var selectionAnimation: Animation { noMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        cards(width: geo.size.width - 2 * TitleLayout.sheetMargin)
                            .padding(.horizontal, TitleLayout.sheetMargin)
                            .padding(.top, 24)
                        if allowsAppearance {
                            appearancePicker
                                .padding(.horizontal, TitleLayout.textMargin)
                                .padding(.top, 24)
                        }
                        Text(L10n.t("who.note"))
                            .font(Trace.Fonts.uiBody)
                            .foregroundStyle(Trace.Colors.bone2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, TitleLayout.textMargin)
                            .padding(.top, 18)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                Button(allowsAppearance ? L10n.t("who.save") : L10n.t("who.continue")) {
                    onContinue(PlayerIdentity(id: selected, appearance: appearance))
                }
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("who.continue")
                .padding(.horizontal, TitleLayout.buttonMargin)
                .padding(.top, 10)
                .padding(.bottom, TitleLayout.buttonBottom)
            }
        }
        .background(DeskBackdrop())
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Trace.Colors.bone)
                    .frame(width: TitleLayout.iconSize, height: TitleLayout.iconSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("common.back")))
            .accessibilityIdentifier("who.back")
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("who.title"))
                .font(Trace.Fonts.monoTitle)
                .tracking(2.2)
                .foregroundStyle(Trace.Colors.bone)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(allowsAppearance ? L10n.t("who.subtitleEdit") : L10n.t("who.subtitle"))
                .font(Trace.Fonts.uiBody)
                .foregroundStyle(Trace.Colors.boneMid)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, TitleLayout.textMargin)
        .padding(.top, 4)
    }

    /// Two columns; one column at accessibility text sizes. Both cards take the same height.
    @ViewBuilder
    private func cards(width: CGFloat) -> some View {
        if stacked {
            VStack(spacing: TitleLayout.cardGap) {
                card(.elise, printWidth: TitleLayout.stackedPrint)
                card(.vincent, printWidth: TitleLayout.stackedPrint)
            }
        } else {
            let cardWidth = max(0, (width - TitleLayout.cardGap) / 2)
            let printWidth = max(40, cardWidth - 2 * TitleLayout.cardPadding - 2 * TitleLayout.printBorder)
            HStack(alignment: .top, spacing: TitleLayout.cardGap) {
                card(.elise, printWidth: printWidth)
                card(.vincent, printWidth: printWidth)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func card(_ id: PlayerID, printWidth: CGFloat) -> some View {
        let isChosen = id == selected
        // Appearance A on the cards; the chosen photo when it can be changed here.
        let shown = PlayerIdentity(id: id, appearance: allowsAppearance && isChosen ? appearance : .a)
        return Button {
            choose(id)
        } label: {
            InvestigatorCard(identity: shown, chosen: isChosen, printWidth: printWidth, sideBySide: stacked)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(.plain)
        .opacity(isChosen ? 1 : 0.6)
        .offset(y: isChosen && !noMotion ? -TitleLayout.lift : 0)
        .zIndex(isChosen ? 1 : 0)
        .accessibilityLabel(Text(verbatim: "\(id.fullName), \(id.title.lowercased())"))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.\(id.rawValue)")
    }

    private func choose(_ id: PlayerID) {
        guard id != selected else { return }
        Haptics.selection()
        withAnimation(selectionAnimation) { selected = id }
    }

    /// « APPARENCE »: photo A or B of the chosen investigator (from the profile only).
    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("who.appearance"))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.bone2)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 18) {
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
            withAnimation(selectionAnimation) { appearance = look }
        } label: {
            VStack(spacing: 6) {
                PlayerPrint(identity: PlayerIdentity(id: selected, appearance: look),
                            width: TitleLayout.appearancePrint, border: TitleLayout.appearanceBorder)
                    .overlay(Rectangle().strokeBorder(Trace.Colors.stamp, lineWidth: 2).opacity(isChosen ? 1 : 0))
                Text(verbatim: letter)
                    .font(Trace.Fonts.kicker)
                    .foregroundStyle(isChosen ? Trace.Colors.stampOnDark : Trace.Colors.bone2)
            }
            .opacity(isChosen ? 1 : 0.6)
            .offset(y: isChosen && !noMotion ? -TitleLayout.lift : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.f("who.appearanceOption", letter)))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.appearance.\(look.rawValue)")
    }
}

/// One investigator on screen 03: the 4:5 print, the name, the title; « ✓ CHOISIE » and a red
/// rule when chosen. In two columns the print is on top; stacked (accessibility sizes), on the left.
private struct InvestigatorCard: View {
    let identity: PlayerIdentity
    let chosen: Bool
    let printWidth: CGFloat
    let sideBySide: Bool

    var body: some View {
        let layout = sideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 14))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
        layout {
            PlayerPrint(identity: identity, width: printWidth, border: TitleLayout.printBorder)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: identity.id.fullName)
                    .font(Trace.Fonts.serifTitle(21))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(identity.id.title)
                    .font(Trace.Fonts.monoSmall)
                    .tracking(1.4)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(identity.id.isFeminine ? L10n.t("who.chosenF") : L10n.t("who.chosenM"))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.4)
                    .foregroundStyle(Trace.Colors.stamp)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .opacity(chosen ? 1 : 0)
            }
        }
        .padding(TitleLayout.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paper(chosen ? Trace.Colors.paperSelected : Trace.Colors.paper, radius: 0, lifted: chosen)
        .overlay(Rectangle().strokeBorder(Trace.Colors.stamp, lineWidth: 2).opacity(chosen ? 1 : 0))
        .contentShape(Rectangle())
    }
}
#endif
