#if os(iOS)
import SwiftUI
import CaseEngine

/// The game: investigation bar on top (timer, case file, hints, accuse) and the seized phone below.
struct InvestigationView: View {
    let session: GameSession
    @State private var showsFile = false
    @State private var showsHints = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            InvestigationBar(session: session, onFile: { showsFile = true }, onHints: { showsHints = true }) {
                session.requestAccusation()
            }
            PhoneView(session: session)
                .padding(.horizontal, Theme.Spacing.xs)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .sheet(isPresented: $showsFile) {
            SuspectFileView(session: session) {
                showsFile = false
                session.requestAccusation()
            }
            .presentationDetents([.large])
            .presentationBackground(Theme.Colors.surface)
        }
        .sheet(isPresented: $showsHints) {
            HintsView(session: session)
                .presentationDetents([.medium])
                .presentationBackground(Theme.Colors.surface)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: session.resume()
            case .inactive, .background: session.pause()
            @unknown default: break
            }
        }
        .onChange(of: session.phase) { _, phase in
            if phase != .investigating { showsFile = false; showsHints = false }
        }
    }
}

/// Timer + actions. Red and pulsing in the last minute; every time cost flashes "−8 s".
struct InvestigationBar: View {
    let session: GameSession
    let onFile: () -> Void
    let onHints: () -> Void
    let onAccuse: () -> Void

    var body: some View {
        let low = session.remainingSeconds <= Double(session.rules.lowTimeWarningSeconds)
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.f("bar.case", session.caseFile.number))
                    .font(Theme.Fonts.overline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(PhoneFormat.countdown(session.remainingSeconds))
                        .font(Theme.Fonts.timer)
                        .monospacedDigit()
                        .foregroundStyle(low ? Theme.Colors.alert : Theme.Colors.textPrimary)
                        .contentTransition(.numericText(countsDown: true))
                        .phaseAnimator(low ? [1.0, 0.45] : [1.0]) { view, opacity in
                            view.opacity(opacity)
                        }
                    if let cost = session.lastCost {
                        Text(L10n.f("bar.cost", cost.seconds))
                            .font(Theme.Fonts.timerSmall)
                            .foregroundStyle(Theme.Colors.alert)
                            .id(cost.id)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(L10n.f("a11y.timer", PhoneFormat.countdown(session.remainingSeconds))))
            Spacer()
            BarButton(icon: "folder.fill", label: L10n.t("bar.file"), action: onFile)
            BarButton(icon: "lightbulb.fill", label: L10n.t("bar.hint"), action: onHints)
            Button(action: onAccuse) {
                Text(L10n.t("bar.accuse"))
                    .font(Theme.Fonts.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, Theme.Spacing.m)
                    .frame(minHeight: 36)
                    .background(Capsule().fill(Theme.Colors.textPrimary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.xs)
        .animation(Theme.Motion.snappy, value: session.lastCost)
    }
}

struct BarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: Theme.Size.hit, height: Theme.Size.hit)
                .background(Circle().fill(Theme.Colors.surfaceElevated))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - Suspect file

/// The player's own case file: police statements, what they pinned, what they ticked.
/// It never tells the truth — it only organises what the player found.
struct SuspectFileView: View {
    let session: GameSession
    let onAccuse: () -> Void

    var body: some View {
        let game = session.game
        NavigationStack {
            List {
                Section {
                    Text(session.caseFile.objective)
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ForEach(session.caseFile.suspects) { suspect in
                    Section {
                        HStack(spacing: Theme.Spacing.m) {
                            Avatar(contact: game.contact(suspect.contact), size: Theme.Size.avatarM)
                            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline)
                                Text(suspect.role).font(Theme.Fonts.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(L10n.t("file.statement")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                            Text(suspect.statement).font(Theme.Fonts.callout.italic())
                        }
                        ForEach(SuspectMark.allCases, id: \.self) { mark in
                            let on = game.marks[suspect.id]?.contains(mark) == true
                            Button {
                                session.perform { $0.toggle(mark, for: suspect.id) }
                                Haptics.selection()
                            } label: {
                                Label(L10n.t("mark.\(mark.rawValue)"), systemImage: on ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(on ? Theme.Colors.accent : Theme.Colors.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                        let pins = game.pins[suspect.id] ?? []
                        if pins.isEmpty {
                            Text(L10n.t("file.noPins")).font(Theme.Fonts.footnote).foregroundStyle(Theme.Colors.textTertiary)
                        } else {
                            ForEach(pins, id: \.self) { ref in
                                let item = ItemDescriber.describe(ref, in: game)
                                Label(item.text, systemImage: item.icon)
                                    .font(Theme.Fonts.footnote)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            session.perform { $0.unpin(ref, from: suspect.id) }
                                        } label: {
                                            Label(L10n.t("file.unpin"), systemImage: "pin.slash")
                                        }
                                    }
                            }
                        }
                    }
                }
                Section {
                    Button(action: onAccuse) {
                        Text(L10n.t("file.accuse"))
                            .font(Theme.Fonts.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(Theme.Colors.alert)
                } footer: {
                    Text(L10n.t("file.pinHelp"))
                }
            }
            .navigationTitle(L10n.t("file.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Hints

struct HintsView: View {
    let session: GameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text(L10n.t("hints.title")).font(Theme.Fonts.title)
            ForEach(Array(game.usedHints.enumerated()), id: \.element.id) { offset, hint in
                Label(hint.text, systemImage: "lightbulb.fill")
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.warning)
                    .accessibilityLabel(Text(L10n.f("hints.number", offset + 1) + " " + hint.text))
            }
            if let next = game.nextHint {
                Text(L10n.f("hints.costExplain", next.costSeconds))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Button {
                    _ = session.useHint()
                } label: {
                    Text(L10n.f("hints.use", game.usedHints.count + 1, next.costSeconds))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.hit)
                        .background(Capsule().fill(Theme.Colors.warning))
                }
                .buttonStyle(.plain)
            } else {
                Text(L10n.t("hints.none")).foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
}
#endif
