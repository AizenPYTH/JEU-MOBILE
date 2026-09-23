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

struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?
    @State private var fileOpen: SuspectID?

    var body: some View {
        let game = session.game
        let timeLeft = session.remainingSeconds > 0
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(timeLeft ? L10n.f("accuse.timeLeft", PhoneFormat.countdown(session.remainingSeconds)) : L10n.t("accuse.timeUp"))
                    .overline(timeLeft ? Theme.Colors.signal : Theme.Colors.alertText)
                Text(L10n.t("accuse.title")).font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
                Text(session.caseFile.objective).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.top, Theme.Spacing.s7)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(session.caseFile.suspects) { suspect in
                    let isSelected = selected == suspect.id
                    let linked = game.linkedEntries(for: suspect.id).count
                    Button {
                        if isSelected { fileOpen = suspect.id } else { selected = suspect.id; Haptics.selection() }
                    } label: {
                        VStack(spacing: Theme.Spacing.s3) {
                            Portrait(contact: game.contact(suspect.contact), width: 96, height: 96)
                            Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                            Text(suspect.role).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1)
                            Text(L10n.f("carnet.linked", linked)).font(Theme.Fonts.data)
                                .foregroundStyle(linked > 0 ? Theme.Colors.signal : Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Spacing.s5)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .strokeBorder(isSelected ? Theme.Colors.textPrimary : Theme.Colors.line1, lineWidth: isSelected ? 2 : 1))
                        .overlay(alignment: .topTrailing) {
                            if isSelected {
                                Text("✓").font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textOnLight)
                                    .frame(width: 24, height: 24).background(Circle().fill(Theme.Colors.textPrimary)).padding(Theme.Spacing.s3)
                            }
                        }
                        .opacity(selected == nil || isSelected ? 1 : 0.6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("accuse.suspect.\(suspect.id)")
                }
            }

            Spacer()

            VStack(spacing: Theme.Spacing.s3) {
                HoldToConfirmButton(title: L10n.t("accuse.hold"), disabledTitle: L10n.t("accuse.select"), enabled: selected != nil) {
                    if let selected { session.accuse(selected) }
                }
                .accessibilityIdentifier("accuse.hold")
                if timeLeft {
                    Button(L10n.t("accuse.back")) { session.resumeInvestigation() }
                        .buttonStyle(TertiaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .padding(.bottom, Theme.Spacing.s5)
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .sheet(item: Binding(get: { fileOpen.map(SuspectSheetID.init) }, set: { fileOpen = $0?.id })) { item in
            NavigationStack { SuspectFileView(suspectID: item.id, session: session) }
                .presentationBackground(Theme.Colors.ink0)
        }
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

    @State private var shownSteps = 0
    @State private var confirmReveal = false

    var body: some View {
        let solved = verdict.isCorrect
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                Text(solved ? L10n.t("result.solvedBadge") : (revealed ? L10n.t("result.revealedBadge") : L10n.t("result.unsolvedBadge")))
                    .font(Theme.Fonts.overline)
                    .tracking(Theme.Tracking.overline)
                    .foregroundStyle(solved ? Theme.Colors.clear : (revealed ? Theme.Colors.textSecondary : Theme.Colors.alertText))
                    .padding(.horizontal, Theme.Spacing.s4)
                    .frame(height: 28)
                    .overlay(Capsule().strokeBorder(solved ? Theme.Colors.clear.opacity(0.5) : Theme.Colors.line3))
                    .padding(.top, Theme.Spacing.s7)

                if solved || revealed {
                    Text(caseFile.solution.headline).font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
                    Text(caseFile.solution.summary).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
                    RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs, shown: shownSteps)
                    Button(revealed ? L10n.t("result.replay") : L10n.t("result.seeScore"), action: revealed ? onReplay : onScore)
                        .buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                        .accessibilityIdentifier("result.primary")
                        .opacity(shownSteps >= caseFile.solution.reveal.count ? 1 : 0.4)
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

    private var wrongAnswer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            Text(L10n.f("result.wrongTitle", names[verdict.accused] ?? ""))
                .font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
            if let alibi = verdict.alibi {
                ResultCard(overline: L10n.t("result.alibi"), text: alibi, detail: verdict.alibiEvidence.map { $0.title })
            }
            if let trap = verdict.trap {
                ResultCard(overline: L10n.t("result.trap"), text: trap, detail: nil)
            }
            if !verdict.foundAboutAccused.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    Text(L10n.t("result.youFoundRight")).overline(Theme.Colors.clear)
                    ForEach(verdict.foundAboutAccused) { evidence in
                        Text("● " + evidence.title).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.f("result.missed", verdict.missed.count)).overline()
                ForEach(verdict.missedByApp.sorted { $0.value > $1.value }, id: \.key) { app, count in
                    HStack {
                        Text("○ " + app.title).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
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

struct ResultCard: View {
    let overline: String
    let text: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(overline).overline()
            Text(text).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textPrimary)
            if let detail { Text("◆ " + detail).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.signal) }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
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
                            .fill(isFound ? Theme.Colors.textPrimary : .clear)
                            .overlay(Circle().strokeBorder(Theme.Colors.textPrimary, lineWidth: 1.5))
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
