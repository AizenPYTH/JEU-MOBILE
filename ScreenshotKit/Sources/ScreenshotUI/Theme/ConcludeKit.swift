#if os(iOS)
import SwiftUI
import UIKit

// Shared pieces of the final design (handoff V3 §G): the few tokens it adds, the call-to-action
// buttons, the logo, the stamp images, the player's print, the confirmation sheet and the post-it.
// Every screen outside the phone builds on these.

extension Trace.Colors {
    /// Selected paper (a chosen card).
    static let paperSelected = Color(hex: 0xF0E9D8)
    /// White border of a photo print.
    static let printWhite = Color(hex: 0xFBF9F4)
    /// Secondary ink on paper.
    static let inkMid = Color(hex: 0x3A3631)
    /// Secondary text on the desk, links.
    static let boneMid = Color(hex: 0xC9C3B6)
    /// Blue-grey of the BEN, portrait backgrounds.
    static let benBlue = Color(hex: 0x6F7A86)
    /// Initials on a missing portrait.
    static let portraitInitials = Color(hex: 0xE4E7EA)
    /// The player's handwriting.
    static let handInk = Color(hex: 0x2B3A5A)
    /// Text on a red (critical) label.
    static let criticalText = Color(hex: 0xF6EDEA)
    /// Hold-to-confirm track.
    static let holdTrack = Color(hex: 0x2A2825)
    /// The desk gradient (§G): warm lamp light → dark wood → launch black.
    static let deskWarm = Color(hex: 0x2E261D)
    static let deskDeep = Color(hex: 0x12100E)
}

extension Trace.Fonts {
    /// Call-to-action label: Plex Mono 13/700, caps.
    static let cta = Font.custom(Trace.FontName.monoBold, size: 13, relativeTo: .callout)
    /// Kicker: Plex Mono 10/700.
    static let kicker = Font.custom(Trace.FontName.monoBold, size: 10, relativeTo: .caption2)
    /// Mono screen title: Plex Mono 18/700 (« QUI ENQUÊTE ? », « QUI EST RESPONSABLE ? »).
    static let monoTitle = Font.custom(Trace.FontName.monoBold, size: 18, relativeTo: .title3)
    /// Plex Mono 11/700 (the three verbs, values).
    static let monoStrong = Font.custom(Trace.FontName.monoBold, size: 11, relativeTo: .caption)
    /// Text links on the desk: Geist 15.
    static let link = Font.custom(Theme.FontName.regular, size: 15, relativeTo: .body)
    /// Interface text on the desk: Geist 16.
    static let uiBody = Font.custom(Theme.FontName.regular, size: 16, relativeTo: .body)
    /// Title-screen tagline: Newsreader 27/500.
    static let tagline = Font.custom(Trace.FontName.serifMedium, size: 27, relativeTo: .title)
    /// Newsreader titles (21–30).
    static func serifTitle(_ size: CGFloat) -> Font { .custom(Trace.FontName.serifSemibold, size: size, relativeTo: .title2) }
}

// MARK: - Backgrounds

/// The desk of the final design: radial #2E261D → #12100E → #0A0908.
struct DeskBackdrop: View {
    var body: some View {
        RadialGradient(colors: [Trace.Colors.deskWarm, Trace.Colors.deskDeep, Trace.Colors.launch],
                       center: .init(x: 0.5, y: 0.1), startRadius: 0, endRadius: 720)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons (§B-1, §F, §G « Boutons »)

/// The one main action of a screen, and its variants. 56 pt, radius 6, Plex Mono 13/700 caps.
/// `onPaper` switches the colours: the full button is bone on the desk, ink on paper.
struct CTAButtonStyle: ButtonStyle {
    enum Kind { case primary, outline, destructive }
    var kind: Kind = .primary
    var onPaper = false
    var height: CGFloat = 56
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        return configuration.label
            .font(Trace.Fonts.cta)
            .tracking(2)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .foregroundStyle(textColor.opacity(isEnabled ? 1 : 0.42))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(shape.fill(isEnabled ? fillColor : .clear))
            .overlay(shape.strokeBorder(strokeColor, lineWidth: isEnabled ? (kind == .outline ? 1.5 : 0) : 1.5))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var fillColor: Color {
        switch kind {
        case .primary: onPaper ? Trace.Colors.ink : Trace.Colors.bone
        case .outline: .clear
        case .destructive: Trace.Colors.stamp
        }
    }

    private var textColor: Color {
        switch kind {
        case .primary: onPaper ? Trace.Colors.bone : Trace.Colors.ink
        case .outline: onPaper ? Trace.Colors.ink : Trace.Colors.bone
        case .destructive: Trace.Colors.criticalText
        }
    }

    private var strokeColor: Color {
        let base = onPaper ? Trace.Colors.ink : Trace.Colors.bone
        return isEnabled ? base : base.opacity(0.18)
    }
}

/// A secondary action: a text link, Geist 15, at least 44 pt tall.
struct TextLinkStyle: ButtonStyle {
    var onPaper = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Trace.Fonts.link)
            .foregroundStyle(onPaper ? Trace.Colors.inkSoft : Trace.Colors.boneMid)
            .underline(onPaper)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
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
                    .shadow(color: .black.opacity(0.7), radius: 30, y: 30)
            } else {
                LogoText()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
        .accessibilityAddTraits(.isImage)
    }
}

/// The paper banner of the logo (screens 02 and 02b): 330 × 148 pt, −1.5°.
struct LogoWordmark: View {
    var width: CGFloat = 330

    var body: some View {
        Group {
            if width >= 240, let image = ArtLibrary.image("logo_wordmark") {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(990.0 / 444.0, contentMode: .fit)
                    .frame(width: width)
                    .rotationEffect(.degrees(-1.5))
            } else {
                LogoText()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Brand.full))
        .accessibilityAddTraits(.isHeader)
    }
}

/// « CONCLUDE » over « ENQUÊTES », a red rule between: the logo when it would be too small.
struct LogoText: View {
    var color: Color = Trace.Colors.bone

    var body: some View {
        VStack(spacing: 6) {
            Text(Brand.name).font(.custom(Trace.FontName.monoBold, fixedSize: 18)).tracking(5.4)
            Rectangle().fill(Trace.Colors.stamp).frame(width: 44, height: 1.5)
            Text(Brand.tagline).font(.custom(Trace.FontName.mono, fixedSize: 11)).tracking(4)
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
                    .blendMode(onPaper ? .multiply : .normal)
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

/// The investigator's photo print (4:5): the chosen appearance, or initials on BEN blue.
struct PlayerPrint: View {
    let identity: PlayerIdentity
    var width: CGFloat = 150
    var border: CGFloat = 6

    var body: some View {
        PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                           width: width, height: width * 1.25)
            .padding(border)
            .background(Trace.Colors.printWhite)
            .shadow(color: .black.opacity(0.25), radius: 5, y: 4)
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
                    .font(.custom(Trace.FontName.serifMedium, fixedSize: min(width, height) * 0.36))
                    .foregroundStyle(Trace.Colors.portraitInitials)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

/// « PIÈCE 0N »: the paper label left on an element once filed (Plex Mono 9/700 on paper).
struct PieceBadge: View {
    let number: Int

    var body: some View {
        Text(PieceFormat.title(number))
            .font(.custom(Trace.FontName.monoBold, fixedSize: 9))
            .tracking(1)
            .foregroundStyle(Trace.Colors.ink)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 1.5).fill(Trace.Colors.paper))
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            .rotationEffect(.degrees(-2))
            .accessibilityIdentifier("piece.badge")
            .accessibilityLabel(Text(PieceFormat.title(number)))
    }
}

// MARK: - Sheets and notes

/// A paper confirmation sheet (pause, « Aucune pièce au dossier »…): a title, one line, one full
/// button, one link. Used with `.presentationDetents` by the caller.
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
            Capsule().fill(Trace.Colors.inkFaint.opacity(0.5)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
            Text(title)
                .font(Trace.Fonts.serifTitle(22))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let message {
                Text(message)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.inkMid)
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
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }
}

/// An error, inside the fiction: a yellow post-it (§B-6, §N). Never a system alert.
struct PostItNote: View {
    let title: String
    let message: String
    var action: String? = nil
    var actionID = "postit.action"
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Trace.Fonts.kicker).tracking(1.6).textCase(.uppercase).foregroundStyle(Trace.Colors.stamp)
            Text(message).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let action {
                Button(action, action: onAction)
                    .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true, height: 44))
                    .accessibilityIdentifier(actionID)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: 320, alignment: .leading)
        .paper(Trace.Colors.noteYellow, lifted: true)
        .rotationEffect(.degrees(-1.5))
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
