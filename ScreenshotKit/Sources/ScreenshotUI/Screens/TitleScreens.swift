#if os(iOS)
import SwiftUI
import CaseEngine

// Screens 02, 02b and 03 of the final handoff (§C, §F-02, §F-02b, §F-03): the title of the first
// launch, the title with an investigation in progress, and « Qui enquête ? ». With the UX V3 the
// first launch opens on 00 · Première impression (FirstImpression.swift) and the title screens are
// no longer routed to; they are kept compiling. « Qui enquête ? » is re-skinned (§7 step 2).

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
        .benCard()
        .accessibilityElement(children: .combine)
    }
}


// MARK: - Qui enquête ? (UX V3 §7 step 2)

/// « Qui enquête ? » (UX V3 §7 step 2, simplified): one choice screen and its confirmation. The two
/// investigators of the BEN as flat cards, the current one preselected (Élise on a first launch);
/// the chosen card has a 2 pt `ben` border and a check, the other is dimmed. No service number, no
/// rank here. Opened from the profile (`allowsAppearance`), it also offers the photo A / B of the
/// chosen investigator, and saves instead of continuing.
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
    /// A short ease; a 200 ms fade with reduced motion.
    private var selectionAnimation: Animation { noMotion ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.2) }

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
                    cards
                        .padding(.top, Trace.Spacing.xxl)
                    if allowsAppearance {
                        appearancePicker
                            .padding(.top, Trace.Spacing.xxl)
                    }
                    Text(L10n.t("who.note"))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Trace.Spacing.xl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.bottom, Trace.Spacing.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(allowsAppearance ? L10n.t("who.save") : L10n.f("who.continueWith", selected.firstName)) {
                onContinue(PlayerIdentity(id: selected, appearance: appearance))
            }
            .buttonStyle(CTAButtonStyle(kind: .primary))
            .accessibilityIdentifier("who.continue")
            .padding(.horizontal, Trace.Spacing.xl)
            .padding(.top, Trace.Spacing.s)
            .padding(.bottom, Trace.Spacing.s)
        }
        .background(Trace.Colors.bg.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.t("who.title"))
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(allowsAppearance ? L10n.t("who.subtitleEdit") : L10n.t("who.subtitle"))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Trace.Spacing.s)
    }

    /// Two columns; one column at accessibility text sizes. Both cards take the same height.
    @ViewBuilder
    private var cards: some View {
        if stacked {
            VStack(spacing: Trace.Spacing.m) {
                card(.elise)
                card(.vincent)
            }
        } else {
            HStack(alignment: .top, spacing: Trace.Spacing.m) {
                card(.elise)
                card(.vincent)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func card(_ id: PlayerID) -> some View {
        let isChosen = id == selected
        // Appearance A on the cards; the chosen photo when it can be changed here.
        let shown = PlayerIdentity(id: id, appearance: allowsAppearance && isChosen ? appearance : .a)
        return Button {
            choose(id)
        } label: {
            InvestigatorCard(identity: shown, chosen: isChosen, sideBySide: stacked)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(PressableStyle())
        .opacity(isChosen ? 1 : 0.55)
        .accessibilityLabel(Text(verbatim: "\(id.fullName), \(id.title.lowercased())"))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.\(id.rawValue)")
    }

    private func choose(_ id: PlayerID) {
        guard id != selected else { return }
        Haptics.selection()
        withAnimation(selectionAnimation) { selected = id }
    }

    /// « Apparence »: photo A or B of the chosen investigator (from the profile only).
    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("who.appearance"))
            HStack(alignment: .top, spacing: Trace.Spacing.l) {
                appearanceOption(.a)
                appearanceOption(.b)
            }
        }
    }

    private func appearanceOption(_ look: Appearance) -> some View {
        let isChosen = look == appearance
        let letter = look.rawValue.uppercased()
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        return Button {
            guard look != appearance else { return }
            Haptics.selection()
            withAnimation(selectionAnimation) { appearance = look }
        } label: {
            VStack(spacing: 6) {
                PlayerPrint(identity: PlayerIdentity(id: selected, appearance: look), width: 72)
                    .overlay(shape.strokeBorder(Trace.Colors.ben, lineWidth: 2).opacity(isChosen ? 1 : 0))
                Text(verbatim: letter)
                    .font(Trace.Fonts.data)
                    .foregroundStyle(isChosen ? Trace.Colors.benText : Trace.Colors.text2)
            }
            .opacity(isChosen ? 1 : 0.55)
            .frame(minWidth: Trace.Height.hit, minHeight: Trace.Height.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.f("who.appearanceOption", letter)))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityIdentifier("who.appearance.\(look.rawValue)")
    }
}

/// One investigator on « Qui enquête ? »: a flat card with the 4:5 photo, the name (headline) and
/// the title (caption). Chosen: 2 pt `ben` border and a 26 pt check. In two columns the photo is
/// on top; stacked (accessibility sizes), on the left.
private struct InvestigatorCard: View {
    let identity: PlayerIdentity
    let chosen: Bool
    let sideBySide: Bool

    /// « ENQUÊTRICE » → « Enquêtrice » (V3: capitals only for section headers).
    private var titleText: String {
        let raw = identity.id.title
        return raw.prefix(1).uppercased() + raw.dropFirst().lowercased()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        let layout = sideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: Trace.Spacing.m))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: Trace.Spacing.m))
        layout {
            photo
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: identity.id.fullName)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(titleText)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Trace.Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(Trace.Colors.surface))
        .overlay(shape.strokeBorder(chosen ? Trace.Colors.ben : Trace.Colors.line, lineWidth: chosen ? 2 : 1))
        .overlay(alignment: .topTrailing) {
            if chosen {
                ZStack {
                    Circle().fill(Trace.Colors.ben)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Trace.Colors.onFill)
                }
                .frame(width: 26, height: 26)
                .padding(Trace.Spacing.s)
                .accessibilityHidden(true)
            }
        }
        .contentShape(shape)
    }

    /// The 4:5 photo, full card width in two columns, 96 pt wide when stacked.
    @ViewBuilder
    private var photo: some View {
        if sideBySide {
            PlayerPrint(identity: identity, width: 96)
        } else {
            Color.clear
                .aspectRatio(0.8, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    GeometryReader { geo in
                        PlayerPrint(identity: identity, width: geo.size.width)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
        }
    }
}
#endif
