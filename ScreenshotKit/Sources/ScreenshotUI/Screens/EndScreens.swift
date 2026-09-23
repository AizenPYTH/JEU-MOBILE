#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 31 · Time's up

/// Content fades out, the timer lands in the centre (mono 88, red), "Le téléphone se verrouille.",
/// a 1.8 s bar, then the accusation.
struct TimeUpView: View {
    let onDone: () -> Void
    @State private var progress: CGFloat = 0
    @State private var shown = false

    var body: some View {
        VStack(spacing: Theme.Spacing.s5) {
            Spacer()
            Text("00:00")
                .font(Theme.Fonts.timerTimeUp)
                .tracking(-4)
                .foregroundStyle(Theme.Colors.alertText)
                .scaleEffect(shown ? 1 : 0.4)
            Text(L10n.t("timeUp.title"))
                .font(Theme.Fonts.overline)
                .tracking(Theme.Tracking.timeUp)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(L10n.t("timeUp.subtitle")).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
            GeometryReader { geo in
                Capsule().fill(Theme.Colors.line2)
                    .overlay(alignment: .leading) { Capsule().fill(Theme.Colors.textPrimary).frame(width: geo.size.width * progress) }
            }
            .frame(width: 160, height: 2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .task {
            withAnimation(Theme.Motion.dramatic(0.74)) { shown = true }
            withAnimation(.linear(duration: Theme.Motion.timeUpHold)) { progress = 1 }
            try? await Task.sleep(for: .seconds(Theme.Motion.timeUpHold + 0.3))
            onDone()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 32 · Accusation

/// The decision: "Qui est responsable ?". One suspect is chosen from a clear list; a panel then
/// states who is accused and on what the player's case rests (the items they linked), and the
/// accusation is confirmed by holding the button (900 ms).
struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?
    @State private var fileOpen: SuspectID?

    var body: some View {
        let game = session.game
        let timeLeft = session.remainingSeconds > 0
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    HStack {
                        Text(L10n.t("accuse.overline")).overline(Theme.Colors.special)
                        Spacer()
                        Text(timeLeft ? L10n.f("accuse.timeLeft", PhoneFormat.countdown(session.remainingSeconds)) : L10n.t("accuse.timeUp"))
                            .font(Theme.Fonts.dataStrong)
                            .foregroundStyle(timeLeft ? Theme.Colors.signal : Theme.Colors.alertText)
                    }
                    Text(L10n.t("accuse.title")).font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
                    Text(L10n.t("accuse.instruction")).font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.s7)

                ObjectiveCard(objective: session.caseFile.objective)

                VStack(spacing: Theme.Spacing.s3) {
                    ForEach(session.caseFile.suspects) { suspect in
                        suspectRow(suspect, game: game)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.marginGame)
            .padding(.bottom, Theme.Spacing.s5)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            decisionPanel(game: game, timeLeft: timeLeft)
        }
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .animation(Theme.Motion.emphasized(0.3), value: selected)
        .sheet(item: Binding(get: { fileOpen.map(SuspectSheetID.init) }, set: { fileOpen = $0?.id })) { item in
            NavigationStack { SuspectFileView(suspectID: item.id, session: session) }
                .presentationBackground(Theme.Colors.ink0)
        }
    }

    private func suspectRow(_ suspect: Suspect, game: Investigation) -> some View {
        let isSelected = selected == suspect.id
        let linked = game.linkedEntries(for: suspect.id).count
        let marks = SuspectMark.allCases.filter { game.marks[suspect.id]?.contains($0) == true }
        return HStack(spacing: 0) {
            Button {
                selected = suspect.id
                Haptics.selection()
            } label: {
                HStack(spacing: Theme.Spacing.s4) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Theme.Colors.special : Theme.Colors.textTertiary)
                    Portrait(contact: game.contact(suspect.contact), width: 56, height: 64)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                        Text(suspect.role).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(2)
                        HStack(spacing: Theme.Spacing.s2) {
                            Chip(text: L10n.f("carnet.linked", linked), color: linked > 0 ? Theme.Colors.special : Theme.Colors.textTertiary)
                            if !marks.isEmpty {
                                Chip(text: L10n.f("carnet.marksCount", marks.count), color: Theme.Colors.signal)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, Theme.Spacing.s4)
                .padding(.leading, Theme.Spacing.s4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("accuse.suspect.\(suspect.id)")

            Button { fileOpen = suspect.id } label: {
                VStack(spacing: 2) {
                    Image(systemName: "folder").font(.system(size: 16, weight: .semibold))
                    Text(L10n.t("accuse.file")).font(Theme.Fonts.caption)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 64)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.f("accuse.fileA11y", game.name(of: suspect.contact))))
        }
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            .fill(isSelected ? Theme.Colors.specialTint : Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            .strokeBorder(isSelected ? Theme.Colors.special : Theme.Colors.line1, lineWidth: isSelected ? 2 : 1))
        .opacity(selected == nil || isSelected ? 1 : 0.65)
    }

    /// Bottom panel: who is accused, what the case rests on, then hold to accuse.
    private func decisionPanel(game: Investigation, timeLeft: Bool) -> some View {
        let suspect = selected.flatMap { id in session.caseFile.suspects.first { $0.id == id } }
        let name = suspect.map { game.name(of: $0.contact) } ?? ""
        let evidence = suspect.map { s in game.linkedEntries(for: s.id).map { ItemDescriber.describe($0.ref, in: game) } } ?? []
        return VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            if suspect != nil {
                Text(L10n.f("accuse.youAccuse", name)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("accuse.youAccuse")
                if evidence.isEmpty {
                    Label(L10n.t("accuse.noEvidence"), systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.signal)
                } else {
                    Text(L10n.f("accuse.basedOn", evidence.count)).overline(Theme.Colors.special)
                    ForEach(Array(evidence.prefix(3).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: Theme.Spacing.s3) {
                            AppTileGlyph(app: item.app, size: 18)
                            Text(item.label).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                        }
                    }
                    if evidence.count > 3 {
                        Text(L10n.f("accuse.more", evidence.count - 3)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            } else {
                Text(L10n.t("accuse.pickFirst")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            }
            HoldToConfirmButton(title: L10n.f("accuse.holdName", name), disabledTitle: L10n.t("accuse.select"), enabled: selected != nil) {
                if let selected { session.accuse(selected) }
            }
            .accessibilityIdentifier("accuse.hold")
            if timeLeft {
                Button(L10n.t("accuse.back")) { session.resumeInvestigation() }
                    .buttonStyle(TertiaryButtonStyle())
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .padding(.top, Theme.Spacing.s4)
        .padding(.bottom, Theme.Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.bgSurface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Theme.Colors.line2).frame(height: 1) }
    }
}

struct SuspectSheetID: Identifiable {
    let id: SuspectID
}

// MARK: - 33 / 34 · Result

struct ResultView: View {
    let verdict: Verdict
    let caseFile: CaseFile
    let names: [SuspectID: String]
    let onScore: () -> Void
    let onReplay: () -> Void
    let onRevealRequested: () -> Void
    /// Solution shown after a wrong answer: the attempt is not ranked.
    var revealed = false
    /// What the player's accusation rested on: the items they linked to the accused.
    var accusedEvidence: [String] = []
    /// The culprit's contact (portrait on the solution).
    var culprit: Contact? = nil

    @State private var shownSteps = 0
    @State private var confirmReveal = false

    var body: some View {
        let solved = verdict.isCorrect
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                badge(solved: solved)
                    .padding(.top, Theme.Spacing.s7)

                if solved || revealed {
                    solution(solved: solved)
                } else {
                    wrongAnswer
                }
            }
            .padding(.horizontal, Theme.Spacing.marginGame)
            .padding(.bottom, Theme.Spacing.s8)
        }
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .task(id: revealed) {
            guard verdict.isCorrect || revealed else { return }
            shownSteps = 0
            for step in 1...max(1, caseFile.solution.reveal.count) {
                try? await Task.sleep(for: .seconds(Theme.Motion.revealStep))
                withAnimation(Theme.Motion.emphasized(Theme.Motion.revealStep)) { shownSteps = step }
            }
        }
        .onTapGesture { shownSteps = caseFile.solution.reveal.count }
        .confirmationDialog(L10n.t("result.revealConfirmTitle"), isPresented: $confirmReveal, titleVisibility: .visible) {
            Button(L10n.t("result.reveal"), role: .destructive, action: onRevealRequested)
        } message: {
            Text(L10n.t("result.revealConfirm"))
        }
    }

    private func badge(solved: Bool) -> some View {
        let color = solved ? Theme.Colors.clear : (revealed ? Theme.Colors.textSecondary : Theme.Colors.alertText)
        return Text(solved ? L10n.t("result.solvedBadge") : (revealed ? L10n.t("result.revealedBadge") : L10n.t("result.unsolvedBadge")))
            .font(Theme.Fonts.overline)
            .tracking(Theme.Tracking.overline)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.s4)
            .frame(height: 30)
            .background(Capsule().fill(color.opacity(0.12)))
            .overlay(Capsule().strokeBorder(color.opacity(0.5)))
    }

    /// Who did it, why (the key evidence, found ✓ or missed ○, with what each one proves),
    /// what the player's accusation rested on, then the reconstruction step by step.
    @ViewBuilder
    private func solution(solved: Bool) -> some View {
        let culpritName = names[verdict.culprit] ?? ""
        let key = caseFile.evidence.filter { $0.importance == .key }
        HStack(alignment: .center, spacing: Theme.Spacing.s4) {
            Portrait(contact: culprit, width: 64, height: 76)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(solved ? Theme.Colors.clear : Theme.Colors.line3, lineWidth: 2))
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(L10n.t("result.culpritOverline")).overline(Theme.Colors.special)
                Text(L10n.f("result.culpritWas", culpritName))
                    .font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(caseFile.solution.headline).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
            Text(caseFile.solution.summary).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
        }

        if !key.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.f("result.keyEvidence", key.count)).overline(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("result.keyEvidence")
                ForEach(key) { evidence in
                    KeyEvidenceRow(evidence: evidence, found: verdict.foundEvidenceIDs.contains(evidence.id))
                }
            }
        }

        if solved {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.t("result.yourCase")).overline(Theme.Colors.special)
                if accusedEvidence.isEmpty {
                    Text(L10n.t("result.yourCaseEmpty")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(Array(accusedEvidence.enumerated()), id: \.offset) { _, label in
                        Text("→ " + label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(2)
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Text(L10n.t("result.timeline")).overline(Theme.Colors.info)
            RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs, shown: shownSteps)
        }

        Button(revealed ? L10n.t("result.replay") : L10n.t("result.seeScore"), action: revealed ? onReplay : onScore)
            .buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
            .accessibilityIdentifier("result.primary")
            .opacity(shownSteps >= caseFile.solution.reveal.count ? 1 : 0.4)
    }

    private var wrongAnswer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                Text(L10n.f("result.wrongTitle", names[verdict.accused] ?? ""))
                    .font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
                Text(L10n.t("result.wrongSubtitle")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            }
            if let alibi = verdict.alibi {
                ResultCard(overline: L10n.t("result.alibi"), text: alibi, detail: verdict.alibiEvidence.map { $0.title },
                           symbol: "checkmark.shield.fill", color: Theme.Colors.clear)
            }
            if let trap = verdict.trap {
                ResultCard(overline: L10n.t("result.trap"), text: trap, detail: nil,
                           symbol: "exclamationmark.triangle.fill", color: Theme.Colors.signal)
            }
            if !verdict.foundAboutAccused.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    Text(L10n.t("result.youFoundRight")).overline(Theme.Colors.clear)
                    ForEach(verdict.foundAboutAccused) { evidence in
                        Label(evidence.title, systemImage: "checkmark.circle.fill")
                            .font(Theme.Fonts.callout)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.f("result.missed", verdict.missed.count)).overline()
                ForEach(verdict.missedByApp.sorted { $0.value > $1.value }, id: \.key) { app, count in
                    HStack(spacing: Theme.Spacing.s3) {
                        AppTileGlyph(app: app, size: 26)
                        Text(app.title).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text(L10n.f("result.missedCount", count)).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            Button(L10n.t("result.replay"), action: onReplay).buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("result.replay")
            Button(L10n.t("result.reveal")) { confirmReveal = true }
                .accessibilityIdentifier("result.reveal")
                .buttonStyle(TertiaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }
}

/// One decisive piece of evidence: ✓ found / ○ missed, its title, and what it really proves.
struct KeyEvidenceRow: View {
    let evidence: Evidence
    let found: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            Image(systemName: found ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 20))
                .foregroundStyle(found ? Theme.Colors.clear : Theme.Colors.textTertiary)
            VStack(alignment: .leading, spacing: 3) {
                Text(evidence.title).font(Theme.Fonts.calloutStrong).foregroundStyle(Theme.Colors.textPrimary)
                Text(evidence.meaning).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(found ? L10n.t("result.keyFound") : L10n.t("result.keyMissed"))
                    .font(Theme.Fonts.dataSmall)
                    .foregroundStyle(found ? Theme.Colors.clear : Theme.Colors.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.s4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(found ? Theme.Colors.clearTint : Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .strokeBorder(found ? Theme.Colors.clear.opacity(0.4) : Theme.Colors.line1))
        .accessibilityElement(children: .combine)
    }
}

struct ResultCard: View {
    let overline: String
    let text: String
    let detail: String?
    var symbol: String = "info.circle.fill"
    var color: Color = Theme.Colors.textSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Label(overline, systemImage: symbol).overline(color)
            Text(text).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textPrimary)
            if let detail { Text("◆ " + detail).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.signal) }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3).padding(.vertical, Theme.Spacing.s5)
        }
        .elevation0(Theme.Radius.lg)
    }
}

/// RevealTimeline: found (filled dot) · missed (empty circle); a vertical 1 pt line that draws itself.
struct RevealTimeline: View {
    let steps: [RevealStep]
    let found: Set<String>
    let shown: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                let isFound = step.evidence.map { found.contains($0) } ?? true
                HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isFound ? Theme.Colors.clear : .clear)
                            .overlay(Circle().strokeBorder(isFound ? Theme.Colors.clear : Theme.Colors.textSecondary, lineWidth: 1.5))
                            .frame(width: 11, height: 11)
                            .padding(.top, 4)
                        if offset < steps.count - 1 {
                            Rectangle().fill(Theme.Colors.line3).frame(width: 1).frame(minHeight: 30)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(PhoneFormat.time(step.at)).font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.textPrimary)
                        Text(step.text).font(Theme.Fonts.callout).foregroundStyle(isFound ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                        if !isFound { Text(L10n.t("result.notFound")).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary) }
                    }
                    .padding(.bottom, Theme.Spacing.s5)
                }
                .opacity(offset < shown ? 1 : 0)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text((isFound ? L10n.t("a11y.found") : L10n.t("a11y.missed")) + ", \(PhoneFormat.time(step.at)), \(step.text)"))
            }
        }
    }
}

// MARK: - 35 · Score

struct ScoreView: View {
    let verdict: Verdict
    let duration: Int
    let onReplay: () -> Void
    let onNext: () -> Void
    @State private var displayed = 0
    @State private var rows = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
            Text(verdict.isPerfect ? L10n.t("score.perfect") : L10n.t("score.overline"))
                .overline(verdict.isPerfect ? Theme.Colors.signal : Theme.Colors.textSecondary)
                .padding(.top, Theme.Spacing.s8)
            Text("\(displayed)%")
                .font(Theme.Fonts.timerScore)
                .tracking(-5)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())
                .accessibilityIdentifier("score.value")
            VStack(spacing: 0) {
                scoreRow(0, L10n.t("score.suspect"), verdict.isCorrect ? "✓ +\(verdict.scoreParts.suspect)" : "✕ 0")
                scoreRow(1, L10n.t("score.time"), "\(PhoneFormat.countdown(Double(verdict.remainingSeconds))) · +\(verdict.scoreParts.time)")
                scoreRow(2, L10n.t("score.found"), "\(verdict.foundCount)/\(verdict.totalCount) · +\(verdict.scoreParts.found)")
                scoreRow(3, L10n.t("score.hints"), "\(verdict.hintsUsed) · −\(verdict.hintCost)")
                scoreRow(4, L10n.t("score.precision"), "\(verdict.relevantPinnedCount)/\(verdict.pinnedCount) · +\(verdict.scoreParts.precision)")
            }
            Spacer()
            HStack(spacing: Theme.Spacing.s3) {
                Button(L10n.t("result.replay"), action: onReplay).buttonStyle(SecondaryButtonStyle())
                Button(L10n.t("score.next"), action: onNext).buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                    .accessibilityIdentifier("score.next")
            }
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .padding(.bottom, Theme.Spacing.s5)
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .task {
            let target = verdict.score
            let steps = 30
            for i in 1...steps {
                try? await Task.sleep(for: .milliseconds(30))
                displayed = target * i / steps
            }
            for i in 1...5 {
                try? await Task.sleep(for: .milliseconds(60))
                withAnimation(Theme.Motion.emphasized(0.3)) { rows = i }
            }
        }
    }

    private func scoreRow(_ index: Int, _ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.textPrimary)
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line1).frame(height: 1) }
        .opacity(index < rows ? 1 : 0)
        .offset(y: index < rows ? 0 : 8)
    }
}
#endif
