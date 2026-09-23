#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 01 · Onboarding

/// First launch only: three short, playable steps — Explorer · Épingler · Accuser.
/// Each step is validated by doing the gesture; "Passer" is always there. No text over 3 lines.
struct OnboardingView: View {
    let onFinish: () -> Void

    enum Step: Int, CaseIterable { case explore, pin, accuse }
    @State private var step: Step = .explore
    @State private var done: Set<Step> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, Theme.Spacing.s5)

            Group {
                switch step {
                case .explore: ExploreDemo { complete(.explore) }
                case .pin: PinDemo { complete(.pin) }
                case .accuse: AccuseDemo { complete(.accuse) }
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .frame(maxHeight: .infinity, alignment: .top)

            Button(step == .accuse ? L10n.t("onboarding.start") : L10n.t("onboarding.continue")) { advance() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!done.contains(step))
                .accessibilityIdentifier("onboarding.next")
                .padding(.bottom, Theme.Spacing.s5)
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .background(Theme.Colors.ink0.ignoresSafeArea())
        .animation(Theme.Motion.emphasized(), value: step)
        .animation(Theme.Motion.standard(), value: done)
    }

    /// Three 18 × 3 marks (the current one white, done ones grey) and "Passer".
    private var header: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? Theme.Colors.textPrimary : (s.rawValue < step.rawValue ? Theme.Colors.textSecondary : Theme.Colors.line3))
                    .frame(width: 18, height: 3)
            }
            .accessibilityHidden(true)
            Text(L10n.f("onboarding.stepOf", step.rawValue + 1, Step.allCases.count))
                .font(Theme.Fonts.dataSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.leading, Theme.Spacing.s3)
            Spacer()
            Button(L10n.t("onboarding.skip"), action: onFinish)
                .buttonStyle(TertiaryButtonStyle())
                .accessibilityIdentifier("onboarding.skip")
        }
    }

    private func complete(_ s: Step) {
        guard !done.contains(s) else { return }
        done.insert(s)
        Haptics.success()
    }

    private func advance() {
        if let next = Step(rawValue: step.rawValue + 1) { step = next } else { onFinish() }
    }
}

/// Overline + title + one short paragraph, the text part of every step.
private struct StepText: View {
    let overline: String
    let title: String
    let body_: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(overline).overline(Theme.Colors.signal)
            Text(title).font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
            Text(body_).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small phone-like stage for the demos.
private struct DemoStage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(Theme.Spacing.s5)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.dock, style: .continuous).fill(Theme.Colors.bgBase))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.dock, style: .continuous).strokeBorder(Theme.Colors.line2))
    }
}

// MARK: Step 1 — Explorer: open an app, analyse a photo, pay in seconds

private struct ExploreDemo: View {
    let onDone: () -> Void
    @State private var opened = false
    @State private var analyzed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            StepText(overline: L10n.t("onboarding.explore.overline"),
                     title: L10n.t("onboarding.explore.title"),
                     body_: L10n.t("onboarding.explore.body"))
                .padding(.top, Theme.Spacing.s7)
            DemoStage {
                VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                    HStack {
                        TimerPill(remaining: analyzed ? 465 : 480, level: .normal)
                        if analyzed {
                            Text(L10n.f("bar.cost", 15)).font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.alertText)
                        }
                        Spacer()
                    }
                    if !opened {
                        HStack(spacing: Theme.Spacing.s5) {
                            ForEach([AppID.messages, .photos, .location, .notes], id: \.self) { app in
                                Button {
                                    if app == .photos { opened = true }
                                } label: {
                                    VStack(spacing: 6) {
                                        AppTileGlyph(app: app, size: 54)
                                        Text(app.title).font(Theme.Fonts.tabLabel).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(app.title))
                                .accessibilityIdentifier("onboarding.app.\(app.rawValue)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Text(L10n.t("onboarding.explore.hintTap")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textTertiary)
                    } else {
                        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                            GeneratedPhoto(scene: "bed", seed: "onboarding")
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                                Text(L10n.t("onboarding.explore.photo")).font(Theme.Fonts.calloutStrong).foregroundStyle(Theme.Colors.textPrimary)
                                if analyzed {
                                    Text(L10n.t("onboarding.explore.metadata")).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.signal)
                                        .accessibilityIdentifier("onboarding.metadata")
                                } else {
                                    Button {
                                        analyzed = true
                                        onDone()
                                    } label: {
                                        Label(L10n.f("photos.analyze", 15), systemImage: "info.circle")
                                            .font(Theme.Fonts.calloutStrong)
                                            .foregroundStyle(Theme.Colors.signal)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("onboarding.analyze")
                                }
                            }
                        }
                    }
                }
            }
        }
        .animation(Theme.Motion.standard(), value: opened)
        .animation(Theme.Motion.standard(), value: analyzed)
    }
}

// MARK: Step 2 — Épingler: hold a message to keep it in the notebook

private struct PinDemo: View {
    let onDone: () -> Void
    @State private var pinned = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            StepText(overline: L10n.t("onboarding.pin.overline"),
                     title: L10n.t("onboarding.pin.title"),
                     body_: L10n.t("onboarding.pin.body"))
                .padding(.top, Theme.Spacing.s7)
            DemoStage {
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    bubble(L10n.t("onboarding.pin.msg1"), mine: true)
                    bubble(L10n.t("onboarding.pin.msg2"), mine: false, pinned: pinned)
                        .scaleEffect(pinned ? 1 : 0.99)
                        .onLongPressGesture(minimumDuration: 0.45) {
                            guard !pinned else { return }
                            pinned = true
                            Haptics.pin()
                            onDone()
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(Text(L10n.t("onboarding.pin.hint")))
                        .accessibilityAction(named: Text(L10n.t("pin.add"))) {
                            pinned = true
                            onDone()
                        }
                        .accessibilityIdentifier("onboarding.pinTarget")
                    bubble(L10n.t("onboarding.pin.msg3"), mine: true)
                    HStack(spacing: Theme.Spacing.s3) {
                        Text("◆").foregroundStyle(pinned ? Theme.Colors.signal : Theme.Colors.textTertiary)
                        Text(L10n.t("carnet.title")).foregroundStyle(Theme.Colors.textPrimary)
                        Text(pinned ? "1" : "0").font(Theme.Fonts.dataStrong)
                            .foregroundStyle(pinned ? Theme.Colors.signal : Theme.Colors.textSecondary)
                            .contentTransition(.numericText())
                    }
                    .font(Theme.Fonts.calloutStrong)
                    .padding(.horizontal, Theme.Spacing.s5)
                    .frame(height: Theme.Size.carnetBar)
                    .background(Capsule().fill(Theme.Colors.bgBubbleIn))
                    .frame(maxWidth: .infinity)
                    .padding(.top, Theme.Spacing.s3)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("onboarding.carnet")
                }
            }
        }
        .animation(Theme.Motion.emphasized(0.3), value: pinned)
    }

    private func bubble(_ text: String, mine: Bool, pinned: Bool = false) -> some View {
        Text(text)
            .font(Theme.Fonts.body)
            .foregroundStyle(mine ? Theme.Colors.textOnLight : Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.s4)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                .fill(mine ? Theme.Colors.textPrimary : Theme.Colors.bgBubbleIn))
            .pinnedRing(pinned, radius: Theme.Radius.bubble)
            .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}

// MARK: Step 3 — Accuser: the timer, then hold to accuse

private struct AccuseDemo: View {
    let onDone: () -> Void
    @State private var selected: Int?
    @State private var accused = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            StepText(overline: L10n.t("onboarding.accuse.overline"),
                     title: L10n.t("onboarding.accuse.title"),
                     body_: L10n.t("onboarding.accuse.body"))
                .padding(.top, Theme.Spacing.s7)
            DemoStage {
                VStack(spacing: Theme.Spacing.s4) {
                    HStack {
                        TimerPill(remaining: 0, level: .critical)
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        ForEach(0..<2, id: \.self) { i in
                            let isSelected = selected == i
                            Button {
                                selected = i
                                Haptics.selection()
                            } label: {
                                VStack(spacing: Theme.Spacing.s2) {
                                    Text(i == 0 ? "A" : "B")
                                        .font(Theme.Fonts.title)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .frame(width: 56, height: 56)
                                        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Colors.bgRaised))
                                    Text(L10n.f("onboarding.accuse.suspect", i + 1)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textPrimary)
                                }
                                .padding(Theme.Spacing.s4)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                    .strokeBorder(isSelected ? Theme.Colors.textPrimary : Theme.Colors.line1, lineWidth: isSelected ? 2 : 1))
                                .opacity(selected == nil || isSelected ? 1 : 0.6)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                            .accessibilityIdentifier("onboarding.suspect.\(i)")
                        }
                    }
                    if accused {
                        Text(L10n.t("onboarding.accuse.done"))
                            .font(Theme.Fonts.narrativeSmall)
                            .foregroundStyle(Theme.Colors.clear)
                            .frame(minHeight: Theme.Size.buttonL)
                            .accessibilityIdentifier("onboarding.accused")
                    } else {
                        HoldToConfirmButton(title: L10n.t("accuse.hold"), disabledTitle: L10n.t("accuse.select"), enabled: selected != nil) {
                            accused = true
                            onDone()
                        }
                        .accessibilityIdentifier("onboarding.hold")
                    }
                }
            }
        }
        .animation(Theme.Motion.standard(), value: accused)
    }
}
#endif
