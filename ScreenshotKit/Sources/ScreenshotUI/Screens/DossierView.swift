#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 02 · Dossier

/// The case file (UX V3 §6-02, docs/CASE_PRESENTATION.md), in a fixed order: « ‹ Bureau »;
/// « DOSSIER #00N », the title, « Lieu · Type » and one meta line (status · difficulty · time);
/// CONTEXTE (two sentences, the rest behind « Lire la suite »); VOTRE MISSION (a card with a ben
/// rule); PERSONNES (initials, first name, relation — a tap opens the person's card); COMMENT
/// ENQUÊTER (#001 only: Explorer · Verser · Relier · Conclure); PREMIÈRES INFORMATIONS (first lead,
/// place, last contact — the ones the case has). The content scrolls; the footer stays:
/// [Ouvrir le téléphone] + « n pièces versées », or [Reprendre l'enquête · 06:58] + « Recommencer ».
/// Secondary: the challenge level (not on the very first #001) and the report of a case already
/// played. The same view serves the story's case.
struct DossierView: View {
    let caseFile: CaseFile
    let rules: GameRules?
    /// Duration of each level, « Temps détendu » included.
    let durations: [Challenge: Int]
    let unlocked: Set<Challenge>
    let levels: [Challenge: LevelProgress]
    /// The investigation in progress on this case, if any.
    let saved: SavedInvestigation?
    /// Finished attempts on this case (for the report).
    let attempts: [Attempt]
    let archiveOpen: Bool
    let onStart: (Challenge) -> Void
    let onResume: () -> Void
    let onClose: () -> Void
    /// « ‹ Bureau » by default (« ‹ Histoire » for the story's case).
    var backTitle: String? = nil

    /// A person of the case, as shown on their card (never who lies).
    struct Person: Identifiable {
        let id: String
        let initials: String
        let name: String
        let relation: String
        let age: Int?
        /// What they told the police (suspects only).
        let statement: String?

        var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }
    }

    private enum Sheet: Identifiable {
        case report, restart, person(Person)

        var id: String {
            switch self {
            case .report: "report"
            case .restart: "restart"
            case .person(let p): "person-\(p.id)"
            }
        }
    }

    @State private var selected: Challenge = .detective
    @State private var contextOpen = false
    @State private var levelsOpen = false
    @State private var sheet: Sheet?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    private var expandMotion: Animation { noMotion ? .easeOut(duration: 0.2) : Trace.Motion.paper }
    private var facts: DossierFacts { DossierFacts(file: caseFile) }
    private var seconds: Int { durations[selected] ?? caseFile.durationSeconds }
    /// The level choice is not offered on the first play of #001, before the assignment.
    private var showsLevels: Bool { !(caseFile.number == 1 && !PlayerStore.isAssigned) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackLink(title: backTitle ?? L10n.t("tab.bureau"), identifier: "intro.close", action: onClose)
                .padding(.horizontal, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    context
                    mission
                    people
                    if caseFile.number == 1 {
                        howTo
                    }
                    firstInformation
                    if showsLevels || !attempts.isEmpty {
                        secondary
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || noMotion ? 0 : 12)
            }
            .scrollIndicators(.hidden)
            footer
        }
        .background(DeskBackdrop())
        .sheet(item: $sheet) { which in
            switch which {
            case .person(let person):
                PersonSheet(person: person, onClose: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.surface)
                    .presentationDragIndicator(.visible)
            case .report:
                reportSheet
                    .presentationDetents([.large])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.surface)
                    .presentationDragIndicator(.visible)
            case .restart:
                PaperConfirmSheet(title: L10n.t("intro.restartTitle"),
                                  message: L10n.t("intro.restartMessage"),
                                  confirm: L10n.t("intro.restartConfirm"),
                                  confirmID: "intro.restartConfirm",
                                  destructive: true,
                                  cancel: L10n.t("common.back"),
                                  cancelID: "intro.restartCancel",
                                  onConfirm: {
                                      sheet = nil
                                      onStart(selected)
                                  },
                                  onCancel: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.surface)
            }
        }
        .task {
            guard !appeared else { return }
            if !unlocked.contains(selected), let first = Challenge.allCases.first(where: { unlocked.contains($0) }) {
                selected = first
            }
            AudioDirector.shared.play(.folder, volume: 0.45)
            withAnimation(noMotion ? .easeOut(duration: 0.2) : Trace.Motion.paper) { appeared = true }
        }
    }

    // MARK: Header

    /// « DOSSIER #001 », the title, « Lieu · Type », then status · difficulty · time.
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fileLabel(caseFile.number))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
            Text(caseFile.title.capitalizedFirst)
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            let place = CaseCard.placeLine(facts)
            if !place.isEmpty {
                Text(place)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(metaLine)
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
                .accessibilityIdentifier("briefing.status")
        }
    }

    /// « Ouvert · Difficulté 2/5 · 08:00 »
    private var metaLine: String {
        [statusText,
         L10n.t("dossier.difficulty") + " \(facts.rating)/5",
         PhoneFormat.countdown(Double(seconds))].joined(separator: " · ")
    }

    /// Ouvert, En cours (an investigation is saved) or Classé (the case has been concluded).
    private var statusText: String {
        if saved != nil { return L10n.t("case.state.open") }
        if attempts.contains(where: \.solved) { return L10n.t("briefing.status.closed") }
        return L10n.t("briefing.status.opened")
    }

    // MARK: Context

    /// CONTEXTE: the first two sentences; the rest behind « Lire la suite ».
    private var context: some View {
        let parts = Self.contextParts(caseFile.synopsis)
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.tab.context"))
            Text(parts.lead)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !parts.more.isEmpty {
                if contextOpen {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(parts.more.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(Trace.Fonts.body)
                                .foregroundStyle(Trace.Colors.text)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 10)
                    .transition(.opacity)
                }
                Button {
                    withAnimation(expandMotion) { contextOpen.toggle() }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 6) {
                        Text(L10n.t(contextOpen ? "briefing.contextLess" : "briefing.contextMore"))
                        Image(systemName: contextOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .buttonStyle(TextLinkStyle())
                .accessibilityAddTraits(contextOpen ? .isSelected : [])
                .accessibilityIdentifier("briefing.context")
            }
        }
    }

    /// The synopsis' first paragraph cut after two sentences; everything else is « more ».
    static func contextParts(_ synopsis: [String]) -> (lead: String, more: [String]) {
        guard let first = synopsis.first else { return ("", []) }
        let sentences = splitSentences(first)
        let lead = sentences.prefix(2).joined(separator: " ")
        let rest = sentences.dropFirst(2).joined(separator: " ")
        return (lead, (rest.isEmpty ? [] : [rest]) + synopsis.dropFirst())
    }

    /// Splits after « . », « ! », « ? » or « … » followed by a space and a capital letter (or a
    /// quote): « 21h30. Il n'est… » splits, « 1 200 € » or « 21:36 » do not.
    static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            current.append(chars[i])
            if ".!?…".contains(chars[i]), i + 2 < chars.count, chars[i + 1] == " ",
               chars[i + 2].isUppercase || chars[i + 2] == "«" || chars[i + 2] == "\"" {
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                i += 1
            }
            i += 1
        }
        let last = current.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { sentences.append(last) }
        return sentences
    }

    // MARK: Mission

    /// VOTRE MISSION: a surface card with a 3 pt ben rule on the left, the objective.
    private var mission: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("briefing.mission"))
            Text(caseFile.objective)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 14)
                .padding(.leading, 17)
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .missionCard()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("briefing.mission")
    }

    // MARK: People

    /// The person the case is about (when not a suspect), then each suspect.
    private var persons: [Person] {
        var result: [Person] = []
        let suspectContacts = Set(caseFile.suspects.map(\.contact))
        if let subject = facts.subjectContact(), !suspectContacts.contains(subject.id) {
            result.append(Person(id: subject.id, initials: subject.initials, name: subject.name,
                                 relation: facts.subjectLabel.capitalizedFirst, age: caseFile.dossier?.subjectAge,
                                 statement: nil))
        }
        for suspect in caseFile.suspects {
            guard let contact = contact(suspect.contact) else { continue }
            result.append(Person(id: suspect.id, initials: contact.initials, name: contact.name,
                                 relation: suspect.role, age: suspect.age, statement: suspect.statement))
        }
        return result
    }

    /// PERSONNES: 56 pt initials, first name, relation; a tap opens the person's card.
    private var people: some View {
        let list = persons
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.people"))
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(list) { person in personTile(person, wide: true) }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(list) { person in personTile(person, wide: false) }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("briefing.people")
    }

    private func personTile(_ person: Person, wide: Bool) -> some View {
        Button {
            sheet = .person(person)
            Haptics.selection()
        } label: {
            let layout = wide
                ? AnyLayout(HStackLayout(alignment: .center, spacing: 12))
                : AnyLayout(VStackLayout(alignment: .center, spacing: 6))
            layout {
                PortraitOrInitials(image: nil, initials: person.initials, width: Self.avatar, height: Self.avatar)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: wide ? .leading : .center, spacing: 2) {
                    Text(person.firstName)
                        .font(Trace.Fonts.monoStrong)
                        .foregroundStyle(Trace.Colors.text)
                        .lineLimit(1)
                    Text(person.relation)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .multilineTextAlignment(wide ? .leading : .center)
                        .lineLimit(wide ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: wide ? nil : Self.tileWidth, alignment: wide ? .leading : .top)
            .frame(maxWidth: wide ? .infinity : nil, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(L10n.t("dossier.personHint")))
        .accessibilityIdentifier("briefing.person.\(person.id)")
    }

    private static let avatar: CGFloat = 56
    private static let tileWidth: CGFloat = 96

    private func contact(_ id: String) -> Contact? {
        caseFile.devices.lazy.compactMap { $0.contacts.first { $0.id == id } }.first
    }

    // MARK: How to investigate (#001)

    /// COMMENT ENQUÊTER: four tiles, the first (where the player starts) in ben.
    private var howTo: some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible())]
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.how"))
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                howTile("magnifyingglass", verb: "dossier.how.explore", line: "dossier.how.exploreLine", current: true)
                howTile("plus.rectangle.on.folder", verb: "dossier.how.file", line: "dossier.how.fileLine", current: false)
                howTile("point.3.connected.trianglepath.dotted", verb: "dossier.how.link", line: "dossier.how.linkLine", current: false)
                howTile("checkmark.seal", verb: "dossier.how.conclude", line: "dossier.how.concludeLine", current: false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("briefing.how")
    }

    private func howTile(_ symbol: String, verb: String, line: String, current: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
        return VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Trace.Colors.benText)
                .accessibilityHidden(true)
            Text(L10n.t(verb))
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(Trace.Colors.text)
            Text(L10n.t(line))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(shape.fill(current ? Trace.Colors.tint(Trace.Colors.ben) : Trace.Colors.surface))
        .overlay(shape.strokeBorder(current ? Trace.Colors.ben : Trace.Colors.line, lineWidth: current ? 2 : 1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(current ? .isSelected : [])
    }

    // MARK: First information

    /// PREMIÈRES INFORMATIONS: the case's first lead, the place, the last contact — the ones present.
    @ViewBuilder
    private var firstInformation: some View {
        let items = infoItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("dossier.firstInfo"))
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.label)
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.text2)
                            Text(item.value)
                                .font(item.data ? Trace.Fonts.fieldValueLarge : Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            if index < items.count - 1 {
                                Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .benCard()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("briefing.firstLead")
        }
    }

    private var infoItems: [(label: String, value: String, data: Bool)] {
        var items: [(label: String, value: String, data: Bool)] = []
        if let lead = caseFile.firstLead, !lead.isEmpty {
            items.append((L10n.t("dossier.info.lead"), lead, false))
        }
        if !facts.place.isEmpty {
            items.append((L10n.t("dossier.info.place"), facts.place, false))
        }
        if let last = facts.lastContact {
            items.append((facts.lastContactLabel.capitalizedFirst, last, true))
        }
        return items
    }

    // MARK: Secondary: level, report

    private var secondary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsLevels {
                levelPicker
            }
            if let last = attempts.last {
                reportLink(last)
            }
        }
    }

    /// « Niveau : Détective », which opens the three levels.
    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(expandMotion) { levelsOpen.toggle() }
                Haptics.selection()
            } label: {
                HStack(spacing: 8) {
                    Text(L10n.f("briefing.level", L10n.t("challenge.\(selected.rawValue)")))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(PhoneFormat.countdown(Double(seconds)))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.text2)
                    Image(systemName: levelsOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Trace.Colors.text2)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: Trace.Height.row)
                .benCard(Trace.Colors.surface2, radius: Trace.Radius.button)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(Text(L10n.t("briefing.levelHint")))
            .accessibilityIdentifier("briefing.level")
            if levelsOpen {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Challenge.allCases, id: \.self) { level in
                        ChallengeCard(level: level, seconds: durations[level] ?? caseFile.durationSeconds,
                                      progress: levels[level], locked: !unlocked.contains(level),
                                      selected: selected == level) {
                            selected = level
                            Haptics.selection()
                        }
                    }
                    Text(L10n.t("challenge.sameStory"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .transition(.opacity)
            }
        }
    }

    /// The closing report of the last attempt (read-only), with its state as a badge.
    private func reportLink(_ last: Attempt) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(L10n.t("report.title")) { sheet = .report }
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("dossier.report")
            Spacer(minLength: 8)
            resultBadge(last.solved)
        }
    }

    private func resultBadge(_ solved: Bool) -> some View {
        StatusBadge(text: L10n.t(solved ? "case.state.solved" : "case.state.unsolved"),
                    color: solved ? Trace.Colors.successText : Trace.Colors.criticalOnDark,
                    symbol: solved ? "✓" : "✕")
    }

    // MARK: Footer

    /// [Ouvrir le téléphone] + « n pièces versées »; in progress, [Reprendre l'enquête · 06:58] and
    /// « Recommencer ».
    private var footer: some View {
        VStack(spacing: 4) {
            if let saved {
                Button(L10n.f("intro.resume", PhoneFormat.countdown(saved.remainingSeconds)), action: onResume)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("intro.resume")
                HStack(spacing: 8) {
                    Text(L10n.f("dossier.piecesCount", saved.snapshot.notebook.count))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                    Text(verbatim: "·").foregroundStyle(Trace.Colors.text3).accessibilityHidden(true)
                    Button(L10n.t("intro.restartConfirm")) { sheet = .restart }
                        .buttonStyle(TextLinkStyle())
                        .accessibilityIdentifier("intro.restart")
                }
            } else {
                Button(startTitle) { onStart(selected) }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityLabel(Text(startTitle + ", " + PhoneFormat.countdown(Double(seconds))))
                    .accessibilityIdentifier("intro.start")
                Text(L10n.f("dossier.piecesCount", 0))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .frame(minHeight: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    /// « Ouvrir le téléphone », or « Rejouer » for a case whose report is open in the Archives.
    private var startTitle: String {
        archiveOpen ? L10n.t("briefing.replay") : L10n.t("briefing.start")
    }

    // MARK: Report sheet

    /// The closing report of the last attempt; the reconstruction once the archive is open.
    private var reportSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { sheet = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Trace.Colors.text2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.t("a11y.close")))
                .accessibilityIdentifier("dossier.reportClose")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    reportContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Trace.Colors.surface.ignoresSafeArea())
    }

    @ViewBuilder
    private var reportContent: some View {
        if let last = attempts.last {
            let columns = typeSize.isAccessibilitySize
                ? [GridItem(.flexible())]
                : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
            resultBadge(last.solved)
            VStack(alignment: .leading, spacing: 4) {
                Text(fileLabel(caseFile.number))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.benText)
                Text(caseFile.title.capitalizedFirst)
                    .font(Trace.Fonts.serifTitle(26))
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.t("report.title"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ReportCard(label: L10n.t("report.date"), value: last.date.formatted(date: .abbreviated, time: .shortened))
                ReportCard(label: L10n.t("report.culpritFound"), value: last.solved ? L10n.t("report.yes") : L10n.t("report.no"),
                           color: last.solved ? Trace.Colors.successText : Trace.Colors.criticalOnDark)
                ReportCard(label: L10n.t("report.keyFound"), value: "\(last.found)/\(last.total)")
                ReportCard(label: L10n.t("report.hints"), value: "\(last.hintsUsed)")
                ReportCard(label: L10n.t("result.colMark"), value: last.ranked ? "\(last.score)/100" : "—")
            }
            if archiveOpen {
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
                .padding(.top, 8)
                .accessibilityIdentifier("dossier.reconstruction")
            } else {
                Text(L10n.t("report.locked"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Mission card

extension View {
    /// A `surface` card with a 3 pt ben rule on its left edge (§6-02 « Votre mission »).
    func missionCard() -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        return background(alignment: .leading) { Trace.Colors.ben.frame(width: 3) }
            .background(Trace.Colors.surface)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Trace.Colors.line, lineWidth: 1))
    }
}

// MARK: - A person's card

/// A person of the case (sheet): initials, name, relation, age, what they told the police. Nothing
/// says who lies.
private struct PersonSheet: View {
    let person: DossierView.Person
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    PortraitOrInitials(image: nil, initials: person.initials, width: 72, height: 72)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name)
                            .font(Trace.Fonts.serifTitle(24))
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text(person.relation)
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let age = person.age {
                            Text(L10n.f("dossier.person.age", age))
                                .font(Trace.Fonts.data)
                                .foregroundStyle(Trace.Colors.text2)
                        }
                    }
                }
                if let statement = person.statement, !statement.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: L10n.t("alibi.tab.claim"))
                        Text(statement)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Button(L10n.t("a11y.close"), action: onClose)
                    .buttonStyle(CTAButtonStyle(kind: .outline))
                    .accessibilityIdentifier("person.close")
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.surface.ignoresSafeArea())
        .accessibilityIdentifier("person.sheet")
    }
}
#endif
