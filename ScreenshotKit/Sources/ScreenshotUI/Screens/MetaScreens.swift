#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// BEN screens that are not the Bureau, the Archives, the profile or the case file (see
// DeskScreens.swift and DossierView.swift — the case file's level rows are its own `LevelRow`): the
// archived report, the settings and « À propos ». V4 « Dossier lisible » (docs/design_v4 §8 step 6):
// paper sheets laid on the dark wooden desk, ink text, Plex Mono section labels, rows separated by
// thin ink rules, figures with dotted leaders.

/// "001" style case number.
func caseNumber(_ n: Int) -> String { shownNumber(n) }

// MARK: - Paperwork (shared by the settings, the archived report and the ALIBI screens)

/// Tokens of the paper forms (V4 §2).
enum Paperwork {
    /// A thin rule between two rows of a sheet: ink at 16 %.
    static let rule = Trace.Colors.ink.opacity(0.16)
    /// The rule under a sheet's header: 1.5 pt ink (§3 CaseSheet).
    static let headerRule: CGFloat = 1.5
    /// Inner margin of a sheet; its margin on the desk.
    static let sheetPadding: CGFloat = 20
    static let deskMargin: CGFloat = 16
    /// A row of a form.
    static let rowHeight: CGFloat = 50
}

/// A thin ink rule (1 pt, or the 1.5 pt header rule).
struct PaperworkRule: View {
    var strong = false

    var body: some View {
        Rectangle()
            .fill(strong ? Trace.Colors.ink : Paperwork.rule)
            .frame(height: strong ? Paperwork.headerRule : 1)
            .accessibilityHidden(true)
    }
}

/// A dotted separator (§3 CaseSheet « section méthode séparée par un pointillé »), and the dots of
/// a leader line.
struct PaperworkDots: View {
    var color: Color = Trace.Colors.ink2.opacity(0.7)
    var gap: CGFloat = 4

    var body: some View {
        DotsLine()
            .stroke(color, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, gap]))
            .frame(height: 1.2)
            .accessibilityHidden(true)
    }

    private struct DotsLine: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

/// Label ........ value (§3 ClosingReport « lignes de chiffres à pointillés »): the label in Plex
/// Sans ink2, dots on the baseline, the value in Plex Mono 13/700.
struct PaperworkLedgerLine: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.ink

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(label)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            PaperworkDots()
                .frame(minWidth: 12)
            Text(value)
                .font(Trace.Fonts.data)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.vertical, Trace.Spacing.s)
        .frame(minHeight: Trace.Height.hit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(label), \(value)"))
    }
}

/// A form's header on its sheet: a Plex Mono kicker, the title in Newsreader, the 1.5 pt ink rule.
struct PaperworkHeader: View {
    var kicker: String? = nil
    var trailing: String? = nil
    let title: String
    var titleID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if kicker != nil || trailing != nil {
                HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.s) {
                    if let kicker {
                        Text(kicker).fieldLabel(Trace.Colors.ink2)
                    }
                    Spacer(minLength: Trace.Spacing.s)
                    if let trailing {
                        Text(trailing)
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.ink2)
                    }
                }
                .padding(.bottom, Trace.Spacing.s)
            }
            Text(title)
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(titleID)
            PaperworkRule(strong: true)
                .padding(.top, Trace.Spacing.m + 2)
        }
    }
}

// MARK: - Archived report (« Voir le rapport »)

/// The report of a closed (or revealed) case, read-only (V4 §3 ClosingReport, filed): « ‹ Archives »
/// on the desk, then one paper sheet — RAPPORT DE CLÔTURE and the number, the title, the RÉSOLU /
/// NON RÉSOLU stamp, the figures of the attempt with dotted leaders, then the reconstruction.
struct ArchivedCaseView: View {
    let caseFile: CaseFile
    let attempt: Attempt
    let onClose: () -> Void
    /// « ‹ Archives » by default.
    var backTitle: String? = nil

    private static let stampWidth: CGFloat = 132
    private static let stampAngle: Double = -9

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackLink(title: backTitle ?? L10n.t("tab.archives"), identifier: "archived.back", action: onClose)
                .padding(.horizontal, Paperwork.deskMargin)
            ScrollView {
                sheet
                    .padding(.horizontal, Paperwork.deskMargin)
                    .padding(.top, Trace.Spacing.s)
                    .padding(.bottom, Trace.Spacing.xxl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(DeskBackdrop())
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaperworkHeader(kicker: L10n.t("report.title"), trailing: fileLabel(caseFile.number),
                            title: caseFile.title.capitalizedFirst, titleID: "archived.title")
            StampImage(asset: attempt.solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque",
                       label: L10n.t(attempt.solved ? "case.state.solved" : "case.state.unsolved"),
                       width: Self.stampWidth, angle: Self.stampAngle,
                       color: attempt.solved ? Trace.Colors.red : Trace.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, Trace.Spacing.m)
            VStack(spacing: 0) {
                PaperworkLedgerLine(label: L10n.t("report.date"), value: attempt.date.formatted(date: .abbreviated, time: .omitted))
                PaperworkLedgerLine(label: L10n.t("report.keyFound"), value: "\(attempt.found)/\(attempt.total)")
                PaperworkLedgerLine(label: L10n.t("report.hints"), value: "\(attempt.hintsUsed)")
                PaperworkLedgerLine(label: L10n.t("result.colMark"),
                                    value: attempt.ranked ? "\(attempt.score)/100" : L10n.t("archive.unranked"))
            }
            .padding(.top, Trace.Spacing.s)
            reconstruction
                .padding(.top, Trace.Spacing.xxl)
        }
        .padding(Paperwork.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper()
    }

    private var reconstruction: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            Text(L10n.t("report.reconstruction"))
                .fieldLabel(Trace.Colors.ink2)
                .accessibilityAddTraits(.isHeader)
            Text(caseFile.solution.headline)
                .font(Trace.Fonts.headline)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(caseFile.solution.summary)
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            RevealTimeline(steps: caseFile.solution.reveal,
                           found: Set(caseFile.solution.reveal.compactMap(\.evidence)),
                           shown: caseFile.solution.reveal.count,
                           onPaper: true)
                .padding(.top, Trace.Spacing.xs)
            ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Settings

/// Paramètres (V4): « ‹ Enquêteur » on the desk, then one paper form — the title in Newsreader over
/// a 1.5 pt ink rule, groups under Plex Mono labels, rows of 50 pt separated by thin ink rules:
/// sound and vibrations, accessibility (« Réduire les animations », « Temps détendu »), help
/// (« Réinitialiser les conseils ») and « À propos » (the only place with the logo tile outside the
/// launch). Switches in ink, as on a light sheet.
struct GameSettingsView: View {
    let onBack: () -> Void
    /// « ‹ Enquêteur » by default.
    var backTitle: String? = nil
    @AppStorage(Preferences.soundsKey) private var sounds = true
    @AppStorage(Preferences.vibrationsKey) private var vibrations = true
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    @AppStorage(Preferences.relaxedTimeKey) private var relaxedTime = false
    @State private var tipsReset = false
    @State private var showingAbout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackLink(title: backTitle ?? L10n.t("tab.investigator"), identifier: "settings.back", action: onBack)
                .padding(.horizontal, Paperwork.deskMargin)
            ScrollView {
                VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
                    PaperworkHeader(title: L10n.t("menu.settings"), titleID: "settings.title")
                    group(L10n.t("settings.soundGroup")) {
                        toggle(L10n.t("settings.soundEffects"), $sounds, id: "settings.sounds")
                        toggle(L10n.t("settings.vibrations"), $vibrations, id: "settings.vibrations")
                    }
                    group(L10n.t("settings.accessibilityGroup")) {
                        toggle(L10n.t("settings.reduceMotion"), $reduceMotion, id: "settings.reduceMotion")
                        toggle(L10n.t("settings.relaxedTime"), $relaxedTime, detail: L10n.t("settings.relaxedTimeDetail"),
                               id: "settings.relaxedTime")
                    }
                    group(L10n.t("settings.helpGroup")) {
                        row(L10n.t("settings.replayTutorial"), id: "settings.replayTutorial", divider: !tipsReset) { resetTips() }
                        if tipsReset {
                            Text(verbatim: "✓ " + L10n.t("settings.replayTutorialDone"))
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.green)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, Trace.Spacing.m)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .bottom) { PaperworkRule() }
                                .transition(.opacity)
                        }
                        row(L10n.t("settings.about"), id: "settings.about") { showingAbout = true }
                    }
                }
                .padding(Paperwork.sheetPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paper()
                .padding(.horizontal, Paperwork.deskMargin)
                .padding(.top, Trace.Spacing.s)
                .padding(.bottom, Trace.Spacing.xxl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(DeskBackdrop())
        .sheet(isPresented: $showingAbout) {
            AboutSheet(onClose: { showingAbout = false })
        }
    }

    /// « Réinitialiser les conseils »: every help bubble (tip) shows again, once.
    private func resetTips() {
        TutorialCoach.replay()
        withAnimation(.easeOut(duration: 0.2)) { tipsReset = true }
        UIAccessibility.post(notification: .announcement, argument: L10n.t("settings.replayTutorialDone"))
    }

    /// A Plex Mono label, then the rows, each closed by a thin ink rule.
    private func group<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .fieldLabel(Trace.Colors.ink2)
                .padding(.bottom, Trace.Spacing.xs)
                .accessibilityAddTraits(.isHeader)
            PaperworkRule()
            content()
        }
    }

    private func toggle(_ title: String, _ value: Binding<Bool>, detail: String? = nil, id: String) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Trace.Colors.ink)
        // A light sheet: the switch's « off » track as on paper, whatever the system appearance.
        .environment(\.colorScheme, .light)
        .padding(.vertical, Trace.Spacing.s)
        .frame(minHeight: Paperwork.rowHeight)
        .overlay(alignment: .bottom) { PaperworkRule() }
        .accessibilityIdentifier(id)
    }

    private func row(_ title: String, id: String, divider: Bool = true, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Trace.Colors.ink2)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Paperwork.rowHeight)
            .overlay(alignment: .bottom) { if divider { PaperworkRule() } }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier(id)
    }
}

/// Paramètres › À propos (V4): a paper sheet — the logo tile (96 pt) laid on it like a print, the
/// studio, the version, the photo credits.
private struct AboutSheet: View {
    let onClose: () -> Void
    @State private var showingCredits = false

    private static let studio = "NOREL GAMES"
    private static let tile: CGFloat = 96

    var body: some View {
        VStack(spacing: Trace.Spacing.m) {
            Spacer(minLength: Trace.Spacing.xxl)
            LogoTile(size: Self.tile)
                .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
                .padding(.bottom, Trace.Spacing.m)
            Text(verbatim: Self.studio)
                .font(Trace.Fonts.data)
                .tracking(2)
                .foregroundStyle(Trace.Colors.ink)
            Text(Self.version)
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink2)
                .accessibilityIdentifier("about.version")
            if PhotoCredits.bundled != nil {
                Button(L10n.t("credits.button")) { showingCredits = true }
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .accessibilityIdentifier("about.photoCredits")
            }
            Spacer(minLength: Trace.Spacing.xxl)
            Button(L10n.t("a11y.close"), action: onClose)
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("about.close")
        }
        .padding(.horizontal, Paperwork.sheetPadding)
        .padding(.bottom, Trace.Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Trace.Radius.sheet)
        .presentationBackground(Trace.Colors.paper)
        .sheet(isPresented: $showingCredits) {
            if let credits = PhotoCredits.bundled {
                PhotoCreditsView(credits: credits, onClose: { showingCredits = false })
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.paper)
            }
        }
    }

    /// « Version 1.2 (34) » from the app bundle.
    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return L10n.f("settings.version", "\(short) (\(build))")
    }
}
#endif
