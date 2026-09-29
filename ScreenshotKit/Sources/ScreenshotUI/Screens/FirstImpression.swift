#if os(iOS)
import SwiftUI

// Screen 00 · Première impression (handoff UX V3 §6-00, §7 step 1): shown on the very first launch
// only. Test: « C'est un jeu d'enquête sur téléphone. » The logo mention, the concept in five steps
// that light up one after the other, one line in Newsreader, then [Commencer]. No video, no music.

/// The first impression: five steps lit every 0.9 s (opacity 0.3 → 1, 8 pt rise), the second one
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

    private struct Step: Identifiable {
        let id: Int
        let symbol: String
        let title: String
        let line: String
        /// The phone step is light, like the phone itself.
        var light = false
    }

    private var steps: [Step] {
        [Step(id: 1, symbol: "folder", title: L10n.t("first.step1.title"), line: L10n.t("first.step1.line")),
         Step(id: 2, symbol: "iphone", title: L10n.t("first.step2.title"), line: L10n.t("first.step2.line"), light: true),
         Step(id: 3, symbol: "plus", title: L10n.t("first.step3.title"), line: L10n.t("first.step3.line")),
         Step(id: 4, symbol: "link", title: L10n.t("first.step4.title"), line: L10n.t("first.step4.line")),
         Step(id: 5, symbol: "checkmark", title: L10n.t("first.step5.title"), line: L10n.t("first.step5.line"))]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LogoText()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: Trace.Spacing.s) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            tile(step, on: index < lit)
                        }
                    }
                    .padding(.top, 32)
                    Text(L10n.t("first.tagline"))
                        .font(Trace.Fonts.tagline)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 32)
                        .padding(.horizontal, 4)
                        .opacity(lineShown ? 1 : 0)
                        .offset(y: lineShown || noMotion ? 0 : 8)
                        .accessibilityHidden(!lineShown)
                }
                .padding(.horizontal, Trace.Spacing.l)
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
        .background(Trace.Colors.bg.ignoresSafeArea())
        // A tap anywhere before the end shows the final state (the button keeps its own tap).
        .contentShape(Rectangle())
        .onTapGesture { showFinalState(animated: true) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("first.impression")
        .task { await play() }
    }

    // MARK: - A step

    private func tile(_ step: Step, on: Bool) -> some View {
        let text = step.light ? Theme.Colors.textPrimary : Trace.Colors.text
        let secondary = step.light ? Theme.Colors.textSecondary : Trace.Colors.text2
        let fill = step.light ? Theme.Colors.bgBase : Trace.Colors.surface
        let iconFill = step.light ? Theme.Colors.bgRaised : Trace.Colors.surface2
        let iconColor = step.light ? Theme.Colors.trace : Trace.Colors.benText
        return HStack(alignment: .center, spacing: Trace.Spacing.l) {
            RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
                .fill(iconFill)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: step.symbol)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(iconColor)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.line)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Trace.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
                    .strokeBorder(step.light ? Theme.Colors.line1 : Trace.Colors.line, lineWidth: 1))
        )
        .opacity(on ? 1 : 0.3)
        .offset(y: on || noMotion ? 0 : 8)
        .accessibilityElement(children: .combine)
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
#endif
