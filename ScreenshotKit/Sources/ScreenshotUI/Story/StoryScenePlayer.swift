#if os(iOS)
import SwiftUI
import StoryEngine

/// h11 / h12 · a scene: the 3D stage, cinema subtitles (never bubbles), the answers, the silence,
/// a scripted notification, the place and time on the opening shot, and the HUD (JOURNAL · AUTO ·
/// PASSER). docs/design_story/DIALOGUE_UI.md. Overlays in the UX V3 look: flat, legible on the
/// scene, sentence case; the 3D stage itself is unchanged.
struct StoryScenePlayer: View {
    let story: StoryCoordinator
    @State private var picked: String?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var cameraStill: Bool { StoryPreferences.reduceCameraMotion ?? reduceMotion }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Trace.Story.sceneVoid.ignoresSafeArea()
                stageView
                    .ignoresSafeArea()
                scrim(height: geo.size.height)
                    .allowsHitTesting(false)
                // Taps anywhere: the whole line, then the next one. Long press: the journal.
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { story.tap() }
                    .onLongPressGesture(minimumDuration: 0.5) { story.journalOpen = true }
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 0)
                    bottom
                }
                .padding(.bottom, 10)
                if let card = story.stage.titleCard {
                    TitleCard(text: card)
                        .transition(.opacity)
                }
                if let notice = story.banner {
                    SceneNotification(notice: notice)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Color.black.opacity(story.blackout)
                    .ignoresSafeArea()
                    .allowsHitTesting(story.blackout > 0.5)
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.28), value: story.banner)
        .animation(.easeInOut(duration: 0.4), value: story.stage.titleCard)
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

    // MARK: Stage

    @ViewBuilder
    private var stageView: some View {
        if let content = story.content, let player = story.player {
            let stage = story.stage
            StoryStageView(snapshot: StageSnapshot(stage: stage,
                                                   location: stage.location.flatMap(content.location),
                                                   content: content, player: player,
                                                   rank: story.save?.rank ?? .enqueteur,
                                                   unlocks: story.save?.unlocks ?? [],
                                                   officeLevel: story.officeLevel,
                                                   text: { story.resolve($0) },
                                                   reduceMotion: cameraStill))
        }
    }

    /// The subtitle's veil: the bottom 300 pt, 0 → 0.82 (at 42 %) → 0.94.
    private func scrim(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(stops: [.init(color: Trace.Story.scrim.opacity(0), location: 0),
                                   .init(color: Trace.Story.scrim.opacity(0.82), location: 0.42),
                                   .init(color: Trace.Story.scrim.opacity(0.94), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: min(height * 0.55, max(300, choicesShown ? 420 : 300)))
        }
        .ignoresSafeArea()
    }

    private var choicesShown: Bool { !(story.stage.line?.choices.isEmpty ?? true) }

    // MARK: HUD and place

    private var topBar: some View {
        HStack(alignment: .top) {
            if let place = story.placeLabel {
                Text(place)
                    .font(Trace.StoryFonts.label)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Story.dialogue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Trace.Story.hud))
                    .transition(.opacity)
                    .accessibilityLabel(Text(place))
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                HUDPill(title: L10n.t("story.hud.journal"), on: false) { story.journalOpen = true }
                    .accessibilityIdentifier("story.hud.journal")
                HUDPill(title: L10n.t("story.hud.auto"), on: story.auto) { story.auto.toggle() }
                    .accessibilityIdentifier("story.hud.auto")
                    .accessibilityValue(Text(L10n.t(story.auto ? "story.a11y.on" : "story.a11y.off")))
                if story.canSkip {
                    HUDPill(title: L10n.t("story.hud.skip"), on: false) { story.skipScene() }
                        .accessibilityIdentifier("story.hud.skip")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.5), value: story.placeLabel)
    }

    // MARK: Subtitles and answers

    @ViewBuilder
    private var bottom: some View {
        if let line = story.stage.line {
            VStack(alignment: .leading, spacing: 14) {
                DialogueLineView(story: story, line: line, question: !line.choices.isEmpty)
                if !line.choices.isEmpty {
                    choices(line)
                }
            }
            .padding(.horizontal, line.choices.isEmpty ? 28 : 20)
            .padding(.bottom, 28)
            .transition(.opacity)
            .id(line.nodeID)
        }
    }

    private func choices(_ line: ResolvedLine) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(line.choices.enumerated()), id: \.element.id) { index, choice in
                ChoiceRow(choice: choice, index: index, picked: picked) {
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

// MARK: - A line

/// NAME + ROLE, then the line between « », typed at the chosen speed; ▸ when it is all there.
private struct DialogueLineView: View {
    let story: StoryCoordinator
    let line: ResolvedLine
    /// The line asks a question: smaller, no ▸ (the answers follow).
    let question: Bool
    @State private var shown = 0
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPlayer: Bool { line.speaker == "player" }
    private var quoted: String { line.speaker == "narrator" ? line.text : "« \(line.text) »" }
    /// The role shows on the speaker's first line of the scene only.
    private var showRole: Bool {
        guard let name = line.speakerName, line.speakerRole != nil else { return false }
        return story.journal.filter { $0.speaker == name && !$0.choice }.count <= 1
    }

    private var scale: CGFloat {
        switch StoryPreferences.subtitleSize {
        case .small: 0.86
        case .medium: 1
        case .large: 1.18
        }
    }

    var body: some View {
        let full = quoted
        let complete = story.lineComplete || shown >= full.count
        VStack(alignment: .leading, spacing: 8) {
            if let name = line.speakerName {
                HStack(spacing: 10) {
                    Text(name)
                        .font(Trace.StoryFonts.dialogueName)
                        .foregroundStyle(Trace.Colors.benText)
                    if showRole, let role = line.speakerRole {
                        Text(role)
                            .font(Trace.StoryFonts.dialogueRole)
                            .foregroundStyle(Trace.Colors.text2)
                    }
                }
            }
            ZStack(alignment: .topLeading) {
                // The full text reserves the space: the block never jumps while typing.
                Text(full).opacity(0)
                Text(complete ? full : String(full.prefix(shown)))
            }
            .font(question ? Trace.StoryFonts.dialogueQuestion : Trace.StoryFonts.dialogue)
            .scaleEffect(scale, anchor: .bottomLeading)
            .lineSpacing(question ? 4 : 7)
            .foregroundStyle(question || isPlayer ? Trace.Story.playerLine : Trace.Story.dialogue)
            .lineLimit(4)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("story.dialogue")
            if complete && !question {
                HStack {
                    Spacer()
                    Text("▸")
                        .font(Trace.StoryFonts.next)
                        .foregroundStyle(Trace.Colors.text2)
                        .opacity(reduceMotion ? 1 : (pulse ? 1 : 0.6))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityAddTraits(.updatesFrequently)
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
        guard let name = line.speakerName else { return line.text }
        if let role = line.speakerRole { return "\(name), \(role.lowercased()) : \(line.text)" }
        return "\(name) : \(line.text)"
    }
}

// MARK: - Answers

/// An answer (V3): a flat `surface2` row (radius 12) legible on the scene; A has a brighter rule,
/// the silence (« — », italic) is transparent; the one picked gets the 2 pt `ben` selection.
private struct ChoiceRow: View {
    let choice: ResolvedChoice
    let index: Int
    let picked: String?
    let action: () -> Void

    private var prefix: String { choice.silent ? "—" : String(UnicodeScalar(UInt8(65 + min(index, 25)))) }

    var body: some View {
        let first = index == 0 && !choice.silent
        let chosen = picked == choice.id
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(prefix)
                    .font(Trace.StoryFonts.choicePrefix)
                    .foregroundStyle(choice.silent ? Trace.Colors.text3 : (first ? Trace.Story.dialogue : Trace.Colors.text2))
                    .frame(width: 14, alignment: .leading)
                Text(choice.text)
                    .font(choice.silent ? Trace.StoryFonts.choiceSilent : Trace.StoryFonts.choice)
                    .foregroundStyle(choice.silent ? Trace.Colors.text2 : Trace.Story.dialogue)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if choice.chosenBefore {
                    // A replayed chapter shows the answer given the first time.
                    Text("✓").font(Trace.StoryFonts.choicePrefix).foregroundStyle(Trace.Colors.text2)
                        .accessibilityLabel(Text(L10n.t("story.a11y.chosenBefore")))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(shape.fill(choice.silent && !chosen ? Color.clear : Trace.Colors.surface2.opacity(0.92)))
            .overlay(shape.strokeBorder(chosen ? Trace.Colors.ben : (first ? Trace.Colors.text.opacity(0.3) : Trace.Colors.line),
                                        lineWidth: chosen ? 2 : 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .opacity(picked == nil || chosen ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: picked)
        .accessibilityLabel(Text(choice.silent ? L10n.t("story.choice.silence") : "\(prefix) : \(choice.text)"))
        .accessibilityIdentifier("story.choice.\(choice.id)")
    }
}

// MARK: - HUD

private struct HUDPill: View {
    let title: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Trace.StoryFonts.label)
                .foregroundStyle(on ? Trace.Colors.onFill : Trace.Story.dialogue)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(on ? Trace.Colors.ben : Trace.Story.hud))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A chapter or scene card (« CHAPITRE 01 — PREMIÈRE AFFECTATION »).
private struct TitleCard: View {
    let text: String

    var body: some View {
        ZStack {
            Trace.Story.sceneVoid.opacity(0.92).ignoresSafeArea()
            Text(text)
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Story.dialogue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The player's own phone receiving something (the phone's banner style), 3 s; a tap does nothing.
private struct SceneNotification: View {
    let notice: StoryNotice

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.Colors.bgSelected)
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: notice.app == "mail" ? "envelope.fill" : "message.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary))
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                if !notice.text.isEmpty {
                    Text(notice.text).font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textSecondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story.notification")
    }
}

// MARK: - Journal

/// Every line of the scene; the scene is paused while it is open. « Quitter la scène » goes back
/// to the hub (the scene resumes at the same line).
private struct SceneJournal: View {
    let story: StoryCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryLabel(text: L10n.t("story.hud.journal"), color: Trace.Colors.text2)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 10)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if story.journal.isEmpty {
                        Text(L10n.t("story.journal.empty"))
                            .font(Trace.StoryFonts.body)
                            .foregroundStyle(Trace.Colors.text2)
                    }
                    ForEach(story.journal) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            if let speaker = entry.speaker {
                                StoryLabel(text: speaker, color: Trace.Colors.text2)
                            }
                            Text(entry.choice ? "▸ " + entry.text : entry.text)
                                .font(Trace.StoryFonts.choice)
                                .foregroundStyle(entry.player ? Trace.Story.playerLine : Trace.Story.dialogue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            Button(L10n.t("story.journal.quit")) { story.journalOpen = false; story.pauseToHub() }
                .buttonStyle(TextLinkStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .accessibilityIdentifier("story.journal.quit")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.journal")
    }
}
#endif
