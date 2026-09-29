#if os(iOS)
import SwiftUI
import UIKit
import StoryEngine

// The entry screens of the story (docs/design_story/STORY_UX_FLOW.md), on the V4 desk
// (docs/design_v4): h04 the story's hub — the agent's kraft folder, the chapter sheet, [Continuer]
// — and h05 the creator in two steps (identity, then the BEN card held 1.2 s). No 3D, no
// appearance: the investigator is a name, an agreement and a print with initials. No story rule
// here: the coordinator and the engine decide.

// MARK: - h04 · Hub Histoire

/// h04: resume in one tap. The agent's folder (print, name, rank, service number) with the
/// chapter in progress on a sheet, three secondary buttons, [Continuer] at the bottom. ⚙ top right,
/// ‹ Bureau top left.
struct StoryHubView: View {
    let story: StoryCoordinator
    let onBack: () -> Void
    let onContinue: () -> Void
    let onProfile: () -> Void
    let onCareer: () -> Void
    let onOffice: () -> Void
    let onSettings: () -> Void
    let onChapter: (String) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var officeOpen: Bool { story.save?.unlocks.contains("office_01") ?? false }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heading
                    if story.loadError != nil {
                        PostItNote(title: L10n.t("story.hub.errorTitle"), message: L10n.t("story.hub.error"))
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("story.hub.error")
                    }
                    if story.player != nil {
                        agentFolder
                    }
                    grid
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StoryFooter { mainButton }
        }
        .background(ModeBackdrop())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.hub")
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            BackLink(title: L10n.t("tab.bureau"), identifier: "story.back", action: onBack)
                .accessibilityLabel(Text(L10n.t("story.hub.backToDesk")))
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Trace.Colors.ivoryMid)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("story.hub.settings")))
            .accessibilityIdentifier("story.settings")
        }
        .padding(.horizontal, 12)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            StoryLabel(text: L10n.t("story.paper.ben") + " · " + L10n.t("assignment.bureau"), color: Trace.Colors.ivory2)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.t("story.nav.hub"))
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.ivory)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: The agent's folder

    /// A kraft folder « DOSSIER D'AGENT »: the stapled print, the name, the rank and the service
    /// number; the chapter's sheet inside.
    private var agentFolder: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryFolderTab(text: L10n.t("story.hub.folderTab"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 18) {
                identity
                chapterSheet
            }
            .padding(16)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kraft()
        }
    }

    @ViewBuilder
    private var identity: some View {
        if let player = story.player {
            let name = player.firstName + " " + player.lastName
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
            layout {
                StoryPlayerPrint(initials: StoryCoordinator.initials(player.firstName, player.lastName),
                                 width: 72, height: 90, label: L10n.f("story.profile.a11y.print", name))
                    .tilt("hub.print")
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: name)
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(story.rankTitle())
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink2)
                    Text(verbatim: player.serviceNumber)
                        .font(Trace.Fonts.data)
                        .tracking(0.8)
                        .foregroundStyle(Trace.Colors.ink)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// « CHAPITRE 01 » / « SCÈNE n / N », the title, a 2 pt ink rule of progress — or, at the end of
    /// the content, « À SUIVRE ».
    @ViewBuilder
    private var chapterSheet: some View {
        if story.endOfContent {
            VStack(alignment: .leading, spacing: 8) {
                StoryLabel(text: L10n.t("story.hub.endKicker"))
                Text(L10n.t("story.hub.endOfContent"))
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperCard)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("story.chapterBlock")
        } else if let chapter = story.currentChapter {
            let progress = story.sceneProgress
            Button { onChapter(chapter.id) } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.f("story.hub.chapter", chapter.number))
                            .font(Trace.Fonts.data)
                            .tracking(1)
                            .foregroundStyle(Trace.Colors.ink)
                        Spacer(minLength: 8)
                        if progress.total > 0 {
                            StoryLabel(text: L10n.f("story.hub.scene", progress.index, progress.total))
                        }
                    }
                    HStack(alignment: .center, spacing: 8) {
                        Text(StoryTitles.sentence(chapter.title))
                            .font(Trace.StoryFonts.h3)
                            .foregroundStyle(Trace.Colors.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Trace.Colors.ink2)
                            .accessibilityHidden(true)
                    }
                    ProgressRule(progress: chapterFraction(chapter))
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .paper(Trace.Colors.paperCard)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(Text(L10n.t("story.hub.chapterHint")))
            .accessibilityIdentifier("story.chapterBlock")
        }
    }

    /// Steps done in the chapter (a finished chapter is full).
    private func chapterFraction(_ chapter: StoryChapter) -> Double {
        guard let save = story.save else { return 0 }
        if save.completedChapters.contains(chapter.id) && save.position.chapterID != chapter.id { return 1 }
        guard save.position.chapterID == chapter.id, !chapter.steps.isEmpty else { return 0 }
        return min(1, Double(save.position.stepIndex) / Double(chapter.steps.count))
    }

    // MARK: Buttons

    /// [Continuer] — the only full button; [Revoir un chapitre] at the end of the content.
    @ViewBuilder
    private var mainButton: some View {
        if story.endOfContent {
            Button(L10n.t("story.hub.replay"), action: onSettings)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("story.continue")
        } else {
            Button(L10n.t("story.hub.continue"), action: onContinue)
                .buttonStyle(CTAButtonStyle())
                .disabled(story.content == nil || story.player == nil)
                .accessibilityIdentifier("story.continue")
        }
    }

    /// MON ENQUÊTEUR · CARRIÈRE · MON BUREAU (outlined, 48 pt).
    private var grid: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return VStack(alignment: .leading, spacing: 8) {
            layout {
                Button(L10n.t("story.hub.profile"), action: onProfile)
                    .buttonStyle(CTAButtonStyle(kind: .outline, height: 48))
                    .accessibilityIdentifier("story.profile")
                Button(L10n.t("story.hub.career"), action: onCareer)
                    .buttonStyle(CTAButtonStyle(kind: .outline, height: 48))
                    .accessibilityIdentifier("story.career")
                Button(L10n.t("story.hub.office"), action: onOffice)
                    .buttonStyle(CTAButtonStyle(kind: .outline, height: 48))
                    .disabled(!officeOpen)
                    .accessibilityHint(Text(officeOpen ? "" : L10n.t("story.hub.officeLocked")))
                    .accessibilityIdentifier("story.office")
            }
            .disabled(story.player == nil)
            if !officeOpen {
                Text(L10n.t("story.hub.officeLocked"))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.ivory2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A 2 pt ink rule of progress on a sheet (never a percentage, never a gauge label).
private struct ProgressRule: View {
    let progress: Double

    var body: some View {
        Rectangle()
            .fill(Trace.Colors.ink.opacity(0.14))
            .frame(height: 2)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().fill(Trace.Colors.ink)
                        .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
                }
            }
            .accessibilityHidden(true)
    }
}

/// Titles written in capitals in the data, shown in sentence case (acronyms and references kept).
enum StoryTitles {
    private static let acronyms: Set<String> = ["BEN", "SMS", "GPS"]

    /// « PREMIÈRE AFFECTATION » → « Première affectation »; mixed case is kept.
    static func sentence(_ text: String) -> String {
        guard text.contains(where: \.isLetter), text == text.uppercased() else { return text }
        var words: [String] = []
        var first = true
        for part in text.split(separator: " ", omittingEmptySubsequences: false) {
            let word = String(part)
            let bare = String(word.filter(\.isLetter))
            if acronyms.contains(bare) || word.contains(where: \.isNumber) {
                words.append(word)
            } else {
                let lower = word.lowercased()
                words.append(first ? lower.prefix(1).uppercased() + lower.dropFirst() : lower)
            }
            if !word.isEmpty { first = false }
        }
        return words.joined(separator: " ")
    }
}

// MARK: - Controls of the creator

private struct SegmentOption<Value: Hashable> {
    let value: Value
    let label: String
    let id: String
}

/// A segmented choice on paper: a 1.2 pt ink frame (radius 8), the chosen segment filled with ink
/// (ivory text), the others ink on paper; 44 pt targets, Plex Sans 14.
private struct PaperSegmented<Value: Hashable>: View {
    let options: [SegmentOption<Value>]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.segment, style: .continuous)
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let on = option.value == selection
                Button {
                    guard !on else { return }
                    Haptics.selection()
                    onSelect(option.value)
                } label: {
                    Text(option.label)
                        .font(on ? .custom(Trace.FontName.sansSemibold, size: 14, relativeTo: .subheadline)
                                 : .custom(Trace.FontName.sans, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(on ? Trace.Colors.ivory : Trace.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: Trace.Height.hit)
                        .background(on ? Trace.Colors.ink : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(option.label))
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier(option.id)
                if i < options.count - 1 {
                    Rectangle().fill(Trace.Colors.ink.opacity(0.35)).frame(width: 1).accessibilityHidden(true)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Trace.Colors.ink, lineWidth: 1.2))
    }
}

// MARK: - h05 · Création du personnage

/// h05 in two steps: IDENTITÉ (the starting models Élise Morel and Vincent Delmas, first name, last
/// name, the agreement of titles) → CONFIRMATION (the BEN card on paper, held 1.2 s « Commencer ma
/// carrière »). No appearance, no outfit: the save keeps the starting model's look, untouched.
struct CharacterCreatorView: View {
    let story: StoryCoordinator
    let onClose: () -> Void

    private enum Step: Int, CaseIterable { case identity, confirmation }
    private enum NameField: Hashable { case first, last }

    @State private var step: Step = .identity
    /// The look saved with the investigator (the model's, or the catalogue's default): never shown.
    @State private var look: CharacterAppearance?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreement: Agreement = .feminine
    @State private var template: String?
    @State private var nameError = false
    @State private var stamped = false
    @State private var creating = false
    @State private var created = false
    @State private var blackout: Double = 0
    @FocusState private var focus: NameField?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : Trace.StoryMotion.paper }
    /// A sheet sliding in (a 200 ms fade with reduced motion).
    private var stepTransition: AnyTransition { reduceMotion ? .opacity : .opacity.combined(with: .offset(x: 24)) }
    private var steps: [Step] { Step.allCases }
    private var stepIndex: Int { steps.firstIndex(of: step) ?? 0 }
    private var reservedNames: [String] { (story.content?.npcs ?? []).map { "\($0.firstName) \($0.lastName)" } }
    private var shownFirst: String { StoryPlayer.normalized(firstName) }
    private var shownLast: String { StoryPlayer.normalized(lastName) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                stepContent
                    .id(step)
                    .transition(stepTransition)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StoryFooter { footer }
        }
        .background(ModeBackdrop())
        .overlay(alignment: .top) {
            if nameError {
                PostItNote(title: L10n.t("story.creator.nameErrorTitle"), message: L10n.t("story.creator.nameError"))
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .onTapGesture { withAnimation(motion) { nameError = false } }
                    .transition(.opacity)
                    .accessibilityIdentifier("creator.nameError")
            }
        }
        .overlay {
            // T-UI-3: the fade to the dark wood before the first scene.
            Trace.Story.sceneVoid.opacity(blackout).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
        }
        .allowsHitTesting(!creating)
        .onAppear { prepare() }
        .onChange(of: story.catalog == nil) { _, _ in prepare() }
    }

    // MARK: Top bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                BackChevron(label: stepIndex == 0 ? L10n.t("tab.bureau") : nil) { back() }
                    .accessibilityIdentifier("creator.back")
                Spacer(minLength: 8)
                StoryLabel(text: L10n.f("story.creator.stepLine", stepIndex + 1, steps.count, title(of: step)),
                           color: Trace.Colors.ivory2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            StepBar(count: steps.count, done: stepIndex + 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func title(of step: Step) -> String {
        switch step {
        case .identity: L10n.t("story.creator.step.identity")
        case .confirmation: L10n.t("story.creator.step.confirmation")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .identity: identityStep
        case .confirmation: confirmationStep
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .identity:
            Button(L10n.t("story.creator.next")) { next() }
                .buttonStyle(CTAButtonStyle())
                .disabled(look == nil)
                .accessibilityIdentifier("creator.next")
        case .confirmation:
            // « Maintien 1,2 s (identité) ».
            BenHoldButton(title: L10n.t("story.creator.confirm"), seconds: 1.2, enabled: !creating,
                          identifier: "creator.confirm") { confirm() }
        }
    }

    // MARK: Step 1 · IDENTITÉ

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                StoryLabel(text: L10n.t("story.paper.ben") + " · " + L10n.t("assignment.bureau"))
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.t("story.creator.sheetTitle"))
                    .font(Trace.StoryFonts.h2)
                    .foregroundStyle(Trace.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).padding(.top, 6).accessibilityHidden(true)
            }
            if let templates = story.catalog?.templates, !templates.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    StoryLabel(text: L10n.t("story.creator.template"))
                    HStack(spacing: 12) {
                        ForEach(templates) { model in
                            templateCard(model)
                        }
                    }
                }
            }
            nameField(L10n.t("story.creator.firstName"), prompt: L10n.t("story.creator.firstNamePrompt"),
                      text: $firstName, field: .first, id: "creator.firstName")
            nameField(L10n.t("story.creator.lastName"), prompt: L10n.t("story.creator.lastNamePrompt"),
                      text: $lastName, field: .last, id: "creator.lastName")
            VStack(alignment: .leading, spacing: 10) {
                StoryLabel(text: L10n.t("story.creator.agreement"))
                PaperSegmented(options: [
                    SegmentOption(value: Agreement.feminine, label: L10n.t("story.creator.agreementF"), id: "creator.agreement.f"),
                    SegmentOption(value: Agreement.masculine, label: L10n.t("story.creator.agreementM"), id: "creator.agreement.m"),
                    SegmentOption(value: Agreement.neutral, label: L10n.t("story.creator.agreementN"), id: "creator.agreement.n"),
                ], selection: agreement) { agreement = $0 }
                Text(L10n.f("story.creator.agreementNote", StoryText.rankTitle(.enqueteur, form: StoryText.GrammaticalForm(agreement))))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
    }

    /// Élise Morel / Vincent Delmas: a name and an agreement, all editable. Chosen: ink frame and a
    /// red pin.
    private func templateCard(_ model: CharacterTemplate) -> some View {
        let chosen = template == model.id
        return Button { apply(model) } label: {
            HStack(spacing: 10) {
                PhotoPrint(border: 3) {
                    PortraitOrInitials(image: nil, initials: StoryCoordinator.initials(model.firstName, model.lastName),
                                       width: 36, height: 45)
                }
                Text(verbatim: "\(model.firstName) \(model.lastName)")
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(chosen ? Trace.Colors.paperSelected : Trace.Colors.paperCard)
            .overlay(Rectangle().strokeBorder(chosen ? Trace.Colors.ink : Trace.Story.rule, lineWidth: chosen ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                if chosen { Pin(color: Trace.Colors.red, size: 12).offset(x: -8, y: -5) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: "\(model.firstName) \(model.lastName)"))
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("creator.template.\(model.id)")
    }

    /// A field of the form: its Plex Mono label, the name in Plex Sans 17 ink on a 1 pt ink rule
    /// (1.5 pt while typing).
    private func nameField(_ label: String, prompt: String, text: Binding<String>, field: NameField, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryLabel(text: label)
                .accessibilityHidden(true)
            TextField("", text: text, prompt: Text(prompt).foregroundStyle(Trace.Colors.ink2.opacity(0.7)))
                .font(.custom(Trace.FontName.sans, size: 17, relativeTo: .body))
                .foregroundStyle(Trace.Colors.ink)
                .tint(Trace.Colors.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textContentType(field == .first ? UITextContentType.givenName : UITextContentType.familyName)
                .submitLabel(field == .first ? .next : .done)
                .focused($focus, equals: field)
                .onSubmit { focus = field == .first ? .last : nil }
                .frame(minHeight: Trace.Height.hit)
                .accessibilityLabel(Text(label))
                .accessibilityIdentifier(id)
            Rectangle()
                .fill(Trace.Colors.ink.opacity(focus == field ? 1 : 0.5))
                .frame(height: focus == field ? 1.5 : 1)
                .accessibilityHidden(true)
        }
        .onChange(of: text.wrappedValue) { _, _ in
            if nameError { withAnimation(motion) { nameError = false } }
        }
    }

    // MARK: Step 2 · CONFIRMATION (the BEN card)

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                StoryLabel(text: L10n.t("story.creator.file"))
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: L10n.t("story.paper.ben") + " · " + L10n.t("assignment.bureau"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).padding(.top, 6).accessibilityHidden(true)
            }
            benCard
            VStack(spacing: 0) {
                ledger(L10n.t("story.creator.service"), L10n.t("story.paper.ben"))
                ledger(L10n.t("story.creator.assignment"), L10n.t("story.creator.unit"))
                ledger(L10n.t("story.creator.initialRank"), rankTitle)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    StoryLabel(text: L10n.t("story.profile.visa"))
                    Text(L10n.t("assignment.signatory"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 8)
                if let seal = ArtLibrary.image("seal_ben_bleu") {
                    Image(uiImage: seal)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .blendMode(.multiply)
                        .opacity(0.85)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
        .overlay(alignment: .topTrailing) {
            if stamped {
                FallingStamp(text: L10n.t("story.creator.stamp"), size: 15, delay: 0)
                    .padding(.top, 22)
                    .padding(.trailing, 16)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creator.file")
    }

    private var rankTitle: String { StoryText.rankTitle(.enqueteur, form: StoryText.GrammaticalForm(agreement)) }

    /// The BEN card: the print with initials, the name, the rank, the service number (given at the
    /// signature).
    private var benCard: some View {
        let name = "\(shownFirst) \(shownLast)"
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            StoryPlayerPrint(initials: StoryCoordinator.initials(shownFirst, shownLast), width: 88, height: 110,
                             label: L10n.f("story.profile.a11y.print", name))
                .tilt("creator.print")
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: name)
                    .font(Trace.StoryFonts.h2)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(rankTitle)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                VStack(alignment: .leading, spacing: 2) {
                    StoryLabel(text: L10n.t("assignment.serviceNumber"))
                    Text(L10n.t("story.creator.numberPending"))
                        .font(Trace.Fonts.fieldValue)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
                .accessibilityElement(children: .combine)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paperCard)
    }

    /// Label ........ value, in ink on the sheet.
    private func ledger(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink2)
            Spacer(minLength: 12)
            Text(value)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Story.rule).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    /// The starting model chosen at « Qui enquête ? » (or the first one).
    private func prepare() {
        guard look == nil, let catalog = story.catalog else { return }
        step = .identity
        if let model = catalog.template(PlayerStore.identity.id.rawValue) ?? catalog.templates.first {
            apply(model)
        } else {
            let fitted = catalog.fitted(catalog.defaultAppearance, unlocked: [])
            look = fitted
            agreement = Agreement(presentation: fitted.presentation)
        }
    }

    private func apply(_ model: CharacterTemplate) {
        guard let catalog = story.catalog else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            template = model.id
            firstName = model.firstName
            lastName = model.lastName
            look = catalog.fitted(model.appearance, unlocked: [])
            agreement = model.agreement
            nameError = false
        }
    }

    private func go(to next: Step) {
        focus = nil
        AudioDirector.shared.play(.paper, volume: 0.35)
        withAnimation(motion) { step = next }
    }

    private func next() {
        guard step == .identity else { return }
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        if StoryPlayer.nameProblem(firstName: first, lastName: last, reserved: reservedNames) != nil {
            focus = nil
            Haptics.warning()
            withAnimation(motion) { nameError = true }
            UIAccessibility.post(notification: .announcement, argument: L10n.t("story.creator.nameError"))
            return
        }
        nameError = false
        go(to: .confirmation)
    }

    private func back() {
        focus = nil
        nameError = false
        guard stepIndex > 0 else {
            onClose()
            return
        }
        go(to: steps[stepIndex - 1])
    }

    /// « Commencer ma carrière » held 1.2 s: the « Identité confirmée » stamp falls on the sheet,
    /// then T-UI-3 goes on.
    private func confirm() {
        guard !creating, look != nil else { return }
        focus = nil
        creating = true
        stamped = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 320))
            stampLanded()
        }
    }

    /// Stamp down → 400 ms → fade to the dark wood (600 ms) → the investigator exists, chapter 1
    /// starts.
    private func stampLanded() {
        guard !created, let look else { return }
        created = true
        let first = shownFirst
        let last = shownLast
        let chosen = agreement
        let fast = reduceMotion
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(fast ? 200 : 400))
            withAnimation(.easeIn(duration: fast ? 0.2 : 0.6)) { blackout = 1 }
            try? await Task.sleep(for: .milliseconds(fast ? 200 : 600))
            story.create(firstName: first, lastName: last, appearance: look, agreement: chosen)
            if !story.hasInvestigator {
                // Nothing could be created (content missing): never a dead end.
                withAnimation(.easeOut(duration: 0.3)) { blackout = 0 }
                stamped = false
                creating = false
                created = false
            }
        }
    }
}
#endif
