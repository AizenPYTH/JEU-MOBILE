#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 02 · Dossier ouvert

/// The case file, open (V4 §4-02, docs/CASE_PRESENTATION.md): the kraft folder fills the screen and
/// holds the CaseSheet — a paper sheet inserted 10 pt from its edges. On the kraft: « ‹ Bureau » and
/// the code stamp OUVERT. On the sheet, in a fixed order: the header (DOSSIER #00N, the title,
/// « Lieu · Type », status · difficulty · time, and the stapled print of the person concerned) over
/// a 1.5 pt ink rule; CONTEXTE (the first sentences, the rest behind « Lire la suite »); VOTRE
/// MISSION framed by a 1.5 pt red rule; PERSONNES ENTENDUES (the suspects' identity photos, a tap
/// opens the person's card); MÉTHODE (#001 only: Explorer · Verser · Relier · Conclure, between
/// dashed rules); PREMIÈRES INFORMATIONS (first lead, place, last contact — the ones the case has);
/// then the level (not on the very first #001) and the report of a case already played. The sheet
/// scrolls; the footer stays, on the `bar` colour: [Examiner le téléphone · Pièce 01] + « n pièces
/// versées », or [Reprendre l'enquête · 06:58] + « Recommencer ». Opening (§5): the kraft cover
/// swings open (rotateY 0 → −165°, left edge) while the sheet rises 12 pt, 450 ms; a 200 ms fade
/// with reduced motion. The same view serves the story's case.
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
        /// The contact behind the person (their identity photo, if one is delivered).
        var contact: Contact? = nil

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
    /// The folder's cover, swinging open (0 → −165°), then gone.
    @State private var coverAngle: Double = 0
    @State private var coverGone = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    private var expandMotion: Animation { noMotion ? .easeOut(duration: 0.2) : Trace.Motion.paper }
    private var facts: DossierFacts { DossierFacts(file: caseFile) }
    private var seconds: Int { durations[selected] ?? caseFile.durationSeconds }
    /// The level choice is not offered on the first play of #001, before the assignment.
    private var showsLevels: Bool { !(caseFile.number == 1 && !PlayerStore.isAssigned) }

    private static let openingDuration = 0.45

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    caseSheet
                        .padding(.horizontal, Trace.Spacing.edge)
                        .padding(.top, 4)
                        .padding(.bottom, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared || noMotion ? 0 : 12)
                }
                .scrollIndicators(.hidden)
                .overlay { cover }
            }
            .background { Color.clear.kraft().ignoresSafeArea(edges: .top) }
            footer
        }
        .background(Trace.Colors.bar.ignoresSafeArea())
        .sheet(item: $sheet) { which in
            switch which {
            case .person(let person):
                PersonSheet(person: person, onClose: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.paper)
                    .presentationDragIndicator(.visible)
            case .report:
                reportSheet
                    .presentationDetents([.large])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.paper)
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
                    .presentationBackground(Trace.Colors.paper)
            }
        }
        .task {
            guard !appeared else { return }
            if !unlocked.contains(selected), let first = Challenge.allCases.first(where: { unlocked.contains($0) }) {
                selected = first
            }
            AudioDirector.shared.play(.folder, volume: 0.45)
            if noMotion {
                coverGone = true
                withAnimation(.easeOut(duration: 0.2)) { appeared = true }
            } else {
                withAnimation(.easeOut(duration: Self.openingDuration)) {
                    coverAngle = -165
                    appeared = true
                }
                try? await Task.sleep(for: .seconds(Self.openingDuration))
                coverGone = true
            }
        }
    }

    // MARK: Folder

    /// « ‹ Bureau » in ink on the kraft, and the OUVERT code stamp.
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            BackLink(title: backTitle ?? L10n.t("tab.bureau"), identifier: "intro.close", onPaper: true, action: onClose)
            Spacer(minLength: 8)
            StampMark(text: L10n.t("briefing.status.opened"), size: 12)
                .padding(.trailing, 6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    /// The folder's front cover over the sheet, swinging open once (decorative).
    @ViewBuilder
    private var cover: some View {
        if !coverGone && !noMotion {
            Color.clear
                .kraft()
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fileLabel(caseFile.number))
                            .font(Trace.Fonts.data)
                            .tracking(1.2)
                        Text(caseFile.title.capitalizedFirst)
                            .font(Trace.Fonts.caseTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(Trace.Colors.ink)
                    .padding(24)
                }
                .rotation3DEffect(.degrees(coverAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.45)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Sheet

    private var caseSheet: some View {
        VStack(alignment: .leading, spacing: 28) {
            header
            context
            mission
            people
            if caseFile.number == 1 {
                method
            }
            firstInformation
            if showsLevels || !attempts.isEmpty {
                secondary
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper()
    }

    // MARK: Header

    /// « DOSSIER #001 », the title, « Lieu · Type », status · difficulty · time; the stapled print
    /// of the person concerned on the right; a 1.5 pt ink rule under it.
    private var header: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 6) {
                Text(fileLabel(caseFile.number))
                    .font(Trace.Fonts.data)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.ink)
                Text(caseFile.title.capitalizedFirst)
                    .font(Trace.Fonts.caseTitle)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                let place = CaseFolder.placeLine(facts)
                if !place.isEmpty {
                    Text(place)
                        .font(Trace.Fonts.deskPlace)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(metaLine)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                    .accessibilityIdentifier("briefing.status")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let subject = subjectPerson {
                subjectPrint(subject)
            }
        }
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).accessibilityHidden(true)
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

    /// The print of the person concerned (66 × 82), stapled; its Caveat caption is the first name
    /// (VoiceOver reads the relation and the full name). A tap opens their card.
    private func subjectPrint(_ person: Person) -> some View {
        Button {
            sheet = .person(person)
            Haptics.selection()
        } label: {
            CaptionedPrint(image: ArtLibrary.portrait(case: caseFile.number, contact: person.contact),
                           initials: person.initials, caption: person.firstName,
                           width: 66, height: 82,
                           accessibility: "\(person.relation), \(person.name)", seed: person.id)
                .padding(.top, 6)
                .padding(.trailing, 2)
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint(Text(L10n.t("dossier.personHint")))
        .accessibilityIdentifier("briefing.person.\(person.id)")
    }

    // MARK: Context

    /// CONTEXTE: the first two sentences; the rest behind « Lire la suite ».
    private var context: some View {
        let parts = Self.contextParts(caseFile.synopsis)
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.tab.context"), color: Trace.Colors.ink2)
            Text(parts.lead)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !parts.more.isEmpty {
                if contextOpen {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(parts.more.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(Trace.Fonts.body)
                                .foregroundStyle(Trace.Colors.ink)
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
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(TextLinkStyle(onPaper: true))
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

    /// VOTRE MISSION, framed by a 1.5 pt red rule: the objective.
    private var mission: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("briefing.mission"))
                .fieldLabel(Trace.Colors.red)
                .accessibilityAddTraits(.isHeader)
            Text(caseFile.objective)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("briefing.mission")
    }

    // MARK: People

    /// The person the case is about, when not a suspect (the print of the header).
    private var subjectPerson: Person? {
        let suspectContacts = Set(caseFile.suspects.map(\.contact))
        guard let subject = facts.subjectContact(), !suspectContacts.contains(subject.id) else { return nil }
        return Person(id: subject.id, initials: subject.initials, name: subject.name,
                      relation: facts.subjectLabel.capitalizedFirst, age: caseFile.dossier?.subjectAge,
                      statement: nil, contact: subject)
    }

    /// The people heard: each suspect.
    private var suspects: [Person] {
        caseFile.suspects.compactMap { suspect in
            guard let contact = contact(suspect.contact) else { return nil }
            return Person(id: suspect.id, initials: contact.initials, name: contact.name,
                          relation: suspect.role, age: suspect.age, statement: suspect.statement, contact: contact)
        }
    }

    /// PERSONNES ENTENDUES: identity photos (60 × 74), first name, relation; a tap opens the
    /// person's card. Four to a row; a list at accessibility sizes.
    private var people: some View {
        let list = suspects
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.peopleHeard"), color: Trace.Colors.ink2)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(list) { person in personTile(person, wide: true) }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 4),
                          alignment: .leading, spacing: 18) {
                    ForEach(list) { person in personTile(person, wide: false) }
                }
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
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 14))
                : AnyLayout(VStackLayout(alignment: .center, spacing: 8))
            layout {
                IDPhoto(contact: person.contact, width: Self.photoWidth, height: Self.photoHeight)
                    .tilt(person.id)
                    .accessibilityHidden(true)
                VStack(alignment: wide ? .leading : .center, spacing: 2) {
                    Text(person.firstName)
                        .font(Trace.Fonts.monoStrong)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(person.relation)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .multilineTextAlignment(wide ? .leading : .center)
                        .lineLimit(wide ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: wide ? .leading : .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(person.name), \(person.relation)"))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text(L10n.t("dossier.personHint")))
        .accessibilityIdentifier("briefing.person.\(person.id)")
    }

    private static let photoWidth: CGFloat = 60
    private static let photoHeight: CGFloat = 74

    private func contact(_ id: String) -> Contact? {
        caseFile.devices.lazy.compactMap { $0.contacts.first { $0.id == id } }.first
    }

    // MARK: Method (#001)

    /// MÉTHODE, between two dashed rules: the four verbs, numbered, with one line each.
    private var method: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashedRule()
                .padding(.bottom, 24)
            SectionHeader(title: L10n.t("dossier.method"), color: Trace.Colors.ink2)
            VStack(alignment: .leading, spacing: 14) {
                step(1, verb: "dossier.how.explore", line: "dossier.how.exploreLine")
                step(2, verb: "dossier.how.file", line: "dossier.how.fileLine")
                step(3, verb: "dossier.how.link", line: "dossier.how.linkLine")
                step(4, verb: "dossier.how.conclude", line: "dossier.how.concludeLine")
            }
            DashedRule()
                .padding(.top, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("briefing.how")
    }

    private func step(_ number: Int, verb: String, line: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verbatim: String(format: "%02d", number))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink2)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t(verb))
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(Trace.Colors.ink)
                Text(L10n.t(line))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: First information

    /// PREMIÈRES INFORMATIONS: the case's first lead, the place, the last contact — the ones present.
    @ViewBuilder
    private var firstInformation: some View {
        let items = infoItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("dossier.firstInfo"), color: Trace.Colors.ink2)
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.label)
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.ink2)
                            Text(item.value)
                                .font(item.data ? Trace.Fonts.fieldValueLarge : Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .top) {
                            if index > 0 {
                                Rectangle().fill(Trace.Colors.ink.opacity(0.14)).frame(height: 1)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
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
        VStack(alignment: .leading, spacing: 12) {
            if showsLevels {
                levelPicker
            }
            if let last = attempts.last {
                reportLink(last)
            }
        }
    }

    /// « Niveau : Détective » in a thin ink frame, which opens the three levels.
    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(expandMotion) { levelsOpen.toggle() }
                Haptics.selection()
            } label: {
                HStack(spacing: 8) {
                    Text(L10n.f("briefing.level", L10n.t("challenge.\(selected.rawValue)")))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(PhoneFormat.countdown(Double(seconds)))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink)
                    Image(systemName: levelsOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Trace.Colors.ink2)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: Trace.Height.row)
                .overlay(Rectangle().strokeBorder(Trace.Colors.ink.opacity(0.35), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(Text(L10n.t("briefing.levelHint")))
            .accessibilityIdentifier("briefing.level")
            if levelsOpen {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Challenge.allCases, id: \.self) { level in
                        LevelRow(level: level, seconds: durations[level] ?? caseFile.durationSeconds,
                                 progress: levels[level], locked: !unlocked.contains(level),
                                 selected: selected == level) {
                            selected = level
                            Haptics.selection()
                        }
                    }
                    Text(L10n.t("challenge.sameStory"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .transition(.opacity)
            }
        }
    }

    /// « Rapport de clôture » (read-only), and the stamp of the last attempt.
    private func reportLink(_ last: Attempt) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(L10n.t("report.title")) { sheet = .report }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("dossier.report")
            Spacer(minLength: 8)
            resultStamp(last.solved, width: 84)
        }
    }

    private func resultStamp(_ solved: Bool, width: CGFloat) -> some View {
        solved
            ? StampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("stamp.solved"), width: width, angle: -8)
            : StampImage(asset: "stamp_non_resolu_noir_marque", label: L10n.t("stamp.unsolved"), width: width * 1.3,
                         angle: -6, color: Trace.Colors.ink)
    }

    // MARK: Footer

    /// On the `bar` colour: [Examiner le téléphone · Pièce 01] + « n pièces versées »; in progress,
    /// [Reprendre l'enquête · 06:58] and « n pièces versées · Recommencer ».
    private var footer: some View {
        VStack(spacing: 4) {
            if let saved {
                Button(L10n.f("intro.resume", PhoneFormat.countdown(saved.remainingSeconds)), action: onResume)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("intro.resume")
                HStack(spacing: 8) {
                    Text(L10n.f("dossier.piecesCount", saved.snapshot.notebook.count))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ivory2)
                    Text(verbatim: "·").foregroundStyle(Trace.Colors.ivory2).accessibilityHidden(true)
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
                    .foregroundStyle(Trace.Colors.ivory2)
                    .frame(minHeight: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
    }

    /// « Examiner le téléphone · Pièce 01 », or « Rejouer » for a case whose report is open.
    private var startTitle: String {
        archiveOpen ? L10n.t("briefing.replay") : L10n.t("dossier.examine")
    }

    // MARK: Report sheet

    /// The closing report of the last attempt, on paper; the reconstruction once the archive is open.
    private var reportSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { sheet = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Trace.Colors.ink2)
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
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }

    @ViewBuilder
    private var reportContent: some View {
        if let last = attempts.last {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("report.title"))
                        .fieldLabel(Trace.Colors.ink2)
                    Text(fileLabel(caseFile.number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(caseFile.title.capitalizedFirst)
                        .font(Trace.Fonts.serifTitle(26))
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 8)
                resultStamp(last.solved, width: 96)
                    .padding(.top, 8)
            }
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 0) {
                LeaderLine(label: L10n.t("report.date"), value: last.date.formatted(date: .abbreviated, time: .shortened))
                LeaderLine(label: L10n.t("report.culpritFound"), value: last.solved ? L10n.t("report.yes") : L10n.t("report.no"),
                           valueColor: last.solved ? Trace.Colors.green : Trace.Colors.red)
                LeaderLine(label: L10n.t("report.keyFound"), value: "\(last.found)/\(last.total)")
                LeaderLine(label: L10n.t("report.hints"), value: "\(last.hintsUsed)")
                LeaderLine(label: L10n.t("result.colMark"), value: last.ranked ? "\(last.score)/100" : "—")
            }
            if archiveOpen {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: L10n.t("report.reconstruction"), color: Trace.Colors.ink2)
                    Text(caseFile.solution.headline)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(caseFile.solution.summary)
                        .font(Trace.Fonts.quote)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    RevealTimeline(steps: caseFile.solution.reveal,
                                   found: Set(caseFile.solution.reveal.compactMap(\.evidence)),
                                   shown: caseFile.solution.reveal.count,
                                   onPaper: true)
                    ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(Trace.Fonts.body)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 8)
                .accessibilityIdentifier("dossier.reconstruction")
            } else {
                Text(L10n.t("report.locked"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Mission card (desk)

extension View {
    /// A `surface` card with a 3 pt ben rule on its left edge (the ALIBI briefing's statement, on
    /// the desk).
    func missionCard() -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        return background(alignment: .leading) { Trace.Colors.ben.frame(width: 3) }
            .background(Trace.Colors.surface)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Trace.Colors.line, lineWidth: 1))
    }
}

// MARK: - Pieces of the sheet

/// A dashed ink rule across the sheet (the MÉTHODE section's frame).
private struct DashedRule: View {
    var body: some View {
        FlatLine()
            .stroke(Trace.Colors.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// One challenge level on paper: a radio, the level, what it is for, its duration, and the player's
/// best result there (or « non tentée », or locked). Selected: 1.5 pt ink frame on a darker paper.
private struct LevelRow: View {
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
                    Circle().strokeBorder(Trace.Colors.ink.opacity(selected ? 1 : 0.5), lineWidth: 1.5)
                    if selected {
                        Circle().fill(Trace.Colors.ink).frame(width: 10, height: 10)
                    } else if locked {
                        Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(Trace.Colors.ink2)
                    }
                }
                .frame(width: 20, height: 20)
                .padding(.top, 1)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.t("challenge.\(level.rawValue)"))
                            .font(Trace.Fonts.monoStrong)
                            .foregroundStyle(Trace.Colors.ink)
                        Spacer()
                        Text(PhoneFormat.countdown(Double(seconds)))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.ink)
                    }
                    Text(L10n.t("challenge.\(level.rawValue)Pitch"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    status
                }
            }
            .padding(12)
            .background(selected ? Trace.Colors.paperSelected : Color.clear)
            .overlay(Rectangle().strokeBorder(Trace.Colors.ink.opacity(selected ? 1 : 0.2), lineWidth: selected ? 1.5 : 1))
            .opacity(locked ? 0.55 : 1)
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
            Text(L10n.t("challenge.locked"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        } else if let progress, progress.solved {
            HStack(spacing: 8) {
                Text(verbatim: "✓ " + L10n.t("challenge.solved")).foregroundStyle(Trace.Colors.green)
                if let time = progress.bestTime { Text(PhoneFormat.countdown(Double(time))) }
                if let score = progress.bestScore { Text(verbatim: "\(score)/100") }
            }
            .font(Trace.Fonts.data)
            .foregroundStyle(Trace.Colors.ink)
            .padding(.top, 2)
        } else if let progress, progress.plays > 0 {
            Text(L10n.f("challenge.tried", progress.plays))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
        } else {
            Text(L10n.t("challenge.untried"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
        }
    }
}

// MARK: - A person's card

/// A person of the case (sheet, on paper): the identity photo, the name, the relation, the age, what
/// they told the police. Nothing says who lies.
private struct PersonSheet: View {
    let person: DossierView.Person
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    IDPhoto(contact: person.contact, width: 78, height: 98, stapled: true)
                        .tilt(person.id)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name)
                            .font(Trace.Fonts.serifTitle(24))
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text(person.relation)
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let age = person.age {
                            Text(L10n.f("dossier.person.age", age))
                                .font(Trace.Fonts.data)
                                .foregroundStyle(Trace.Colors.ink2)
                        }
                    }
                    .padding(.top, 4)
                }
                if let statement = person.statement, !statement.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: L10n.t("alibi.tab.claim"), color: Trace.Colors.ink2)
                        Text(statement)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 14)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).accessibilityHidden(true)
                    }
                }
                Button(L10n.t("a11y.close"), action: onClose)
                    .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                    .accessibilityIdentifier("person.close")
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        .accessibilityIdentifier("person.sheet")
    }
}
#endif
