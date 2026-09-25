#if os(iOS)
import SwiftUI
import CaseEngine

// Desk screens that are not the Bureau, the Archives or the case folder (see DeskScreens.swift and
// DossierView.swift): the level boxes of the case form, the archived reconstruction, the settings.

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

/// Réglages: a paper form on the desk.
struct GameSettingsView: View {
    let onBack: () -> Void
    let onReplayOnboarding: () -> Void
    @AppStorage(Preferences.vibrationsKey) private var vibrations = true
    @AppStorage(Preferences.soundsKey) private var sounds = true
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    @AppStorage(Preferences.legibleHandwritingKey) private var legible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward").font(.system(size: 15, weight: .semibold))
                    Text(L10n.t("tab.investigator")).font(.custom(Theme.FontName.regular, size: 17))
                }
                .foregroundStyle(Trace.Colors.bone).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            Text(L10n.t("menu.settings")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
            VStack(alignment: .leading, spacing: 0) {
                section(L10n.t("settings.soundGroup"))
                toggle(L10n.t("settings.sounds"), $sounds)
                toggle(L10n.t("settings.vibrations"), $vibrations)
                section(L10n.t("settings.accessibilityGroup"))
                toggle(L10n.t("settings.reduceMotion"), $reduceMotion)
                toggle(L10n.t("settings.legibleHandwriting"), $legible)
                section(L10n.t("settings.helpGroup"))
                Button(action: onReplayOnboarding) {
                    HStack {
                        Text(L10n.t("settings.replayOnboarding")).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Trace.Colors.inkSoft)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.replayOnboarding")
            }
            .padding(18)
            .paper(Trace.Colors.paper)
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(TraceDesk())
    }

    private func section(_ title: String) -> some View {
        Text(title).fieldLabel().padding(.top, 14).padding(.bottom, 4)
    }

    private func toggle(_ title: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Text(title).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
        }
        .tint(Trace.Colors.stamp)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
    }
}
#endif
