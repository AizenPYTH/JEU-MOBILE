#if os(iOS)
import SwiftUI
import CaseEngine

// The end of a case, as the closing of a file: the phone is sealed (time's up), the final
// verification form (who is responsible, hold to close), the typed verification, the stamp
// RÉSOLU / NON RÉSOLU on the closed folder, the conclusion report, the closing report (score).

// MARK: - Time's up

/// The timer lands in the centre (mono, red), "TEMPS ÉCOULÉ", the phone is sealed, then the
/// final verification.
struct TimeUpView: View {
    let onDone: () -> Void
    @State private var progress: CGFloat = 0
    @State private var shown = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("00:00")
                .font(Trace.Fonts.score)
                .monospacedDigit()
                .foregroundStyle(Trace.Colors.stampOnDark)
                .scaleEffect(shown ? 1 : 0.5)
                .opacity(shown ? 1 : 0)
            Text(L10n.t("timeUp.title"))
                .font(Trace.Fonts.stamp(16))
                .tracking(4)
                .foregroundStyle(Trace.Colors.stampOnDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Trace.Colors.stampOnDark, lineWidth: 2))
                .rotationEffect(.degrees(-5))
                .scaleEffect(shown ? 1 : 1.5)
                .opacity(shown ? 1 : 0)
            Text(L10n.t("timeUp.subtitle")).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.bone2)
            GeometryReader { geo in
                Rectangle().fill(Trace.Colors.graphite)
                    .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.bone).frame(width: geo.size.width * progress) }
            }
            .frame(width: 160, height: 1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(TraceDesk())
        .task {
            AudioDirector.shared.play(.sting, volume: 0.8)
            withAnimation(Trace.Motion.dramatic) { shown = true }
            withAnimation(.linear(duration: Theme.Motion.timeUpHold)) { progress = 1 }
            try? await Task.sleep(for: .seconds(Theme.Motion.timeUpHold + 0.3))
            onDone()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Final verification (accusation)

/// « Vérification finale » — a form: "Qui est responsable ?", one box per suspect, then a slip
/// saying who is designated and on which pieces, and « Maintenir pour clore le dossier » (1.2 s).
struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?
    @State private var fileOpen: SuspectID?

    var body: some View {
        let game = session.game
        let timeLeft = session.remainingSeconds > 0
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.f("accuse.overline", dossierNumber(session.caseFile.number))).fieldLabel(Trace.Colors.bone3)
                        Spacer()
                        Text(timeLeft ? L10n.f("accuse.timeLeft", PhoneFormat.countdown(session.remainingSeconds)) : L10n.t("accuse.timeUp"))
                            .font(Trace.Fonts.fieldValue)
                            .foregroundStyle(timeLeft ? Trace.Colors.bone : Trace.Colors.stampOnDark)
                    }
                    Text(L10n.t("accuse.title")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
                    Text(L10n.t("accuse.instruction")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.bone2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
                .padding(.horizontal, 6)

                VStack(alignment: .leading, spacing: 12) {
                    ObjectiveCard(objective: session.caseFile.objective)
                        .padding(.bottom, 6)
                    ForEach(Array(session.caseFile.suspects.enumerated()), id: \.element.id) { index, suspect in
                        suspectRow(suspect, letter: Suspect.letter(index), game: game)
                    }
                }
                .padding(16)
                .paper(Trace.Colors.paper)
                .overlay(alignment: .top) { Staple().offset(y: 6) }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            decisionPanel(game: game, timeLeft: timeLeft)
        }
        .background(TraceDesk())
        .animation(Trace.Motion.emphasized, value: selected)
        .sheet(item: Binding(get: { fileOpen.map(SuspectSheetID.init) }, set: { fileOpen = $0?.id })) { item in
            NavigationStack { SuspectFileView(suspectID: item.id, session: session) }
                .presentationBackground(Trace.Colors.desk)
        }
    }

    private func suspectRow(_ suspect: Suspect, letter: String, game: Investigation) -> some View {
        let isSelected = selected == suspect.id
        let entries = game.linkedEntries(for: suspect.id)
        let against = entries.filter { $0.stance == .incriminates }.count
        let favour = entries.filter { $0.stance == .clears }.count
        return HStack(alignment: .center, spacing: 10) {
            Button {
                selected = suspect.id
                AudioDirector.shared.play(.paper, volume: 0.3)
                Haptics.selection()
            } label: {
                HStack(spacing: 10) {
                    CheckBox(on: isSelected, size: 20)
                    SuspectIndexCard(suspect: suspect, letter: letter, contact: game.contact(suspect.contact),
                                     against: against, favour: favour, principal: isSelected)
                        .overlay(alignment: .bottomTrailing) {
                            if isSelected {
                                StampMark(text: L10n.t("stamp.designated"), size: 9, angle: -8)
                                    .padding(8)
                                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                            }
                        }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("accuse.suspect.\(suspect.id)")

            Button { fileOpen = suspect.id } label: {
                VStack(spacing: 3) {
                    Image(systemName: "doc.text").font(.system(size: 15))
                    Text(L10n.t("accuse.file")).font(Trace.Fonts.monoSmall).textCase(.uppercase)
                }
                .foregroundStyle(Trace.Colors.inkSoft)
                .frame(width: 44)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(Text(L10n.f("accuse.fileA11y", game.name(of: suspect.contact))))
        }
        .opacity(selected == nil || isSelected ? 1 : 0.6)
    }

    private static func rank(_ stance: NotebookEntry.Stance?) -> Int {
        switch stance {
        case .incriminates: 0
        case nil: 1
        case .clears: 2
        }
    }

    /// The slip at the bottom: who is designated, the pieces the case rests on, hold to close.
    private func decisionPanel(game: Investigation, timeLeft: Bool) -> some View {
        let suspect = selected.flatMap { id in session.caseFile.suspects.first { $0.id == id } }
        let name = suspect.map { game.name(of: $0.contact) } ?? ""
        // What the case rests on: the pieces marked "l'accuse" first.
        let entries = suspect.map { s in
            game.linkedEntries(for: s.id).sorted { Self.rank($0.stance) < Self.rank($1.stance) }
        } ?? []
        return VStack(alignment: .leading, spacing: 10) {
            if suspect != nil {
                Text(L10n.f("accuse.youAccuse", name)).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                    .accessibilityIdentifier("accuse.youAccuse")
                if entries.isEmpty {
                    Handwritten(text: L10n.t("accuse.noEvidence"), color: Trace.Colors.stamp, size: 18, angle: -1)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(L10n.f("accuse.basedOn", entries.count)).fieldLabel()
                    FlowLayout(spacing: 6) {
                        ForEach(entries.prefix(6), id: \.ref) { entry in
                            EvidenceLabel(text: (game.pieceNumber(of: entry.ref).map(PieceFormat.short) ?? "") + " · " + PieceFormat.kind(entry.ref, in: game),
                                          seed: entry.ref.id)
                        }
                    }
                    if entries.count > 6 {
                        Text(L10n.f("accuse.more", entries.count - 6)).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                    }
                }
            } else {
                Text(L10n.t("accuse.pickFirst")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
            }
            HoldToCloseButton(title: L10n.t("accuse.hold"), disabledTitle: L10n.t("accuse.select"), enabled: selected != nil) {
                if let selected { session.accuse(selected) }
            }
            .accessibilityLabel(Text(selected != nil ? L10n.f("accuse.holdName", name) : L10n.t("accuse.select")))
            .accessibilityIdentifier("accuse.hold")
            if timeLeft {
                Button { session.resumeInvestigation() } label: {
                    Text(L10n.t("accuse.back")).font(Trace.Fonts.button).tracking(1.4).textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.inkSoft).frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                .fill(Trace.Colors.paperAged)
                .overlay(PaperGrain().clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)))
                .shadow(color: .black.opacity(0.5), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct SuspectSheetID: Identifiable {
    let id: SuspectID
}

/// « Maintenir pour clore le dossier »: an ink block that fills with the stamp's red while held;
/// released early, it empties. 1.2 s.
struct HoldToCloseButton: View {
    let title: String
    let disabledTitle: String
    let enabled: Bool
    let action: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6).fill(enabled ? Trace.Colors.ink : Trace.Colors.inkFaint.opacity(0.4))
            GeometryReader { geo in
                Rectangle().fill(Trace.Colors.stamp).frame(width: geo.size.width * progress)
            }
            Text(enabled ? title : disabledTitle)
                .font(Trace.Fonts.button)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(enabled ? Trace.Colors.bone : Trace.Colors.inkSoft)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: Trace.Motion.holdToClose, maximumDistance: 40) {
            guard enabled else { return }
            Haptics.stamp(heavy: true)
            action()
        } onPressingChanged: { pressing in
            guard enabled else { return }
            if pressing {
                withAnimation(.linear(duration: Trace.Motion.holdToClose)) { progress = 1 }
            } else {
                withAnimation(.linear(duration: 0.2)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(enabled ? title : disabledTitle))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { if enabled { action() } }
    }
}

// MARK: - Conclusion report

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
    /// The culprit's contact (photo on the solution).
    var culprit: Contact? = nil
    /// The accused's contact (the verification).
    var accused: Contact? = nil

    @State private var shownSteps = 0
    @State private var confirmReveal = false
    @State private var verification = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let solved = verdict.isCorrect
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.f("result.overline", dossierNumber(caseFile.number))).fieldLabel(Trace.Colors.bone3)
                    .padding(.top, 24)
                    .padding(.horizontal, 6)
                VStack(alignment: .leading, spacing: 22) {
                    header(solved: solved)
                    if solved || revealed {
                        solution(solved: solved)
                    } else {
                        wrongAnswer
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .top) { RuledLines(spacing: 28) }
                .paper(Trace.Colors.paper)
                .overlay(alignment: .top) { Staple().offset(y: 6) }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 32)
        }
        .background(TraceDesk())
        .task(id: revealed) {
            guard verdict.isCorrect || revealed else { return }
            shownSteps = 0
            if verification && !revealed && !reduceMotion {
                try? await Task.sleep(for: .seconds(Trace.Motion.verification + 1.6))
            }
            for step in 1...max(1, caseFile.solution.reveal.count) {
                try? await Task.sleep(for: .seconds(Theme.Motion.revealStep))
                withAnimation(Trace.Motion.emphasized) { shownSteps = step }
            }
        }
        .onTapGesture { shownSteps = caseFile.solution.reveal.count }
        .overlay {
            if verification && !revealed && !reduceMotion {
                VerificationView(caseNumber: caseFile.number, accusedName: names[verdict.accused] ?? "", accused: accused,
                                 pieces: verdict.pinnedCount, solved: verdict.isCorrect) {
                    withAnimation(Trace.Motion.dramatic) { verification = false }
                }
                .transition(.opacity)
            }
        }
        .confirmationDialog(L10n.t("result.revealConfirmTitle"), isPresented: $confirmReveal, titleVisibility: .visible) {
            Button(L10n.t("result.revealConfirmButton"), role: .destructive, action: onRevealRequested)
        } message: {
            Text(L10n.t("result.revealConfirm"))
        }
    }

    private func header(solved: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("result.reportTitle")).fieldLabel()
                Text(caseFile.title).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if solved {
                StampMark(text: L10n.t("stamp.solved"), size: 13, angle: -8)
            } else if revealed {
                StampMark(text: L10n.t("stamp.revealed"), color: Trace.Colors.ink, size: 10, dashed: true, angle: -6)
            } else {
                StampMark(text: L10n.t("stamp.unsolved"), size: 11, dashed: true, angle: -8)
            }
        }
    }

    /// Who did it, why (the key pieces, found ✓ or missed ○, with what each one proves), what the
    /// player's accusation rested on, then the reconstruction step by step.
    @ViewBuilder
    private func solution(solved: Bool) -> some View {
        let culpritName = names[verdict.culprit] ?? ""
        let key = caseFile.evidence.filter { $0.importance == .key }
        HStack(alignment: .center, spacing: 16) {
            IDPhoto(contact: culprit, width: 68, height: 82)
                .overlay(alignment: .topLeading) { Paperclip().offset(x: -4, y: -14) }
                .rotationEffect(.degrees(-1.5))
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("result.culpritOverline")).fieldLabel(Trace.Colors.stamp)
                Text(L10n.f("result.culpritWas", culpritName))
                    .font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        VStack(alignment: .leading, spacing: 8) {
            Text(caseFile.solution.headline).font(Trace.Fonts.fieldValueLarge).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(caseFile.solution.summary).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }

        if !key.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.f("result.keyEvidence", key.count)).fieldLabel()
                    .accessibilityIdentifier("result.keyEvidence")
                ForEach(key) { evidence in
                    KeyEvidenceRow(evidence: evidence, found: verdict.foundEvidenceIDs.contains(evidence.id))
                }
            }
        }

        if solved {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("result.yourCase")).fieldLabel()
                if accusedEvidence.isEmpty {
                    Handwritten(text: L10n.t("result.yourCaseEmpty"), color: Trace.Colors.pen, size: 18, angle: -1)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(Array(accusedEvidence.enumerated()), id: \.offset) { _, label in
                        Text("→ " + label).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink).lineLimit(2)
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("result.timeline")).fieldLabel()
            RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs, shown: shownSteps)
        }

        Button(revealed ? L10n.t("result.replay") : L10n.t("result.seeScore"), action: revealed ? onReplay : onScore)
            .buttonStyle(InkButtonStyle())
            .accessibilityIdentifier("result.primary")
            .opacity(shownSteps >= caseFile.solution.reveal.count ? 1 : 0.4)
    }

    /// Not solved: the debrief slip — why it was not them, the trap, what the player got right,
    /// what they missed (by app). The solution only on request.
    private var wrongAnswer: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.f("result.wrongTitle", names[verdict.accused] ?? ""))
                    .font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.t("result.wrongSubtitle")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
            }
            if let alibi = verdict.alibi {
                ResultCard(overline: L10n.t("result.alibi"), text: alibi, detail: verdict.alibiEvidence.map { $0.title })
            }
            if let trap = verdict.trap {
                ResultCard(overline: L10n.t("result.trap"), text: trap, detail: nil, color: Trace.Colors.stamp)
            }
            if !verdict.foundAboutAccused.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("result.youFoundRight")).fieldLabel()
                    ForEach(verdict.foundAboutAccused) { evidence in
                        HStack(alignment: .top, spacing: 10) {
                            CheckBox(on: true)
                            Text(evidence.title).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.f("result.missed", verdict.missed.count)).fieldLabel()
                ForEach(verdict.missedByApp.sorted { $0.value > $1.value }, id: \.key) { app, count in
                    LedgerRow(label: app.title, value: L10n.f("result.missedCount", count))
                }
            }
            Button(L10n.t("result.replay"), action: onReplay)
                .buttonStyle(InkButtonStyle())
                .accessibilityIdentifier("result.replay")
            Button(L10n.t("result.reveal")) { confirmReveal = true }
                .buttonStyle(PaperButtonStyle(height: 50, outlined: true))
                .accessibilityIdentifier("result.reveal")
        }
    }
}

/// The seconds after the hold: « VÉRIFICATION DU DOSSIER… » typed line by line (2.4 s), then
/// the folder closes and the stamp falls — RÉSOLU, or NON RÉSOLU. A tap skips it.
struct VerificationView: View {
    let caseNumber: Int
    let accusedName: String
    let accused: Contact?
    let pieces: Int
    let solved: Bool
    let onDone: () -> Void

    @State private var typed = 0
    @State private var closed = false

    private var lines: [String] {
        [L10n.t("verdict.checking"),
         L10n.f("verdict.designated", accusedName.uppercased()),
         L10n.f("verdict.pieces", pieces),
         L10n.t("verdict.crossCheck")]
    }

    var body: some View {
        ZStack {
            TraceDesk()
            if closed {
                closedFolder
                    .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
            } else {
                sheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
        .accessibilityElement(children: .combine)
        .task {
            let text = lines.joined()
            let perChar = Trace.Motion.verification / Double(max(1, text.count))
            for i in 1...text.count {
                typed = i
                if i % 3 == 0 { AudioDirector.shared.play(.typewriter, volume: 0.35) }
                try? await Task.sleep(for: .seconds(perChar))
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(Trace.Motion.emphasized) { closed = true }
            AudioDirector.shared.play(.folder, volume: 0.6)
            try? await Task.sleep(for: .seconds(1.8))
            onDone()
        }
    }

    /// The typed sheet: each line appears character by character.
    private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                IDPhoto(contact: accused, width: 56, height: 68)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.f("dossier.numberLong", dossierNumber(caseNumber))).fieldLabel(Trace.Colors.stamp)
                    Text(accusedName).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let start = lines.prefix(index).reduce(0) { $0 + $1.count }
                    let visible = max(0, min(line.count, typed - start))
                    Text(String(line.prefix(visible)) + (visible > 0 && visible < line.count ? "▌" : ""))
                        .font(Trace.Fonts.fieldValueLarge)
                        .foregroundStyle(Trace.Colors.ink)
                        .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 340)
        .paper(Trace.Colors.paper, lifted: true)
        .padding(.horizontal, 20)
    }

    /// The closed folder with its stamp.
    private var closedFolder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.f("dossier.number", dossierNumber(caseNumber))).font(Trace.Fonts.stamp(12)).tracking(2).foregroundStyle(Trace.Colors.kraftInk)
            Text(accusedName.uppercased()).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.kraftLabel)
            Spacer()
            HStack {
                Spacer()
                FallingStamp(text: solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                             size: solved ? 34 : 26, dashed: !solved, delay: 0.25)
                Spacer()
            }
            Spacer()
            Text(L10n.t("verdict.closed")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.kraftLabel)
        }
        .padding(22)
        .frame(width: 300, height: 380)
        .kraft()
        .overlay(alignment: .topLeading) {
            UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8).fill(Trace.Colors.kraft)
                .frame(width: 110, height: 22).offset(y: -20)
        }
    }
}

/// One decisive piece: ✓ found / ○ missed, its title, and what it really proves.
struct KeyEvidenceRow: View {
    let evidence: Evidence
    let found: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.3)
                if found { Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(Trace.Colors.pen) }
            }
            .frame(width: 18, height: 18)
            .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(evidence.title).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                Text(evidence.meaning).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(found ? L10n.t("result.keyFound") : L10n.t("result.keyMissed"))
                    .font(Trace.Fonts.monoSmall.weight(.semibold))
                    .foregroundStyle(found ? Trace.Colors.pen : Trace.Colors.stamp)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

/// A typed memo pinned in the report (the alibi, the trap).
struct ResultCard: View {
    let overline: String
    let text: String
    let detail: String?
    var color: Color = Trace.Colors.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(overline).fieldLabel(color)
            Text(text).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let detail { EvidenceLabel(text: detail) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.print, radius: 1)
        .overlay(alignment: .top) { Tape(width: 44).offset(y: -8) }
    }
}

/// The reconstruction, typed: found (filled square) · missed (empty square), a thin ink line.
struct RevealTimeline: View {
    let steps: [RevealStep]
    let found: Set<String>
    let shown: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                let isFound = step.evidence.map { found.contains($0) } ?? true
                HStack(alignment: .top, spacing: 12) {
                    Text(PhoneFormat.time(step.at)).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                        .frame(width: 42, alignment: .trailing)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(isFound ? Trace.Colors.ink : .clear)
                            .overlay(Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.3))
                            .frame(width: 9, height: 9)
                            .padding(.top, 4)
                        if offset < steps.count - 1 {
                            Rectangle().fill(Trace.Colors.ink.opacity(0.5)).frame(width: 1).frame(minHeight: 28)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.text).font(Trace.Fonts.proseSmall).foregroundStyle(isFound ? Trace.Colors.ink : Trace.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        if !isFound { Text(L10n.t("result.notFound")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.stamp) }
                    }
                    .padding(.bottom, 14)
                }
                .opacity(offset < shown ? 1 : 0)
                .offset(y: offset < shown ? 0 : 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text((isFound ? L10n.t("a11y.found") : L10n.t("a11y.missed")) + ", \(PhoneFormat.time(step.at)), \(step.text)"))
            }
        }
    }
}

// MARK: - Closing report (score)

/// « Rapport de clôture »: the final mark and the lines it is made of, typed on the form.
struct ScoreView: View {
    let verdict: Verdict
    let duration: Int
    var caseTitle: String = ""
    var caseNumber: Int = 0
    let onReplay: () -> Void
    let onNext: () -> Void
    @State private var displayed = 0
    @State private var rows = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.t("score.overline")).fieldLabel(Trace.Colors.stamp)
                            Text(L10n.f("dossier.numberLong", dossierNumber(caseNumber))).fieldLabel()
                            if !caseTitle.isEmpty {
                                Text(caseTitle).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                            }
                        }
                        Spacer(minLength: 8)
                        StampMark(text: verdict.isCorrect ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                                  size: 10, dashed: !verdict.isCorrect, angle: -8)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.t("score.final")).fieldLabel()
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(displayed)")
                                .font(Trace.Fonts.score)
                                .monospacedDigit()
                                .foregroundStyle(Trace.Colors.ink)
                                .contentTransition(.numericText())
                                .accessibilityIdentifier("score.value")
                            Text("/ 100").font(Trace.Fonts.fieldValueLarge).foregroundStyle(Trace.Colors.inkSoft)
                            Spacer()
                            if verdict.isPerfect && rows >= 5 {
                                FallingStamp(text: L10n.t("score.perfect"), size: 12, delay: 0.1)
                            }
                        }
                    }
                    VStack(spacing: 0) {
                        scoreRow(0, L10n.t("score.suspect"), verdict.isCorrect ? "✓ +\(verdict.scoreParts.suspect)" : "✕ 0")
                        scoreRow(1, L10n.t("score.time"), "\(PhoneFormat.countdown(Double(verdict.remainingSeconds))) · +\(verdict.scoreParts.time)")
                        scoreRow(2, L10n.t("score.found"), "\(verdict.foundCount)/\(verdict.totalCount) · +\(verdict.scoreParts.found)")
                        scoreRow(3, L10n.t("score.hints"), verdict.hintsUsed == 0 ? L10n.t("score.noHint") : "\(verdict.hintsUsed) · −\(verdict.hintCost)")
                        scoreRow(4, L10n.t("score.precision"), "\(verdict.relevantPinnedCount)/\(verdict.pinnedCount) · +\(verdict.scoreParts.precision)")
                    }
                    Text(L10n.t("score.signature")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint).padding(.top, 6)
                }
                .padding(20)
                .paper(Trace.Colors.paper)
                .overlay(alignment: .top) { Staple().offset(y: 6) }
                .padding(.horizontal, 12)
                .padding(.top, 28)
            }
            HStack(spacing: 10) {
                Button(L10n.t("result.replay"), action: onReplay).buttonStyle(PaperButtonStyle(height: 56))
                Button(L10n.t("score.next"), action: onNext).buttonStyle(InkButtonStyle(fill: Trace.Colors.stamp, text: Trace.Colors.stampText))
                    .accessibilityIdentifier("score.next")
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .background(TraceDesk())
        .task {
            let target = verdict.score
            let steps = 30
            for i in 1...steps {
                try? await Task.sleep(for: .milliseconds(30))
                displayed = target * i / steps
            }
            for i in 1...5 {
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(Trace.Motion.emphasized) { rows = i }
                if i % 2 == 1 { AudioDirector.shared.play(.typewriter, volume: 0.25) }
            }
        }
    }

    private func scoreRow(_ index: Int, _ label: String, _ value: String) -> some View {
        LedgerRow(label: label, value: value)
            .opacity(index < rows ? 1 : 0)
            .offset(y: index < rows ? 0 : 6)
    }
}
#endif
