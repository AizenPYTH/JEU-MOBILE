#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// Desk screens that are not the Bureau, the Archives, the profile or the case folder (see
// DeskScreens.swift and DossierView.swift): the level boxes of the case form, the archived
// reconstruction, the settings and « À propos ».

/// "001" style case number.
func caseNumber(_ n: Int) -> String { dossierNumber(n) }

// MARK: - Level box (on the case form)

/// One challenge level as a line of the case form: a box to tick, the level, what it is for, its
/// duration, and the player's best result there (or « non tentée », or locked).
struct ChallengeCard: View {
    let level: Challenge
    let seconds: Int
    let progress: LevelProgress?
    let locked: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.4).frame(width: 18, height: 18)
                    if selected {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(Trace.Colors.pen)
                    } else if locked {
                        Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(Trace.Colors.inkFaint)
                    }
                }
                .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.t("challenge.\(level.rawValue)").uppercased())
                            .font(Trace.Fonts.fieldValueLarge).tracking(1.2).foregroundStyle(Trace.Colors.ink)
                        Spacer()
                        Text(PhoneFormat.countdown(Double(seconds))).font(Trace.Fonts.fieldValueLarge).foregroundStyle(Trace.Colors.ink)
                    }
                    Text(L10n.t("challenge.\(level.rawValue)Pitch")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
                    status
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(selected ? Trace.Colors.highlight : .clear)
            .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
            .opacity(locked ? 0.5 : 1)
            .contentShape(Rectangle())
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
            Text(L10n.t("challenge.locked")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint)
        } else if let progress, progress.solved {
            HStack(spacing: 8) {
                StampMark(text: L10n.t("challenge.solved"), size: 8, angle: -3)
                if let time = progress.bestTime { Text(PhoneFormat.countdown(Double(time))).foregroundStyle(Trace.Colors.ink) }
                if let score = progress.bestScore { Text("\(score) / 100").foregroundStyle(Trace.Colors.ink) }
            }
            .font(Trace.Fonts.monoSmall.weight(.semibold))
            .padding(.top, 2)
        } else if let progress, progress.plays > 0 {
            Text(L10n.f("challenge.tried", progress.plays)).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
        } else {
            Text(L10n.t("challenge.untried")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint)
        }
    }
}

// MARK: - Archived reconstruction

/// The reconstruction of a closed (or revealed) case, read-only, as a typed report.
struct ArchivedCaseView: View {
    let caseFile: CaseFile
    let attempt: Attempt
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward").font(.system(size: 15, weight: .semibold))
                    Text(L10n.t("tab.archives")).font(.custom(Theme.FontName.regular, size: 17))
                }
                .foregroundStyle(Trace.Colors.bone).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.f("dossier.numberLong", dossierNumber(caseFile.number))).fieldLabel(Trace.Colors.stamp)
                    Text(caseFile.solution.headline).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    Text(caseFile.solution.summary).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.inkSoft)
                    RevealTimeline(steps: caseFile.solution.reveal, found: Set(caseFile.solution.reveal.compactMap(\.evidence)), shown: caseFile.solution.reveal.count)
                    ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                    }
                }
                .padding(20)
                .paper(Trace.Colors.paper)
                .padding(.horizontal, 10)
                .padding(.bottom, 24)
            }
        }
        .background(TraceDesk())
    }
}

// MARK: - Settings

/// Paramètres: one paper form on the desk, one column, rows of at least 44 pt. Sound, vibrations,
/// accessibility (« Réduire les animations », legible handwriting, « Temps détendu »), « Revoir le
/// tutoriel », and « À propos » — the only place with the logo tile outside the title screens.
struct GameSettingsView: View {
    let onBack: () -> Void
    @AppStorage(Preferences.soundsKey) private var sounds = true
    @AppStorage(Preferences.vibrationsKey) private var vibrations = true
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    @AppStorage(Preferences.legibleHandwritingKey) private var legible = false
    @AppStorage(Preferences.relaxedTimeKey) private var relaxedTime = false
    @State private var tutorialReplayed = false
    @State private var showingAbout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward").font(.system(size: 15, weight: .semibold))
                    Text(L10n.t("common.back")).font(Trace.Fonts.uiBody)
                }
                .foregroundStyle(Trace.Colors.bone)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("settings.back")
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L10n.t("menu.settings"))
                        .font(Trace.Fonts.serifTitle(28))
                        .foregroundStyle(Trace.Colors.bone)
                        .accessibilityAddTraits(.isHeader)
                    form
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(DeskBackdrop())
        .sheet(isPresented: $showingAbout) {
            AboutSheet(onClose: { showingAbout = false })
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            section(L10n.t("settings.soundGroup"))
            toggle(L10n.t("settings.soundEffects"), $sounds, id: "settings.sounds")
            toggle(L10n.t("settings.vibrations"), $vibrations, id: "settings.vibrations")
            section(L10n.t("settings.accessibilityGroup"))
            toggle(L10n.t("settings.reduceMotion"), $reduceMotion, id: "settings.reduceMotion")
            toggle(L10n.t("settings.legibleHandwriting"), $legible, id: "settings.legibleHandwriting")
            toggle(L10n.t("settings.relaxedTime"), $relaxedTime, detail: L10n.t("settings.relaxedTimeDetail"),
                   id: "settings.relaxedTime")
            section(L10n.t("settings.helpGroup"))
            row(L10n.t("settings.replayTutorial"), id: "settings.replayTutorial") { replayTutorial() }
            if tutorialReplayed {
                Text(L10n.t("settings.replayTutorialDone"))
                    .font(Trace.Fonts.proseSmall)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .transition(.opacity)
            }
            row(L10n.t("settings.about"), id: "settings.about") { showingAbout = true }
        }
        .padding(18)
        .paper(Trace.Colors.paper)
    }

    /// The three help bubbles come back on the next play of case #001.
    private func replayTutorial() {
        TutorialCoach.replay()
        withAnimation(.easeOut(duration: 0.2)) { tutorialReplayed = true }
        UIAccessibility.post(notification: .announcement, argument: L10n.t("settings.replayTutorialDone"))
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .fieldLabel()
            .padding(.top, 14)
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func toggle(_ title: String, _ value: Binding<Bool>, detail: String? = nil, id: String) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(Trace.Fonts.proseSmall)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Trace.Colors.stamp)
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
        .accessibilityIdentifier(id)
    }

    private func row(_ title: String, id: String, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 48)
            .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

/// Paramètres › À propos: the logo tile (96 pt) on the dark desk, the studio, the version.
private struct AboutSheet: View {
    let onClose: () -> Void

    private static let studio = "NOREL GAMES"

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 24)
            LogoTile(size: 96)
                .padding(.bottom, 10)
            Text(verbatim: Self.studio)
                .font(Trace.Fonts.kicker)
                .tracking(3)
                .foregroundStyle(Trace.Colors.bone)
            Text(Self.version)
                .font(Trace.Fonts.mono)
                .foregroundStyle(Trace.Colors.bone2)
                .accessibilityIdentifier("about.version")
            Spacer(minLength: 24)
            Button(L10n.t("a11y.close"), action: onClose)
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("about.close")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeskBackdrop())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Trace.Colors.launch)
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
