#if os(iOS)
import SwiftUI
import CaseEngine

/// Never just "wrong": what you got right, what it really meant, what you missed — revealed
/// step by step. The full solution is only shown if the player asks (or got it right).
struct ResultView: View {
    let verdict: Verdict
    let session: GameSession
    let onReplay: () -> Void
    let onExit: () -> Void

    @State private var step = 0
    @State private var missedShown = 0
    @State private var showsSolution = false

    private var file: CaseFile { session.caseFile }
    private func name(_ suspect: SuspectID) -> String {
        guard let s = file.suspects.first(where: { $0.id == suspect }) else { return suspect }
        return session.game.name(of: s.contact)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                if step >= 1 {
                    Text(verdict.accusedText)
                        .font(Theme.Fonts.body)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                if step >= 2, !verdict.foundAboutAccused.isEmpty {
                    block(title: verdict.isCorrect ? L10n.t("result.yourEvidence") : L10n.t("result.youFoundRight"),
                          items: verdict.foundAboutAccused, tint: Theme.Colors.success)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                if step >= 3, !verdict.missedKey.isEmpty {
                    missed.transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                if step >= 4 {
                    stats.transition(.opacity)
                    if verdict.isCorrect || showsSolution {
                        solution.transition(.opacity)
                    }
                    actions
                }
            }
            .padding(Theme.Spacing.xl)
            .animation(Theme.Motion.spring, value: step)
            .animation(Theme.Motion.spring, value: missedShown)
            .animation(Theme.Motion.spring, value: showsSolution)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .task {
            for next in 1...4 {
                try? await Task.sleep(for: .seconds(Theme.Motion.revealStep))
                step = next
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(L10n.f("bar.case", file.number) + " — " + file.title)
                .font(Theme.Fonts.overline)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(verdict.isCorrect ? L10n.t("result.solved") : L10n.t("result.unsolved"))
                .font(Theme.Fonts.display)
                .foregroundStyle(verdict.isCorrect ? Theme.Colors.success : Theme.Colors.alert)
            Text(verdict.isCorrect ? L10n.f("result.rightSuspect", name(verdict.accused))
                                   : L10n.f("result.wrongSuspect", name(verdict.accused)))
                .font(Theme.Fonts.title)
        }
    }

    private func block(title: String, items: [Evidence], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(title).font(Theme.Fonts.headline)
            ForEach(items) { evidence in
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Label(evidence.title, systemImage: evidence.importance == .falseLead ? "arrow.triangle.branch" : "checkmark.circle.fill")
                        .font(Theme.Fonts.subheadline.weight(.semibold))
                        .foregroundStyle(evidence.importance == .falseLead ? Theme.Colors.warning : tint)
                    Text(evidence.meaning)
                        .font(Theme.Fonts.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.surface))
    }

    private var missed: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(L10n.f("result.missed", verdict.missedKey.count)).font(Theme.Fonts.headline)
            ForEach(verdict.missedKey.prefix(missedShown)) { evidence in
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Label(evidence.title, systemImage: "eye.slash")
                        .font(Theme.Fonts.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                    // Without the solution, only the *kind* of clue is revealed; its meaning comes with the solution.
                    if verdict.isCorrect || showsSolution {
                        Text(evidence.meaning).font(Theme.Fonts.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            if missedShown < verdict.missedKey.count {
                Button(L10n.t("result.nextMissed")) { missedShown += 1 }
                    .font(Theme.Fonts.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.surface))
    }

    private var stats: some View {
        VStack(spacing: Theme.Spacing.s) {
            statRow(L10n.t("result.timeLeft"), PhoneFormat.countdown(Double(verdict.remainingSeconds)))
            statRow(L10n.t("result.hints"), "\(verdict.hintsUsed)")
            statRow(L10n.t("result.evidence"), "\(verdict.foundKeyCount)/\(verdict.totalKeyCount) · \(verdict.foundSupportingCount)/\(verdict.totalSupportingCount)")
            statRow(L10n.t("result.falseLeads"), "\(verdict.falseLeadsSeen.count)")
            statRow(L10n.t("result.apps"), "\(verdict.appsOpened) · \(L10n.f("result.searches", verdict.searches))")
            Divider().overlay(Theme.Colors.separator)
            HStack {
                Text(L10n.t("result.score")).font(Theme.Fonts.headline)
                Spacer()
                Text("\(verdict.score) %").font(Theme.Fonts.timer).monospacedDigit()
            }
        }
        .padding(Theme.Spacing.l)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.surface))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(Theme.Fonts.subheadline)
    }

    private var solution: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(L10n.t("result.whatHappened")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
            Text(file.solution.headline).font(Theme.Fonts.title)
            ForEach(Array(file.solution.story.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph).font(Theme.Fonts.body)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Theme.Spacing.m) {
            if !verdict.isCorrect && !showsSolution {
                Button {
                    showsSolution = true
                    missedShown = verdict.missedKey.count
                } label: {
                    Text(L10n.t("result.reveal"))
                        .font(Theme.Fonts.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).strokeBorder(Theme.Colors.separator))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.Colors.textPrimary)
            }
            Button(action: onReplay) {
                Text(L10n.t("result.replay"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.textPrimary))
            }
            .buttonStyle(.plain)
            Button(L10n.t("result.exit"), action: onExit)
                .font(Theme.Fonts.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.m)
    }
}
#endif
