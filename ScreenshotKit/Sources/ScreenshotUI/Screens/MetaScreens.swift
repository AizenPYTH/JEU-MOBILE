#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// BEN screens that are not the Bureau, the Archives, the profile or the case file (see
// DeskScreens.swift and DossierView.swift): the level rows of the case file, the archived
// reconstruction, the settings and « À propos ». UX V3: flat surfaces, V3 components.

/// "001" style case number.
func caseNumber(_ n: Int) -> String { shownNumber(n) }

// MARK: - Level row (in the case file)

/// One challenge level: a radio, the level, what it is for, its duration, and the player's best
/// result there (or « non tentée », or locked). Selected: ben rule and tint.
struct ChallengeCard: View {
    let level: Challenge
    let seconds: Int
    let progress: LevelProgress?
    let locked: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().strokeBorder(selected ? Trace.Colors.ben : Trace.Colors.text3, lineWidth: 2)
                    if selected {
                        Circle().fill(Trace.Colors.ben).frame(width: 10, height: 10)
                    } else if locked {
                        Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(Trace.Colors.text3)
                    }
                }
                .frame(width: 20, height: 20)
                .padding(.top, 1)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.t("challenge.\(level.rawValue)"))
                            .font(Trace.Fonts.monoStrong)
                            .foregroundStyle(Trace.Colors.text)
                        Spacer()
                        Text(PhoneFormat.countdown(Double(seconds)))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.text)
                    }
                    Text(L10n.t("challenge.\(level.rawValue)Pitch"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    status
                }
            }
            .padding(12)
            .background(shape.fill(selected ? Trace.Colors.tint(Trace.Colors.ben) : Trace.Colors.surface))
            .overlay(shape.strokeBorder(selected ? Trace.Colors.ben : Trace.Colors.line, lineWidth: selected ? 2 : 1))
            .opacity(locked ? 0.6 : 1)
            .contentShape(shape)
        }
        .buttonStyle(PressableStyle())
        .disabled(locked)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("challenge.\(level.rawValue)")
    }

    @ViewBuilder
    private var status: some View {
        if locked {
            Text(L10n.t("challenge.locked"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
        } else if let progress, progress.solved {
            HStack(spacing: 8) {
                StatusBadge(text: L10n.t("challenge.solved"), color: Trace.Colors.successText, symbol: "✓")
                if let time = progress.bestTime { Text(PhoneFormat.countdown(Double(time))) }
                if let score = progress.bestScore { Text(verbatim: "\(score)/100") }
            }
            .font(Trace.Fonts.data)
            .foregroundStyle(Trace.Colors.text)
            .padding(.top, 2)
        } else if let progress, progress.plays > 0 {
            Text(L10n.f("challenge.tried", progress.plays))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
        } else {
            Text(L10n.t("challenge.untried"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
        }
    }
}

// MARK: - Archived reconstruction (« Voir le rapport »)

/// The report of a closed (or revealed) case, read-only: the result, the data of the attempt, then
/// the reconstruction.
struct ArchivedCaseView: View {
    let caseFile: CaseFile
    let attempt: Attempt
    let onClose: () -> Void
    /// « ‹ Archives » by default.
    var backTitle: String? = nil
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
        VStack(alignment: .leading, spacing: 0) {
            BackLink(title: backTitle ?? L10n.t("tab.archives"), identifier: "archived.back", action: onClose)
                .padding(.horizontal, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    StatusBadge(text: L10n.t(attempt.solved ? "case.state.solved" : "case.state.unsolved"),
                                color: attempt.solved ? Trace.Colors.successText : Trace.Colors.criticalOnDark,
                                symbol: attempt.solved ? "✓" : "✕")
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fileLabel(caseFile.number))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.benText)
                        Text(caseFile.title.capitalizedFirst)
                            .font(Trace.Fonts.title)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("archived.title")
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ReportCard(label: L10n.t("report.date"), value: attempt.date.formatted(date: .abbreviated, time: .omitted))
                        ReportCard(label: L10n.t("report.keyFound"), value: "\(attempt.found)/\(attempt.total)")
                        ReportCard(label: L10n.t("report.hints"), value: "\(attempt.hintsUsed)")
                        ReportCard(label: L10n.t("result.colMark"), value: attempt.ranked ? "\(attempt.score)/100" : L10n.t("archive.unranked"))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: L10n.t("report.reconstruction"))
                        Text(caseFile.solution.headline)
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(caseFile.solution.summary)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        RevealTimeline(steps: caseFile.solution.reveal,
                                       found: Set(caseFile.solution.reveal.compactMap(\.evidence)),
                                       shown: caseFile.solution.reveal.count)
                        ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(Trace.Fonts.body)
                                .foregroundStyle(Trace.Colors.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .benCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(DeskBackdrop())
    }
}

// MARK: - Settings

/// Paramètres: « ‹ Enquêteur », the Newsreader title, then grouped cards with rows of 50 pt —
/// sound and vibrations, accessibility (« Réduire les animations », « Temps détendu »), help
/// (« Réinitialiser les conseils ») and « À propos » (the only place with the logo tile outside the
/// launch).
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BenScreenHeader(back: backTitle ?? L10n.t("tab.investigator"), backID: "settings.back", onBack: onBack,
                                title: L10n.t("menu.settings"), titleID: "settings.title")
                group(L10n.t("settings.soundGroup")) {
                    toggle(L10n.t("settings.soundEffects"), $sounds, id: "settings.sounds")
                    toggle(L10n.t("settings.vibrations"), $vibrations, id: "settings.vibrations", divider: false)
                }
                group(L10n.t("settings.accessibilityGroup")) {
                    toggle(L10n.t("settings.reduceMotion"), $reduceMotion, id: "settings.reduceMotion")
                    toggle(L10n.t("settings.relaxedTime"), $relaxedTime, detail: L10n.t("settings.relaxedTimeDetail"),
                           id: "settings.relaxedTime", divider: false)
                }
                group(L10n.t("settings.helpGroup")) {
                    row(L10n.t("settings.replayTutorial"), id: "settings.replayTutorial") { resetTips() }
                    if tipsReset {
                        Text(L10n.t("settings.replayTutorialDone"))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.successText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }
                    row(L10n.t("settings.about"), id: "settings.about", divider: false) { showingAbout = true }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
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

    private func group<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title)
            VStack(spacing: 0) {
                content()
            }
            .benCard()
        }
    }

    private func toggle(_ title: String, _ value: Binding<Bool>, detail: String? = nil, id: String, divider: Bool = true) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Trace.Colors.ben)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
        }
        .accessibilityIdentifier(id)
    }

    private func row(_ title: String, id: String, divider: Bool = true, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Trace.Colors.text3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: Trace.Height.row)
            .overlay(alignment: .bottom) {
                if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier(id)
    }
}

/// Paramètres › À propos: the logo tile (96 pt), the studio, the version, the photo credits.
private struct AboutSheet: View {
    let onClose: () -> Void
    @State private var showingCredits = false

    private static let studio = "NOREL GAMES"

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 24)
            LogoTile(size: 96)
                .padding(.bottom, 12)
            Text(verbatim: Self.studio)
                .font(Trace.Fonts.data)
                .tracking(2)
                .foregroundStyle(Trace.Colors.text)
            Text(Self.version)
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.text2)
                .accessibilityIdentifier("about.version")
            if PhotoCredits.bundled != nil {
                Button(L10n.t("credits.button")) { showingCredits = true }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("about.photoCredits")
            }
            Spacer(minLength: 24)
            Button(L10n.t("a11y.close"), action: onClose)
                .buttonStyle(CTAButtonStyle(kind: .outline))
                .accessibilityIdentifier("about.close")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeskBackdrop())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Trace.Radius.sheet)
        .presentationBackground(Trace.Colors.bg)
        .sheet(isPresented: $showingCredits) {
            if let credits = PhotoCredits.bundled {
                PhotoCreditsView(credits: credits, onClose: { showingCredits = false })
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.bg)
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
