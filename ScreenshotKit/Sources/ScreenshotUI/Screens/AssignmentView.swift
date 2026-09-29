#if os(iOS)
import SwiftUI
import UIKit

/// Official assignment to the BEN, once, after case #001 (V4 « Dossier lisible »): an official
/// letter on paper, laid on the desk. Letterhead « BUREAU DES ENQUÊTES NUMÉRIQUES », « Affectation
/// officielle », « Bon travail, {Prénom Nom}. Vous êtes affectée au BEN. » (« Dossier classé, … »
/// if not solved), the cases waiting at the Bureau; the investigator's print stapled to the letter,
/// name, service number and rank in Plex Mono; the BEN seal and Lacaze's signature. One primary
/// button on the desk: [Aller au Bureau]. From here on the career layer (service number, rank,
/// profile) is visible.
struct AssignmentView: View {
    let identity: PlayerIdentity
    let rank: Rank
    let solved: Bool
    let remainingCases: Int
    let onDesk: () -> Void

    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// The investigator's print on the letter (4:5).
    private static let photoWidth: CGFloat = 84
    /// The BEN seal, stamped in blue next to the signature.
    private static let sealWidth: CGFloat = 88

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        ScrollView {
            letter
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.top, Trace.Spacing.xxl)
                .padding(.bottom, Trace.Spacing.xxl)
                .opacity(shown ? 1 : 0)
                .offset(y: shown || still ? 0 : Trace.Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(L10n.t("assignment.desk"), action: onDesk)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("assignment.desk")
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.top, Trace.Spacing.m)
                .padding(.bottom, Trace.Spacing.s)
                .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
                .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        }
        .background(DeskBackdrop())
        .task {
            AudioDirector.shared.play(.paper, volume: 0.7)
            withAnimation(still ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { shown = true }
            Haptics.success()
        }
    }

    // MARK: Letter

    /// The letter: a paper sheet, never tilted; only the stapled print leans (≤ 1.5°).
    private var letter: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
            letterhead
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                Text(title)
                    .font(Trace.Fonts.serifTitle(26))
                    .foregroundStyle(Trace.Colors.ink)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            agent
            signatures
        }
        .padding(.horizontal, Trace.Spacing.sheet)
        .padding(.top, Trace.Spacing.xxl)
        .padding(.bottom, Trace.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assignment.view")
    }

    /// « BUREAU DES ENQUÊTES NUMÉRIQUES », a 1.5 pt ink rule, « AFFECTATION OFFICIELLE » in red.
    private var letterhead: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.t("assignment.bureau"))
                .font(Trace.Fonts.data)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(Trace.Colors.ink)
                .frame(height: 1.5)
                .accessibilityHidden(true)
            Text(L10n.t("assignment.kicker"))
                .fieldLabel(Trace.Colors.red)
                .padding(.top, Trace.Spacing.xs)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The investigator's print, stapled, with the name, the title, the service number and the rank.
    private var agent: some View {
        HStack(alignment: .top, spacing: Trace.Spacing.l) {
            PlayerPrint(identity: identity, width: Self.photoWidth, border: 5)
                .overlay(alignment: .top) { Staple().offset(y: -4) }
                .tilt(identity.id.fullName)
                .padding(.top, Trace.Spacing.xs)
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.personName)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(identity.id.title)
                        .fieldLabel(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                field(label: L10n.t("assignment.serviceNumber"), value: identity.id.serviceNumber)
                field(label: L10n.t("profile.rank"), value: rank.title(feminine: identity.id.isFeminine).uppercased())
            }
            Spacer(minLength: 0)
        }
    }

    /// LABEL over a Plex Mono value.
    private func field(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).fieldLabel(Trace.Colors.ink2)
            Text(value)
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// A dashed rule, then the BEN seal (blue, multiply) and Lacaze's visa; stacked when they do not
    /// fit side by side.
    private var signatures: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.l) {
            Rectangle()
                .fill(Trace.Colors.ink2.opacity(0.25))
                .frame(height: 1)
                .accessibilityHidden(true)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: Trace.Spacing.l) {
                    seal
                    Spacer(minLength: Trace.Spacing.l)
                    ClosingVisa()
                }
                VStack(alignment: .leading, spacing: Trace.Spacing.l) {
                    seal
                    ClosingVisa(alignment: .leading)
                }
            }
        }
    }

    private var seal: some View {
        StampImage(asset: "seal_ben_bleu", label: L10n.t("assignment.bureau"), width: Self.sealWidth,
                   onPaper: true, angle: -8, color: Trace.Colors.pen)
            .padding(Trace.Spacing.xs)
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
