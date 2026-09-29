#if os(iOS)
import SwiftUI
import UIKit

// Shared pieces of the UX V3 design (docs/design_ux_v3): the call-to-action buttons (ActionButton),
// the logo, the RÉSOLU stamp, portraits, the confirmation sheet and the error card. Every screen
// outside the phone builds on these and on TraceDesign.swift.

extension Trace.Colors {
    /// A selected card.
    static let paperSelected = surface2
    /// The former white border of a print.
    static let printWhite = surface2
    /// Secondary text (the former secondary ink).
    static let inkMid = text2
    /// Secondary text on the desk, links.
    static let boneMid = text2
    /// Fallback avatar background.
    static let benBlue = surface3
    /// Initials on a missing portrait.
    static let portraitInitials = text
    /// The player's own words.
    static let handInk = benText
    /// Text on a critical fill.
    static let criticalText = onFill
    /// Hold-to-confirm track.
    static let holdTrack = surface2
    static let deskWarm = bg
    static let deskDeep = bg
}

extension Trace.Fonts {
    /// Button label: Plex Sans 17/600, sentence case.
    static let cta = Font.custom(Trace.FontName.sansSemibold, size: 17, relativeTo: .body)
    /// A section header (caps are applied by the view): Plex Sans 12/600.
    static let kicker = Font.custom(Trace.FontName.sansSemibold, size: 12, relativeTo: .caption)
    /// Screen title: Newsreader 31/500.
    static let monoTitle = Font.custom(Trace.FontName.serifMedium, size: 31, relativeTo: .title)
    /// Plex Sans 15/600: names, verbs, values in a row.
    static let monoStrong = Font.custom(Trace.FontName.sansSemibold, size: 15, relativeTo: .subheadline)
    /// Links: Plex Sans 15.
    static let link = Font.custom(Trace.FontName.sans, size: 15, relativeTo: .body)
    /// Interface text: Plex Sans 16.
    static let uiBody = Font.custom(Trace.FontName.sans, size: 16, relativeTo: .body)
    /// A line in Newsreader 26.
    static let tagline = Font.custom(Trace.FontName.serif, size: 26, relativeTo: .title)
    /// Newsreader titles.
    static func serifTitle(_ size: CGFloat) -> Font { .custom(Trace.FontName.serifMedium, size: size, relativeTo: .title2) }
}

// MARK: - Backgrounds

/// The BEN background: flat `bg` (V3: no lamp, no wood).
struct DeskBackdrop: View {
    var body: some View {
        Trace.Colors.bg.ignoresSafeArea().accessibilityHidden(true)
    }
}

// MARK: - Buttons (ActionButton, §5)

/// ActionButton (§5): 56 pt, radius 14, Plex Sans 17/600. One primary (ben, white text) per
/// screen; secondary on `surface2`; tertiary outlined at 20 %; destructive on `critical`.
/// Pressed: scale 0.98 + darker (90 ms). Disabled: `surface2` + `text3`.
/// `onPaper` is kept for callers and no longer changes anything.
struct CTAButtonStyle: ButtonStyle {
    enum Kind { case primary, outline, tertiary, destructive }
    var kind: Kind = .primary
    var onPaper = false
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        ActionButtonBody(label: configuration.label, pressed: configuration.isPressed, kind: kind, height: height)
    }
}

/// The body of an ActionButton (reads `isEnabled` itself).
struct ActionButtonBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    let kind: CTAButtonStyle.Kind
    let height: CGFloat
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        label
            .font(Trace.Fonts.cta)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isEnabled ? textColor : Trace.Colors.text3)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(shape.fill(isEnabled ? fillColor : Trace.Colors.surface2))
            .overlay(shape.strokeBorder(Trace.Colors.text.opacity(kind == .tertiary && isEnabled ? 0.2 : 0), lineWidth: 1.5))
            .contentShape(shape)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.09), value: pressed)
    }

    private var fillColor: Color {
        switch kind {
        case .primary: pressed ? Trace.Colors.benPressed : Trace.Colors.ben
        case .outline: pressed ? Trace.Colors.surface3 : Trace.Colors.surface2
        case .tertiary: .clear
        case .destructive: pressed ? Trace.Colors.critical.opacity(0.85) : Trace.Colors.critical
        }
    }

    private var textColor: Color {
        switch kind {
        case .primary, .destructive: Trace.Colors.onFill
        case .outline, .tertiary: Trace.Colors.text
        }
    }
}

/// A text link: Plex Sans 15 in `benText`, at least 44 pt tall.
struct TextLinkStyle: ButtonStyle {
    var onPaper = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Trace.Fonts.link)
            .foregroundStyle(Trace.Colors.benText)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// « ‹ Bureau » (§4 « où suis-je »): the previous screen's name in `benText`, top left, 44 pt.
struct BackLink: View {
    let title: String
    var identifier = "nav.back"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                Text(title).font(Trace.Fonts.link)
            }
            .foregroundStyle(Trace.Colors.benText)
            .frame(minHeight: Trace.Height.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier(identifier)
    }
}

/// SectionHeader (§5): Plex Sans 12/600 caps in `text2`, 10 pt below.
struct SectionHeader: View {
    let title: String
    var color: Color = Trace.Colors.text2

    var body: some View {
        Text(title)
            .fieldLabel(color)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Hold to confirm (§5 ActionButton « maintien »): `surface2`, filled in `ben` from left to right
/// while held (linear); let go early and it empties in 250 ms. Light haptic at the start, rigid at
/// the end. VoiceOver: a double tap asks for confirmation instead (`accessibilityConfirm`).
struct HoldToConfirmButton: View {
    let title: String
    var seconds: Double = Trace.Motion.holdToClose
    var enabled = true
    var identifier = "hold.confirm"
    /// VoiceOver: the alert shown instead of the hold (« Emma est responsable ? »).
    var accessibilityConfirm: String? = nil
    let action: () -> Void
    @State private var progress: CGFloat = 0
    @State private var askingVoiceOver = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        ZStack(alignment: .leading) {
            shape.fill(Trace.Colors.surface2)
            GeometryReader { geo in
                shape.fill(Trace.Colors.ben).frame(width: geo.size.width * progress)
            }
            Text(title)
                .font(Trace.Fonts.cta)
                .foregroundStyle(enabled ? Trace.Colors.text : Trace.Colors.text3)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
        }
        .frame(minHeight: Trace.Height.hold)
        .clipShape(shape)
        .contentShape(shape)
        .onLongPressGesture(minimumDuration: seconds, maximumDistance: 40) {
            guard enabled else { return }
            Haptics.rigid()
            action()
        } onPressingChanged: { pressing in
            guard enabled else { return }
            if pressing {
                Haptics.light()
                withAnimation(.linear(duration: seconds)) { progress = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(L10n.t("a11y.holdHint")))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard enabled else { return }
            if accessibilityConfirm != nil { askingVoiceOver = true } else { action() }
        }
        .accessibilityIdentifier(identifier)
        .alert(accessibilityConfirm ?? "", isPresented: $askingVoiceOver) {
            Button(L10n.t("common.confirm")) { action() }
            Button(L10n.t("common.cancel"), role: .cancel) {}
        }
    }
}

/// ReportCard (§5): a caption label and a data value (19/500) in its semantic colour.
struct ReportCard: View {
    let label: String
    let value: String
    var color: Color = Trace.Colors.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            Text(value).font(.custom(Trace.FontName.monoMedium, size: 19, relativeTo: .title3)).foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Logo (§H)

/// The app-icon tile (screens 01 and Paramètres › À propos). Never recoloured, never animated
/// beyond a fade. Below 96 pt, or if missing, the text mention.
struct LogoTile: View {
    var size: CGFloat = 188

    var body: some View {
        Group {
            if size >= 96, let image = ArtLibrary.image("logo_tile") {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
            } else {
                LogoText()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
        .accessibilityAddTraits(.isImage)
    }
}

/// The logo mention (V3: « CONCLUDE : ENQUÊTES » in Plex Mono 15/600, no paper banner).
struct LogoWordmark: View {
    var width: CGFloat = 330

    var body: some View {
        Group {
            LogoText()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
        .accessibilityAddTraits(.isHeader)
    }
}

/// « CONCLUDE : ENQUÊTES » in Plex Mono 15/600 (§6-00): the logo mention.
struct LogoText: View {
    var color: Color = Trace.Colors.text

    var body: some View {
        HStack(spacing: 0) {
            Text(verbatim: Brand.name + " : ").font(Trace.Fonts.wordmark).tracking(1.5)
            Text(verbatim: Brand.tagline).font(Trace.Fonts.wordmark).tracking(1.5).foregroundStyle(Trace.Colors.benText)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
    }
}

// MARK: - Stamps and seals (PNG, §G « Tampons »)

/// An inked stamp from `Art.xcassets/Stamps`: multiply on paper, normal on the desk. Falls back to
/// the drawn `StampMark` if the image is missing.
struct StampImage: View {
    let asset: String
    /// Text of the drawn fallback (and the VoiceOver label).
    let label: String
    var width: CGFloat = 160
    var onPaper = true
    var angle: Double = -8
    var color: Color = Trace.Colors.stamp

    var body: some View {
        Group {
            if let image = ArtLibrary.image(asset) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .rotationEffect(.degrees(angle))
            } else {
                StampMark(text: label, color: color, size: max(10, width / 7), angle: angle)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("a11y.stamp", label)))
    }
}

/// A stamp that falls (§J): scale 1.35 → 1, blur 2 → 0, 180 ms, then a 60 ms settle; 300 ms of
/// silence before it; heavy thud; success or warning haptic. With reduced motion it just appears.
struct FallingStampImage: View {
    let asset: String
    let label: String
    var width: CGFloat = 200
    var onPaper = true
    var angle: Double = -8
    var color: Color = Trace.Colors.stamp
    /// RÉSOLU (success) or NON RÉSOLU (warning).
    var success = true
    var delay: Double = 0.3
    var sound = true
    var onLanded: () -> Void = {}
    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        let still = systemReduceMotion || appReduceMotion
        StampImage(asset: asset, label: label, width: width, onPaper: onPaper, angle: angle, color: color)
            .scaleEffect(still ? 1 : (phase == 0 ? 1.35 : phase == 1 ? 0.98 : 1))
            .blur(radius: still || phase > 0 ? 0 : 2)
            .opacity(phase > 0 ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                if still {
                    withAnimation(.easeOut(duration: 0.2)) { phase = 2 }
                } else {
                    withAnimation(.easeIn(duration: 0.18)) { phase = 1 }
                    try? await Task.sleep(for: .milliseconds(180))
                    withAnimation(.easeOut(duration: 0.06)) { phase = 2 }
                }
                if sound { AudioDirector.shared.play(.stamp, volume: 0.9) }
                if success { Haptics.success() } else { Haptics.warning() }
                onLanded()
            }
    }
}

// MARK: - Prints

/// The investigator's photo (4:5): the chosen appearance, or initials on `surface3`.
struct PlayerPrint: View {
    let identity: PlayerIdentity
    var width: CGFloat = 150
    var border: CGFloat = 6

    var body: some View {
        PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                           width: width, height: width * 1.25)
            .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(identity.id.fullName))
            .accessibilityAddTraits(.isImage)
    }
}

/// A portrait, or the initials in Newsreader on blue-grey, same frame and ratio (§N).
struct PortraitOrInitials: View {
    let image: UIImage?
    let initials: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Trace.Colors.benBlue
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(initials)
                    .font(.custom(Trace.FontName.sansSemibold, fixedSize: min(width, height) * 0.34))
                    .foregroundStyle(Trace.Colors.portraitInitials)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

/// « ✓ Pièce 03 » (§5 EvidenceBadge « déjà versée »): what an element keeps once filed.
struct PieceBadge: View {
    let number: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: "✓")
            Text(PieceFormat.shortTitle(number))
        }
        .font(.custom(Trace.FontName.sansSemibold, fixedSize: 12))
        .foregroundStyle(Trace.Colors.successText)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Capsule().fill(Trace.Colors.bg))
        .background(Capsule().fill(Trace.Colors.tint(Trace.Colors.success)))
        .accessibilityIdentifier("piece.badge")
        .accessibilityLabel(Text(PieceFormat.title(number)))
    }
}

// MARK: - Sheets and errors

/// A confirmation sheet (pause…): a title, one line, one main button, one link. `surface`, radius
/// 20; used with `.presentationDetents` by the caller.
struct PaperConfirmSheet: View {
    let title: String
    var message: String? = nil
    let confirm: String
    var confirmID = "confirm.ok"
    var destructive = false
    let cancel: String
    var cancelID = "confirm.cancel"
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Trace.Colors.surface3).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
            Text(title)
                .font(Trace.Fonts.serifTitle(24))
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let message {
                Text(message)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button(confirm, action: onConfirm)
                .buttonStyle(CTAButtonStyle(kind: destructive ? .destructive : .primary))
                .accessibilityIdentifier(confirmID)
            Button(cancel, action: onCancel)
                .buttonStyle(TextLinkStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(cancelID)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Trace.Colors.surface.ignoresSafeArea())
    }
}

/// An error or notice card (§6-13): a title, a line, an optional action. Never a system alert.
struct PostItNote: View {
    let title: String
    let message: String
    var action: String? = nil
    var actionID = "postit.action"
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Trace.Fonts.headline).foregroundStyle(Trace.Colors.text)
            Text(message).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            if let action {
                Button(action, action: onAction)
                    .buttonStyle(CTAButtonStyle(kind: .outline, height: 48))
                    .accessibilityIdentifier(actionID)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: 340, alignment: .leading)
        .benCard(Trace.Colors.surface2)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Motion

/// True when either the system or the game asks for reduced motion.
struct ReducedMotionReader<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var system
    @AppStorage(Preferences.reduceMotionKey) private var app = false
    let content: (Bool) -> Content

    var body: some View { content(system || app) }
}
#endif
