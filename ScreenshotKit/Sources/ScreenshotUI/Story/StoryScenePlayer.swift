#if os(iOS)
import SwiftUI
import StoryEngine

/// h11 / h12 · a scene, in 2D (no 3D: owner's decision): an interview report laid on the desk
/// (docs/design_v4). The place on a paper strip, the people present as identity prints (the one
/// speaking at full opacity with a red pin, the others at 55 %), the current line on a paper sheet
/// (speaker in Plex Mono caps, the words in Newsreader, typed at the chosen speed), the answers as
/// paper slips, title cards, notifications and pauses as paper cards; camera beats show nothing.
/// A tap anywhere completes the line, then moves on; a long press opens the JOURNAL. The HUD:
/// JOURNAL · AUTO · PASSER. The rules (auto-advance, journal, skip) are the coordinator's.
struct StoryScenePlayer: View {
    let story: StoryCoordinator
    @State private var picked: String?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var line: ResolvedLine? { story.stage.line }
    private var choicesShown: Bool { !(line?.choices.isEmpty ?? true) }

    var body: some View {
        ZStack {
            ModeBackdrop()
            VStack(spacing: 0) {
                hud
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                header
                // The sheet and the answers sit at the bottom; they scroll if they cannot fit.
                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        exchange
                            .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .bottom)
                            // The scroll view's whole area answers the tap too (not only its text).
                            .contentShape(Rectangle())
                            .onTapGesture { story.tap() }
                            .onLongPressGesture(minimumDuration: 0.5) { story.journalOpen = true }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .defaultScrollAnchor(.bottom)
                }
            }
            if let card = story.stage.titleCard {
                TitleCard(text: card)
                    .transition(.opacity)
            }
            if let notice = story.banner {
                SceneNotification(notice: notice)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 56)
                    .padding(.horizontal, 16)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
            Trace.Story.sceneVoid.opacity(story.blackout)
                .ignoresSafeArea()
                .allowsHitTesting(story.blackout > 0.5)
                .accessibilityHidden(true)
        }
        // The whole scene is the tappable area: the whole line, then the next one. Long press: the
        // journal. The buttons inside (answers, HUD) keep their own taps.
        .contentShape(Rectangle())
        .onTapGesture { story.tap() }
        .onLongPressGesture(minimumDuration: 0.5) { story.journalOpen = true }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.28), value: story.banner)
        .animation(.easeInOut(duration: reduceMotion ? 0.2 : 0.4), value: story.stage.titleCard)
        .sheet(isPresented: Binding(get: { story.journalOpen }, set: { story.journalOpen = $0 })) {
            SceneJournal(story: story)
                .presentationDetents([.fraction(0.9)])
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Story.journal)
                .presentationDragIndicator(.visible)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.scene")
        .statusBarHidden(true)
    }

    // MARK: HUD

    private var hud: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            HUDTag(title: L10n.t("story.hud.journal"), on: false) { story.journalOpen = true }
                .accessibilityIdentifier("story.hud.journal")
            HUDTag(title: L10n.t("story.hud.auto"), on: story.auto) { story.auto.toggle() }
                .accessibilityIdentifier("story.hud.auto")
                .accessibilityValue(Text(L10n.t(story.auto ? "story.a11y.on" : "story.a11y.off")))
            if story.canSkip {
                HUDTag(title: L10n.t("story.hud.skip"), on: false) { story.skipScene() }
                    .accessibilityIdentifier("story.hud.skip")
            }
        }
        .frame(minHeight: 44)
    }

    // MARK: The report

    /// The place, then who is in the room.
    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            PlaceStrip(place: story.scenePlace)
            PresentRow(people: present, speaker: line?.speaker, compact: choicesShown)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper, value: choicesShown)
    }

    /// The line on its sheet, then the answers.
    private var exchange: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSheet(story: story, line: line)
                .id(line?.nodeID ?? "pause")
                .transition(.opacity)
            if let line, !line.choices.isEmpty {
                choices(line)
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper, value: line?.nodeID)
    }

    /// The people in the room: the player always, the others once they are in (or speaking).
    private var present: [StoryParticipant] {
        let actors = story.stage.actors
        return story.participants.filter { p in
            p.id == "player" || actors[p.id]?.visible == true || line?.speaker == p.id
        }
    }

    private func choices(_ line: ResolvedLine) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(line.choices.enumerated()), id: \.element.id) { index, choice in
                ChoiceSlip(choice: choice, index: index, picked: picked) {
                    guard picked == nil else { return }
                    picked = choice.id
                    Task {
                        try? await Task.sleep(for: .milliseconds(reduceMotion ? 50 : 220))
                        story.choose(choice.id)
                        picked = nil
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(L10n.f("story.a11y.choices", line.choices.count)))
    }
}

// MARK: - Header

/// « COMPTE RENDU D'ENTRETIEN » and « BEN · BUREAU 312 · 21:06 » on a paper strip, stapled.
private struct PlaceStrip: View {
    let place: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("story.scene.report"))
                .fieldLabel(Trace.Colors.ink2)
            if let place, !place.isEmpty {
                Text(place)
                    .font(Trace.Fonts.data)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paperCard)
        .overlay(alignment: .topTrailing) { Staple().offset(x: -20, y: -4) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The people present, as identity prints (initials on `photoBg`): the one speaking at full
/// opacity with a red pin, the others at 55 %; nobody speaking (a pause, the narrator): all in full.
private struct PresentRow: View {
    let people: [StoryParticipant]
    let speaker: String?
    /// Smaller prints while answers are on the desk.
    let compact: Bool

    private var someoneSpeaks: Bool { people.contains { $0.id == speaker } }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ForEach(people) { person in
                let speaking = person.id == speaker
                VStack(spacing: 8) {
                    PhotoPrint(border: 4) {
                        PortraitOrInitials(image: nil, initials: person.initials,
                                           width: compact ? 50 : 62, height: compact ? 62 : 78)
                    }
                    .overlay(alignment: .top) {
                        Pin(color: speaking ? Trace.Colors.red : Trace.Colors.staple, size: speaking ? 14 : 11)
                            .offset(y: -6)
                    }
                    .tilt(person.id, range: 1.2)
                    Text(person.name)
                        .font(.custom(Trace.FontName.monoBold, size: 10, relativeTo: .caption2))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(speaking ? Trace.Colors.ivory : Trace.Colors.ivory2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: 96)
                }
                .opacity(!someoneSpeaks || speaking ? 1 : 0.55)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.25), value: speaker)
        .animation(.easeInOut(duration: 0.3), value: people.map(\.id))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("story.scene.a11y.present", people.map(\.name).joined(separator: ", "))))
    }
}

// MARK: - The sheet

/// The current line on its sheet — or, between lines (a silence, a held shot), a quiet « … ».
private struct ReportSheet: View {
    let story: StoryCoordinator
    let line: ResolvedLine?

    var body: some View {
        Group {
            if let line {
                DialogueLineView(story: story, line: line, question: !line.choices.isEmpty)
            } else {
                Text(verbatim: "…")
                    .font(Trace.StoryFonts.dialogueFont(size: 28))
                    .foregroundStyle(Trace.Colors.ink2)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .accessibilityLabel(Text(L10n.t("story.scene.pause")))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .paper(Trace.Colors.paper)
    }
}

/// SPEAKER (+ role on their first line), a rule, then the words typed at the chosen speed; ▸ when
/// it is all there. The player's own lines in ink2 italic, the narrator's without a name.
private struct DialogueLineView: View {
    let story: StoryCoordinator
    let line: ResolvedLine
    /// The line asks a question: no ▸ (the answers follow).
    let question: Bool
    @State private var shown = 0
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPlayer: Bool { line.speaker == "player" }
    private var isNarrator: Bool { line.speaker == "narrator" || line.speakerName == nil }
    private var quoted: String { isNarrator ? line.text : "« \(line.text) »" }
    /// The role shows on the speaker's first line of the scene only.
    private var showRole: Bool {
        guard let name = line.speakerName, line.speakerRole != nil else { return false }
        return story.journal.filter { $0.speaker == name && !$0.choice }.count <= 1
    }

    /// Newsreader 19 / 20 / 22 (subtitle size).
    private var size: CGFloat {
        switch StoryPreferences.subtitleSize {
        case .small: 19
        case .medium: 20
        case .large: 22
        }
    }

    var body: some View {
        let full = quoted
        let complete = story.lineComplete || shown >= full.count
        VStack(alignment: .leading, spacing: 10) {
            if let name = line.speakerName, !isNarrator {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(name)
                            .font(Trace.StoryFonts.dialogueName)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(Trace.Colors.ink)
                        if showRole, let role = line.speakerRole {
                            Text(role)
                                .font(Trace.StoryFonts.dialogueRole)
                                .foregroundStyle(Trace.Colors.ink2)
                        }
                    }
                    Rectangle().fill(Trace.Story.rule).frame(height: 1)
                }
            }
            ZStack(alignment: .topLeading) {
                // The full text reserves the space: the sheet never jumps while typing.
                Text(full).opacity(0)
                Text(complete ? full : String(full.prefix(shown)))
            }
            .font(Trace.StoryFonts.dialogueFont(size: question ? size - 1 : size, italic: isPlayer))
            .lineSpacing(5)
            .foregroundStyle(isPlayer || isNarrator ? Trace.Story.playerLine : Trace.Story.dialogue)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("story.dialogue")
            if !question {
                HStack {
                    Spacer()
                    Text(verbatim: "▸")
                        .font(Trace.StoryFonts.next)
                        .foregroundStyle(Trace.Colors.ink2)
                        .opacity(complete ? (reduceMotion ? 1 : (pulse ? 1 : 0.5)) : 0)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityHint(Text(question ? "" : L10n.t("story.a11y.next")))
        .accessibilityAddTraits(question ? .updatesFrequently : [.updatesFrequently, .isButton])
        .accessibilityAction { if !question { story.tap() } }
        .task(id: line.nodeID) {
            shown = 0
            let delay = StoryPreferences.characterDelay
            guard delay > 0 else {
                shown = full.count
                story.lineDidComplete()
                return
            }
            while shown < full.count {
                if story.lineComplete { shown = full.count; break }
                try? await Task.sleep(for: .seconds(delay))
                if Task.isCancelled { return }
                shown += 1
            }
            story.lineDidComplete()
        }
    }

    /// « Bernard Lacaze, commandant : Delmas. Fermez la porte. »
    private var spoken: String {
        guard let name = line.speakerName, !isNarrator else { return line.text }
        if let role = line.speakerRole { return "\(name), \(role.lowercased()) : \(line.text)" }
        return "\(name) : \(line.text)"
    }
}

// MARK: - Answers

/// An answer: a paper slip laid on the desk (a tilt of 1° at most), « A », « B »… in Plex Mono,
/// the silence (« — ») in Newsreader italic; the one picked gets a 2 pt red rule, the others go.
private struct ChoiceSlip: View {
    let choice: ResolvedChoice
    let index: Int
    let picked: String?
    let action: () -> Void

    private var prefix: String { choice.silent ? "—" : String(UnicodeScalar(UInt8(65 + min(index, 25)))) }

    var body: some View {
        let chosen = picked == choice.id
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(prefix)
                    .font(Trace.StoryFonts.choicePrefix)
                    .foregroundStyle(chosen ? Trace.Colors.red : Trace.Colors.ink2)
                    .frame(width: 14, alignment: .leading)
                Text(choice.text)
                    .font(choice.silent ? Trace.StoryFonts.choiceSilent : Trace.StoryFonts.choice)
                    .foregroundStyle(choice.silent ? Trace.Colors.ink2 : Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if choice.chosenBefore {
                    // A replayed chapter shows the answer given the first time.
                    Text(verbatim: "✓").font(Trace.StoryFonts.choicePrefix).foregroundStyle(Trace.Colors.ink2)
                        .accessibilityLabel(Text(L10n.t("story.a11y.chosenBefore")))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .paper(choice.silent ? Trace.Colors.paper : Trace.Colors.paperCard)
            .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: chosen ? 2 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .tilt("choice." + choice.id, range: 1)
        .opacity(picked == nil || chosen ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: picked)
        .accessibilityLabel(Text(choice.silent ? L10n.t("story.choice.silence") : "\(prefix) : \(choice.text)"))
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("story.choice.\(choice.id)")
    }
}

// MARK: - HUD

/// JOURNAL · AUTO · PASSER: short Plex Mono caps tags on the desk (ivory outline); AUTO on is
/// filled ivory with ink text. 32 pt tall, 44 pt targets.
private struct HUDTag: View {
    let title: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        Button(action: action) {
            Text(title)
                .fieldLabel(on ? Trace.Colors.ink : Trace.Colors.ivoryMid)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(shape.fill(on ? Trace.Colors.ivory : Color.clear))
                .overlay(shape.strokeBorder(on ? Color.clear : Trace.Story.deskRule, lineWidth: 1))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

/// A chapter or scene card (« CHAPITRE 01 — PREMIÈRE AFFECTATION »): a paper card over the dimmed
/// desk. It ends by itself.
private struct TitleCard: View {
    let text: String

    var body: some View {
        ZStack {
            Trace.Colors.desk.opacity(0.55).ignoresSafeArea()
            Text(text)
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Colors.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .paper(Trace.Colors.paper, lifted: true)
                .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The player's own phone receiving something, noted on a paper card taped at the top (3 s); a
/// tap does nothing more than on the scene.
private struct SceneNotification: View {
    let notice: StoryNotice

    private var isMail: Bool { notice.app == "mail" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t(isMail ? "story.scene.notice.mail" : "story.scene.notice.message"))
                .fieldLabel(Trace.Colors.red)
            Text(notice.title)
                .font(Trace.Fonts.headline)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !notice.text.isEmpty {
                Text(notice.text)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paperCard, lifted: true)
        .overlay(alignment: .top) { Tape().offset(y: -8) }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story.notification")
    }
}

// MARK: - Journal

/// Every line of the scene, on a sheet; the scene is paused while it is open. « Quitter la scène »
/// goes back to the hub (the scene resumes at the same line).
private struct SceneJournal: View {
    let story: StoryCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                StoryLabel(text: L10n.t("story.hud.journal"))
                if let place = story.scenePlace {
                    Text(place)
                        .font(Trace.Fonts.data)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.ink)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Rectangle().fill(Trace.Story.rule).frame(height: 1).padding(.horizontal, 20)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if story.journal.isEmpty {
                        Text(L10n.t("story.journal.empty"))
                            .font(Trace.StoryFonts.body)
                            .foregroundStyle(Trace.Colors.ink2)
                    }
                    ForEach(story.journal) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            if let speaker = entry.speaker {
                                StoryLabel(text: speaker)
                            }
                            Text(entry.choice ? "▸ " + entry.text : entry.text)
                                .font(entry.player ? Trace.StoryFonts.dialogueFont(size: 17, italic: true) : Trace.StoryFonts.dialogueFont(size: 17))
                                .foregroundStyle(entry.player ? Trace.Story.playerLine : Trace.Story.dialogue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            Button(L10n.t("story.journal.quit")) { story.journalOpen = false; story.pauseToHub() }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .accessibilityIdentifier("story.journal.quit")
        }
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.journal")
    }
}
#endif
