#if os(iOS)
import SwiftUI

// Screen 00 · Première impression (handoff UX V3 §6-00, §7 step 1; V4 « Dossier lisible » look):
// shown on the very first launch only. Test: « C'est un jeu d'enquête sur téléphone. » On the dark
// wooden desk, the concept as five objects laid one under the other — a kraft folder, the light
// phone, the kraft « Verser au dossier » tag, a red thread between two pins, a stamp — each with its
// one line in Plex Sans; they light up one after the other. Then one line in Newsreader and
// [Commencer]. No video, no music.

/// Sizes of the first impression (V4 §2–§3).
private enum ImpressionLayout {
    static let margin: CGFloat = 24
    /// The step number's column (Plex Mono 13/700).
    static let numberColumn: CGFloat = 28
    /// Space between two steps, and between an object and its line.
    static let stepGap: CGFloat = 18
    static let lineGap: CGFloat = 8
    /// Titles written on the objects: Plex Sans 15/600; the tag's own label 13/600 (§3 EvidenceTag).
    static let objectTitle = Trace.Fonts.monoStrong
    static let tagTitle = Font.custom(Trace.FontName.sansSemibold, size: 13, relativeTo: .footnote)
    /// Folder: tab 40 × 8 (radius 5 5 0 0), body radius 0 0 8 8.
    static let folderTab = CGSize(width: 40, height: 8)
    static let folderRadius: CGFloat = 8
    static let folderMinWidth: CGFloat = 132
    /// Phone card: radius 14, bubbles radius 16.
    static let phoneRadius: CGFloat = 14
    static let bubbleRadius: CGFloat = 16
    /// Evidence tag: 32 pt, corners 4 16 16 4, white eyelet 8 pt.
    static let tagHeight: CGFloat = 32
    static let eyelet: CGFloat = 8
    /// Thread: two paper nodes 28 × 24 with a 12 pt pin, a 2 pt red thread from pin to pin.
    static let node = CGSize(width: 28, height: 24)
    static let pin: CGFloat = 12
    static let thread: CGFloat = 2
    /// Stamp: Plex Mono 14/700, −6° (stays inside its slip).
    static let stampSize: CGFloat = 14
    static let stampAngle: Double = -6
}

/// The first impression: five steps lit every 0.9 s (opacity 0.3 → 1, 8 pt rise), the phone step
/// light like the phone; the line « Un téléphone. Une disparition. À vous de conclure. » and
/// [Commencer] at 4.5 s. A tap anywhere before the end shows the final state at once. Reduced
/// motion: the final state, faded in over 200 ms.
struct FirstImpressionView: View {
    let onStart: () -> Void

    /// Number of steps lit (0…5).
    @State private var lit = 0
    @State private var lineShown = false
    @State private var buttonShown = false
    /// Reduced motion: the whole screen fades in once.
    @State private var faded = false
    @State private var skipped = false

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }

    /// Timeline (§6-00): a step every 0.9 s, the line after the last one, the button at 4.5 s.
    private enum Timing {
        static let firstStep: Double = 0.3
        static let step: Double = 0.9
        static let line: Double = 4.1
        static let button: Double = 4.5
        static let light = Animation.easeOut(duration: 0.35)
    }

    fileprivate enum Object { case folder, phone, tag, thread, stamp }

    private struct Step: Identifiable {
        let id: Int
        let object: Object
        let title: String
        let line: String
    }

    private var steps: [Step] {
        [Step(id: 1, object: .folder, title: L10n.t("first.step1.title"), line: L10n.t("first.step1.line")),
         Step(id: 2, object: .phone, title: L10n.t("first.step2.title"), line: L10n.t("first.step2.line")),
         Step(id: 3, object: .tag, title: L10n.t("first.step3.title"), line: L10n.t("first.step3.line")),
         Step(id: 4, object: .thread, title: L10n.t("first.step4.title"), line: L10n.t("first.step4.line")),
         Step(id: 5, object: .stamp, title: L10n.t("first.step5.title"), line: L10n.t("first.step5.line"))]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LogoText()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Trace.Spacing.xxl)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: ImpressionLayout.stepGap) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            stepView(step, on: index < lit)
                        }
                    }
                    .padding(.top, Trace.Spacing.xxl + Trace.Spacing.s)
                    Text(L10n.t("first.tagline"))
                        .font(Trace.Fonts.tagline)
                        .foregroundStyle(Trace.Colors.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Trace.Spacing.xxl + Trace.Spacing.s)
                        .opacity(lineShown ? 1 : 0)
                        .offset(y: lineShown || noMotion ? 0 : 8)
                        .accessibilityHidden(!lineShown)
                }
                .padding(.horizontal, ImpressionLayout.margin)
                .padding(.bottom, Trace.Spacing.l)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(L10n.t("first.start")) {
                Haptics.selection()
                onStart()
            }
            .buttonStyle(CTAButtonStyle(kind: .primary))
            .accessibilityIdentifier("first.start")
            .padding(.horizontal, Trace.Spacing.xl)
            .padding(.top, Trace.Spacing.s)
            .padding(.bottom, Trace.Spacing.s)
            .opacity(buttonShown ? 1 : 0)
            .allowsHitTesting(buttonShown)
            .accessibilityHidden(!buttonShown)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(noMotion && !faded ? 0 : 1)
        .background(DeskBackdrop())
        // A tap anywhere before the end shows the final state (the button keeps its own tap).
        .contentShape(Rectangle())
        .onTapGesture { showFinalState(animated: true) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("first.impression")
        .task { await play() }
    }

    // MARK: - A step

    /// « 01 » in the margin (level with the object's middle), the object (which carries the
    /// step's name), its line below.
    private func stepView(_ step: Step, on: Bool) -> some View {
        HStack(alignment: .objectMiddle, spacing: 0) {
            Text(verbatim: String(format: "%02d", step.id))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ivory2)
                .frame(width: ImpressionLayout.numberColumn, alignment: .leading)
                .alignmentGuide(.objectMiddle) { $0[VerticalAlignment.center] }
            VStack(alignment: .leading, spacing: ImpressionLayout.lineGap) {
                ImpressionObject(kind: step.object, title: step.title)
                    .alignmentGuide(.objectMiddle) { $0[VerticalAlignment.center] }
                Text(step.line)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ivoryMid)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(on ? 1 : 0.3)
        .offset(y: on || noMotion ? 0 : 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(step.title). \(step.line)"))
    }

    // MARK: - Timeline

    private func play() async {
        if noMotion {
            showFinalState(animated: false)
            withAnimation(.easeInOut(duration: 0.2)) { faded = true }
            return
        }
        try? await Task.sleep(for: .seconds(Timing.firstStep))
        for index in 0..<steps.count {
            guard !Task.isCancelled, !skipped else { return }
            withAnimation(Timing.light) { lit = max(lit, index + 1) }
            if index < steps.count - 1 {
                try? await Task.sleep(for: .seconds(Timing.step))
            }
        }
        let afterLast = Timing.firstStep + Timing.step * Double(steps.count - 1)
        try? await Task.sleep(for: .seconds(max(0, Timing.line - afterLast)))
        guard !Task.isCancelled, !skipped else { return }
        withAnimation(Timing.light) { lineShown = true }
        try? await Task.sleep(for: .seconds(Timing.button - max(Timing.line, afterLast)))
        guard !Task.isCancelled, !skipped else { return }
        withAnimation(.easeOut(duration: 0.25)) { buttonShown = true }
    }

    private func showFinalState(animated: Bool) {
        guard !buttonShown else { return }
        skipped = true
        let update = {
            lit = steps.count
            lineShown = true
            buttonShown = true
        }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) { update() }
        } else {
            update()
        }
    }
}

// MARK: - The five objects

/// The step number sits level with the middle of its object.
private struct ObjectMiddle: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context[VerticalAlignment.center] }
}

extension VerticalAlignment {
    fileprivate static var objectMiddle: VerticalAlignment { VerticalAlignment(ObjectMiddle.self) }
}

/// One object laid on the desk, carrying the step's name. Decorative for VoiceOver (the step reads
/// its name and line). None is tilted (V4 §2: only prints and piece slips are); the stamp keeps its
/// own stamp angle.
private struct ImpressionObject: View {
    let kind: FirstImpressionView.Object
    let title: String

    var body: some View {
        switch kind {
        case .folder: folder
        case .phone: phone
        case .tag: tag
        case .thread: thread
        case .stamp: stamp
        }
    }

    /// 1 · A kraft folder: its tab, a sheet showing over the top edge, the name on the cover.
    private var folder: some View {
        let cover = UnevenRoundedRectangle(bottomLeadingRadius: ImpressionLayout.folderRadius,
                                          bottomTrailingRadius: ImpressionLayout.folderRadius,
                                          style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                .fill(Trace.Colors.kraft)
                .frame(width: ImpressionLayout.folderTab.width, height: ImpressionLayout.folderTab.height)
            Text(title)
                .font(ImpressionLayout.objectTitle)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.vertical, Trace.Spacing.m)
                .frame(minWidth: ImpressionLayout.folderMinWidth, alignment: .leading)
                .background(cover.fill(Trace.Colors.kraft))
                // The sheet inside, showing above the cover on the right.
                .background(alignment: .topTrailing) {
                    Rectangle()
                        .fill(Trace.Colors.paper)
                        .frame(width: 64, height: 12)
                        .offset(x: -Trace.Spacing.s, y: -5)
                }
        }
        .compositingGroup()
        .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
    }

    /// 2 · The seized phone, light (the phone's own colours): a message received, and the name as
    /// the message sent.
    private var phone: some View {
        let card = RoundedRectangle(cornerRadius: ImpressionLayout.phoneRadius, style: .continuous)
        return VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: ImpressionLayout.bubbleRadius, style: .continuous)
                .fill(Theme.Colors.bgBubbleIn)
                .frame(width: 64, height: 16)
            Text(title)
                .font(ImpressionLayout.objectTitle)
                .foregroundStyle(Theme.Colors.bubbleOutText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Trace.Spacing.m)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: ImpressionLayout.bubbleRadius, style: .continuous)
                    .fill(Theme.Colors.bubbleOut))
                .padding(.leading, Trace.Spacing.xxl)
        }
        .padding(Trace.Spacing.s + 2)
        .padding(.top, Trace.Spacing.s)
        .background(card.fill(Theme.Colors.bgBase))
        // The earpiece, centred on the card without widening it.
        .overlay(alignment: .top) {
            Capsule()
                .fill(Theme.Colors.bgElevated)
                .frame(width: 28, height: 4)
                .padding(.top, 7)
        }
        .overlay(card.strokeBorder(Theme.Colors.line2, lineWidth: 1))
        .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
    }

    /// 3 · The kraft « Verser au dossier » tag (§3 EvidenceTag): 32 pt, a white eyelet.
    private var tag: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4,
                                           bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous)
        return HStack(spacing: Trace.Spacing.s) {
            Circle()
                .fill(Trace.Colors.photoBorder)
                .overlay(Circle().strokeBorder(Trace.Colors.kraftDark, lineWidth: 1))
                .frame(width: ImpressionLayout.eyelet, height: ImpressionLayout.eyelet)
            Text(title)
                .font(ImpressionLayout.tagTitle)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, Trace.Spacing.m - 2)
        .padding(.trailing, Trace.Spacing.l)
        .padding(.vertical, 6)
        .frame(minHeight: ImpressionLayout.tagHeight)
        .background(shape.fill(Trace.Colors.kraft))
        .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
    }

    /// 4 · Two paper notes pinned in red, a red thread from pin to pin, the name under the thread.
    private var thread: some View {
        HStack(alignment: .top, spacing: Trace.Spacing.m) {
            node
            Text(title)
                .font(ImpressionLayout.objectTitle)
                .foregroundStyle(Trace.Colors.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, ImpressionLayout.pin + Trace.Spacing.xs)
            node
        }
        .background(alignment: .top) {
            Rectangle()
                .fill(Trace.Colors.redOnDesk)
                .frame(height: ImpressionLayout.thread)
                .padding(.horizontal, ImpressionLayout.node.width / 2)
                .padding(.top, (ImpressionLayout.pin - ImpressionLayout.thread) / 2)
        }
    }

    private var node: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Trace.Colors.paperCard)
                .frame(width: ImpressionLayout.node.width, height: ImpressionLayout.node.height)
                .shadow(color: Trace.Shadow.slip.color, radius: 3, y: 2)
                .padding(.top, ImpressionLayout.pin / 2)
            Pin(color: Trace.Colors.red, size: ImpressionLayout.pin)
        }
    }

    /// 5 · The stamp « CONCLURE », inked on a paper slip.
    private var stamp: some View {
        StampMark(text: title, color: Trace.Colors.red, size: ImpressionLayout.stampSize, angle: ImpressionLayout.stampAngle)
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.vertical, Trace.Spacing.m + 2)
            .background(
                Rectangle()
                    .fill(Trace.Colors.paper)
                    .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
            )
    }
}
#endif
