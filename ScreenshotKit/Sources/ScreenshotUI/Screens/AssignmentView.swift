#if os(iOS)
import SwiftUI
import UIKit

/// 12 · Official assignment to the BEN (final handoff §F-12), once, after case #001: the BEN seal,
/// « Bon travail, {Prénom Nom}. Vous êtes affectée au BEN. » (« Dossier classé, … » if not solved),
/// the cases waiting at the Bureau, the service number, Lacaze's signature and the rank stamp
/// falling after 0.5 s. From here on the career layer (service number, rank, profile) is visible.
struct AssignmentView: View {
    let identity: PlayerIdentity
    let rank: Rank
    let solved: Bool
    let remainingCases: Int
    let onDesk: () -> Void

    @State private var shown = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private static let sealSize: CGFloat = 64
    private static let signatureWidth: CGFloat = 150
    private static let rankStampWidth: CGFloat = 140
    /// The rank stamp falls once the sheet is in place.
    private static let stampDelay = 0.5

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        ScrollView {
            sheet
                .padding(.horizontal, 16)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .opacity(shown ? 1 : 0)
                .offset(y: shown || still ? 0 : 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(L10n.t("assignment.desk"), action: onDesk)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("assignment.desk")
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 10)
        }
        .background(DeskBackdrop())
        .task {
            AudioDirector.shared.play(.paper, volume: 0.4)
            withAnimation(still ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { shown = true }
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                StampImage(asset: "seal_ben_bleu", label: L10n.t("assignment.bureau"), width: Self.sealSize,
                           onPaper: true, angle: 0, color: Trace.Colors.benBlue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("assignment.bureau"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.t("assignment.kicker"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Rectangle().fill(Trace.Colors.ink.opacity(0.2)).frame(height: 1)
            Text(title)
                .font(Trace.Fonts.serifTitle(24))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(Trace.Fonts.prose)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.t("assignment.serviceNumber")).fieldLabel()
                Text(identity.id.serviceNumber + " · " + identity.id.title)
                    .font(Trace.Fonts.fieldValueLarge)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    signature
                    rankStamp
                }
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    signature
                    Spacer(minLength: 8)
                    rankStamp
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assignment.view")
    }

    /// Lacaze's visa and his name, printed.
    private var signature: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let image = ArtLibrary.image("signature_lacaze_bleu") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.signatureWidth)
                    .blendMode(.multiply)
                    .accessibilityHidden(true)
            }
            Text(L10n.t("assignment.signatory"))
                .font(Trace.Fonts.monoSmall)
                .foregroundStyle(Trace.Colors.inkSoft)
        }
    }

    /// The rank obtained, stamped (sound and haptic come with the fall).
    private var rankStamp: some View {
        FallingStampImage(asset: rank.stampAsset, label: rank.title, width: Self.rankStampWidth,
                          onPaper: true, angle: -8, success: true, delay: Self.stampDelay)
    }

    /// « Bon travail, Élise Morel. Vous êtes affectée au BEN. »
    private var title: String {
        let name = identity.id.fullName
        if solved {
            return identity.id.isFeminine ? L10n.f("assignment.titleSolvedF", name) : L10n.f("assignment.titleSolvedM", name)
        }
        return identity.id.isFeminine ? L10n.f("assignment.titleFiledF", name) : L10n.f("assignment.titleFiledM", name)
    }

    /// « 4 dossiers vous attendent au Bureau. Votre carte d'agent et votre rang sont dans votre profil. »
    private var message: String {
        let profile = L10n.t("assignment.profile")
        guard remainingCases > 0 else { return profile }
        return L10n.f("assignment.waiting", remainingCases) + " " + profile
    }
}
#endif
