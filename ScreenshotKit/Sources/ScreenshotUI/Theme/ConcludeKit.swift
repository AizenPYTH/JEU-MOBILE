#if os(iOS)
import SwiftUI
import UIKit

// Shared pieces of the V4 design (docs/design_v4) on the V3 UX: buttons (ivory on the desk, ink on
// paper), the back link, section labels, the hold, report cards, the logo, the PNG stamps, prints,
// the confirmation sheet and the post-it. Every screen outside the phone builds on these and on
// TraceDesign.swift.

extension Trace.Colors {
    /// A selected paper card.
    static let paperSelected = Color(hex: 0xF0E9D8)
    /// The white border of a print.
    static let printWhite = photoBorder
    /// Secondary ink on paper.
    static let inkMid = Color(hex: 0x3A3631)
    /// Secondary text on the desk.
    static let boneMid = ivoryMid
    /// Background of an identity photo and of its initials.
    static let benBlue = photoBg
    /// The player's handwriting.
    static let handInk = pen
    /// Text on a red fill.
    static let criticalText = ivory
    static let deskWarm = Color(hex: 0x3A2D20)
    static let deskDeep = Color(hex: 0x100D0A)
}

extension Trace.Fonts {
    /// Button label: Plex Sans 16/600, sentence case.
    static let cta = Font.custom(Trace.FontName.sansSemibold, size: 16, relativeTo: .body)
    /// A short capital label: Plex Mono 11/700.
    static let kicker = Font.custom(Trace.FontName.monoBold, size: 11, relativeTo: .caption)
    /// Screen title: Newsreader 30/600.
    static let monoTitle = Font.custom(Trace.FontName.serifSemibold, size: 30, relativeTo: .title)
    /// Plex Sans 15/600: names in a row, verbs, values.
    static let monoStrong = Font.custom(Trace.FontName.sansSemibold, size: 15, relativeTo: .subheadline)
    /// Links: Plex Sans 15.
    static let link = Font.custom(Trace.FontName.sans, size: 15, relativeTo: .body)
    /// Interface text: Plex Sans 16.
    static let uiBody = Font.custom(Trace.FontName.sans, size: 16, relativeTo: .body)
    /// A line in Newsreader 26.
    static let tagline = Font.custom(Trace.FontName.serif, size: 26, relativeTo: .title)
    /// Newsreader titles.
    static func serifTitle(_ size: CGFloat) -> Font { .custom(Trace.FontName.serifSemibold, size: size, relativeTo: .title2) }
}

// MARK: - Backgrounds

/// The desk with the lamp's pool (V4 `deskLamp`).
struct DeskBackdrop: View {
    var body: some View { TraceDesk() }
}

/// The accusation's desk (V4 `deskDeep`).
struct DeepDeskBackdrop: View {
    var body: some View {
        RadialGradient(colors: Trace.Colors.deskDeepGradient, center: .init(x: 0.5, y: 0.15), startRadius: 0, endRadius: 700)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons (§3 « Boutons »)

/// The main action of a screen, and its variants: 56 pt, radius 9, Plex Sans 16/600.
/// Primary on the desk: ivory with ink text; on paper or kraft (`onPaper`): ink with ivory text.
/// Secondary (`.outline`): 1.5 pt outline (ink on paper, ivory on the desk). Tertiary: text only.
/// Destructive: red with ivory text. Pressed: scale 0.98, 90 ms. Disabled: 40 %.
struct CTAButtonStyle: ButtonStyle {
    enum Kind { case primary, outline, tertiary, destructive }
    var kind: Kind = .primary
    var onPaper = false
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        ActionButtonBody(label: configuration.label, pressed: configuration.isPressed, kind: kind, onPaper: onPaper, height: height)
    }
}

/// The body of a V4 button (reads `isEnabled` itself).
struct ActionButtonBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    let kind: CTAButtonStyle.Kind
    var onPaper = false
    let height: CGFloat
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        label
            .font(Trace.Fonts.cta)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .foregroundStyle(textColor)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(shape.fill(fillColor))
            .overlay(shape.strokeBorder(strokeColor, lineWidth: kind == .outline ? 1.5 : 0))
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.09), value: pressed)
    }

    private var ink: Color { onPaper ? Trace.Colors.ink : Trace.Colors.ivory }

    private var fillColor: Color {
        switch kind {
        case .primary: onPaper ? Trace.Colors.ink : Trace.Colors.ivory
        case .outline, .tertiary: .clear
        case .destructive: onPaper ? Trace.Colors.red : Trace.Colors.redOnDesk
        }
    }

    private var textColor: Color {
        switch kind {
        case .primary: onPaper ? Trace.Colors.ivory : Trace.Colors.ink
        case .outline, .tertiary: ink
        case .destructive: Trace.Colors.ivory
        }
    }

    private var strokeColor: Color { kind == .outline ? ink : .clear }
}

/// A text link: Plex Sans 15 — ink2 underlined on paper, ivory2 on the desk; 44 pt tall.
struct TextLinkStyle: ButtonStyle {
    var onPaper = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Trace.Fonts.link)
            .foregroundStyle(onPaper ? Trace.Colors.ink2 : Trace.Colors.ivoryMid)
            .underline(onPaper)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// « ‹ Bureau » (§4 « où suis-je »): the previous screen's name in `benText`, top left, 44 pt.
struct BackLink: View {
    let title: String
    var identifier = "nav.back"
    /// Ink on paper or kraft; ivory on the desk.
    var onPaper = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                Text(title).font(Trace.Fonts.link)
            }
            .foregroundStyle(onPaper ? Trace.Colors.ink : Trace.Colors.ivoryMid)
            .frame(minHeight: Trace.Height.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier(identifier)
    }
}

/// A section label: Plex Mono 11/700 caps (V4), 10 pt below; ink2 on paper, ivory2 on the desk.
struct SectionHeader: View {
    let title: String
    var color: Color = Trace.Colors.ivory2

    var body: some View {
        Text(title)
            .fieldLabel(color)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Hold to confirm (V4 « maintien »): track #2A2522, filled in red from left to right
/// while held (linear); let go early and it empties in 250 ms. Light haptic at the start, rigid at
/// the end. VoiceOver: a double tap asks for confirmation instead (`accessibilityConfirm`).
struct BenHoldButton: View {
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
        // The label gives the button its size (60 pt, taller with large text); the fill lies behind
        // it — a GeometryReader in a ZStack would take the whole screen.
        Text(title)
            .font(Trace.Fonts.cta)
            .foregroundStyle(enabled ? Trace.Colors.ivory : Trace.Colors.ivory2)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: Trace.Height.hold)
            .background {
                ZStack(alignment: .leading) {
                    shape.fill(Trace.Colors.holdTrack)
                    GeometryReader { geo in
                        shape.fill(Trace.Colors.redOnDesk).frame(width: geo.size.width * progress)
                    }
                }
            }
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
    var color: Color = Trace.Colors.ivory

    var body: some View {
        HStack(spacing: 0) {
            Text(verbatim: Brand.name + " : ").font(Trace.Fonts.wordmark).tracking(1.5)
            Text(verbatim: Brand.tagline).font(Trace.Fonts.wordmark).tracking(1.5).foregroundStyle(Trace.Colors.kraft)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
    }
}

// MARK: - Stamps and seals (PNG, §G « Tampons »)

/// An inked stamp PNG from `Art.xcassets/Stamps` (V4 §2: CONFIDENTIEL, ÉLÉMENT CLÉ, RÉSOLU / NON
/// RÉSOLU): multiply on paper, normal on the desk; no rotation with « Augmenter le contraste ».
/// Falls back to the drawn `StampMark` if the image is missing.
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
                    .blendMode(onPaper ? .multiply : .normal)
                    .modifier(TiltModifier(degrees: angle))
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
                Haptics.rigid()
                onLanded()
            }
    }
}

// MARK: - Prints

/// The investigator's print (4:5): the chosen portrait, or initials on `photoBg`, white border.
struct PlayerPrint: View {
    let identity: PlayerIdentity
    var width: CGFloat = 150
    var border: CGFloat = 6

    var body: some View {
        PhotoPrint(border: border) {
            PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                               width: width, height: width * 1.25)
        }
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

/// « PIÈCE 03 »: the paper label an element keeps once filed (Plex Mono 9/700 ink on a label,
/// slightly tilted).
struct PieceBadge: View {
    let number: Int

    var body: some View {
        Text(PieceFormat.title(number))
            .font(.custom(Trace.FontName.monoBold, fixedSize: 9))
            .tracking(0.9)
            .foregroundStyle(Trace.Colors.ink)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Rectangle().fill(Trace.Colors.label))
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            .modifier(TiltModifier(degrees: -1.5))
            .accessibilityIdentifier("piece.badge")
            .accessibilityLabel(Text(PieceFormat.title(number)))
    }
}

// MARK: - Sheets and errors

/// A confirmation sheet on paper (pause…): a title, one line, one ink button, one link. Used with
/// `.presentationDetents` by the caller.
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
            Capsule().fill(Trace.Colors.ink2.opacity(0.35)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
            Text(title)
                .font(Trace.Fonts.serifTitle(24))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let message {
                Text(message)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button(confirm, action: onConfirm)
                .buttonStyle(CTAButtonStyle(kind: destructive ? .destructive : .primary, onPaper: true))
                .accessibilityIdentifier(confirmID)
            Button(cancel, action: onCancel)
                .buttonStyle(TextLinkStyle(onPaper: true))
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(cancelID)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }
}

/// An error, inside the fiction (V4 §4): a yellow post-it tilted −1°, title, text, [Réessayer].
struct PostItNote: View {
    let title: String
    let message: String
    var action: String? = nil
    var actionID = "postit.action"
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Trace.Fonts.headline).foregroundStyle(Trace.Colors.ink)
            Text(message).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
            if let action {
                Button(action, action: onAction)
                    .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true, height: 48))
                    .accessibilityIdentifier(actionID)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: 340, alignment: .leading)
        .background(Trace.Colors.postIt.shadow(.drop(color: .black.opacity(0.4), radius: 10, y: 8)))
        .modifier(TiltModifier(degrees: -1))
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
