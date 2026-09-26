#if os(iOS)
import SwiftUI
import UIKit

/// A tutorial bubble of case #001 (final handoff §D): paper, 280 pt max, a diamond arrow, a red
/// kicker « 1 / 3 · EXPLORER », one or two lines, an optional action hint. Never modal: it does not
/// block anything around it; the × (or any tap on it) closes it for good.
struct CoachBubble: View {
    let bubble: TutorialCoach.Bubble
    /// Where the arrow points.
    var arrow: Edge = .top
    /// Horizontal shift of the arrow from the bubble's centre, to point at an element that is not
    /// under the middle of the bubble (the Messages icon of the dock, a received message…).
    var arrowOffset: CGFloat = 0
    /// Dark variant, used on paper (the Carnet).
    var dark = false
    let onClose: () -> Void
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    private var key: String {
        switch bubble {
        case .explore: "explore"
        case .file: "file"
        case .link: "link"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("coach.kicker", bubble.rawValue, L10n.t("coach.\(key).verb")))
                    .font(Trace.Fonts.pieceNumber)
                    .tracking(1.6)
                    .foregroundStyle(dark ? Trace.Colors.stampOnDark : Trace.Colors.stamp)
                Spacer(minLength: 8)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(dark ? Trace.Colors.bone2 : Trace.Colors.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -14)
                .padding(.trailing, -12)
                .accessibilityLabel(Text(L10n.t("a11y.close")))
                .accessibilityIdentifier("coach.close")
            }
            Text(L10n.t("coach.\(key).body"))
                .font(Trace.Fonts.prose)
                .lineSpacing(3)
                .foregroundStyle(dark ? Trace.Colors.bone : Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if bubble == .explore {
                Text(L10n.t("coach.explore.action"))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(dark ? Trace.Colors.bone2 : Trace.Colors.inkSoft)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: 280, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(dark ? Trace.Colors.ink : Trace.Colors.paper)
                .overlay(alignment: arrow == .top ? .top : .bottom) {
                    Rectangle()
                        .fill(dark ? Trace.Colors.ink : Trace.Colors.paper)
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(45))
                        .offset(x: arrowOffset, y: arrow == .top ? -7 : 7)
                }
                .shadow(color: .black.opacity(0.6), radius: 20, y: 18)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .scaleEffect(shown || reduceMotion ? 1 : 0.96)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.22)) { shown = true } }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityIdentifier("coach.bubble.\(bubble.rawValue)")
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: L10n.t("coach.\(key).body"))
        }
    }
}

/// The element a bubble points at (§D): a 3 pt paper ring and a 4 pt halo at 25 %, just outside it.
struct CoachRing: View {
    let radius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius + 7, style: .continuous)
                .strokeBorder(Trace.Colors.paper.opacity(0.25), lineWidth: 4)
                .padding(-7)
            RoundedRectangle(cornerRadius: radius + 3, style: .continuous)
                .strokeBorder(Trace.Colors.paper, lineWidth: 3)
                .padding(-3)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
