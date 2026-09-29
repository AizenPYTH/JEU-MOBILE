#if os(iOS)
import SwiftUI
import UIKit

/// A BEN tip bubble (handoff UX V3 §7): flat `surface`, light text, radius 16, a small arrow
/// towards what it talks about, one sentence and a close button. Never modal: only its × takes
/// touches (taps go through the rest of it). It lives on the light phone: the dark bubble is the
/// BEN speaking, not the phone.
struct CoachBubble: View {
    let bubble: TutorialCoach.Bubble
    /// Where the arrow points.
    var arrow: Edge = .top
    /// Horizontal shift of the arrow from the bubble's centre, to point at an element that is not
    /// under the middle of the bubble (the Messages icon, a received message…).
    var arrowOffset: CGFloat = 0
    /// Kept for callers (the bubble is always the BEN's dark surface now).
    var dark = false
    let onClose: () -> Void
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    private var text: String {
        switch bubble {
        case .explore: L10n.t("tip.messages")
        case .file: L10n.t("tip.touchToFile")
        case .link: ""
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .allowsHitTesting(false)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Trace.Colors.text2)
                    .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -10)
            .accessibilityLabel(Text(L10n.t("a11y.close")))
            .accessibilityIdentifier("coach.close")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(maxWidth: 280, alignment: .leading)
        .background(
            shape
                .fill(Trace.Colors.surface)
                .overlay(shape.strokeBorder(Trace.Colors.line, lineWidth: 1))
                .overlay(alignment: arrow == .top ? .top : .bottom) {
                    BubbleArrow(up: arrow == .top)
                        .fill(Trace.Colors.surface)
                        .frame(width: 16, height: 8)
                        .offset(x: arrowOffset, y: arrow == .top ? -7.5 : 7.5)
                }
                .allowsHitTesting(false)
        )
        .offset(y: shown || reduceMotion ? 0 : (arrow == .top ? -4 : 4))
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.22)) { shown = true } }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityIdentifier("coach.bubble.\(bubble.rawValue)")
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }
}

/// The bubble's small triangle.
private struct BubbleArrow: Shape {
    let up: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if up {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

/// The element a tip points at (§7): a 2 pt ben ring that pulses once (scale 1 → 1.04 → 1), then
/// stays until the tip is answered. Reduced motion: the ring only.
struct CoachRing: View {
    let radius: CGFloat
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius + 3, style: .continuous)
            .strokeBorder(Trace.Colors.ben, lineWidth: 2)
            .padding(-3)
            .scaleEffect(pulse ? 1.04 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                guard !(systemReduceMotion || appReduceMotion) else { return }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeInOut(duration: 0.3)) { pulse = true }
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeInOut(duration: 0.3)) { pulse = false }
            }
    }
}
#endif
