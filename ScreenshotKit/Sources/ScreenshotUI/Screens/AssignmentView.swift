#if os(iOS)
import SwiftUI
import UIKit

/// Official assignment to the BEN, once, after case #001 (V3 flat re-skin of the former screen
/// 12): « Affectation officielle », « Bon travail, {Prénom Nom}. Vous êtes affectée au BEN. »
/// (« Dossier classé, … » if not solved), the cases waiting at the Bureau, then a card with the
/// investigator, the service number, the rank obtained and the signatory. One primary button:
/// [Aller au Bureau]. No paper, no stamp, no rotation. From here on the career layer (service
/// number, rank, profile) is visible.
struct AssignmentView: View {
    let identity: PlayerIdentity
    let rank: Rank
    let solved: Bool
    let remainingCases: Int
    let onDesk: () -> Void

    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// The investigator's photo in the card (56 × 70 pt, 4:5).
    private static let photoWidth: CGFloat = 56

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Trace.Spacing.xl)
                .padding(.top, Trace.Spacing.xxl + Trace.Spacing.s)
                .padding(.bottom, Trace.Spacing.xxl)
                .opacity(shown ? 1 : 0)
                .offset(y: shown || still ? 0 : Trace.Spacing.s)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(L10n.t("assignment.desk"), action: onDesk)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("assignment.desk")
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.top, Trace.Spacing.m)
                .padding(.bottom, Trace.Spacing.s)
                .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
                .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        }
        .background(Trace.Colors.bg.ignoresSafeArea())
        .task {
            withAnimation(still ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { shown = true }
            Haptics.success()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                SectionHeader(title: L10n.t("assignment.kicker"), color: Trace.Colors.benText)
                    .padding(.bottom, -Trace.Spacing.xs)
                Text(title)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            card
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assignment.view")
    }

    /// The investigator, service number, rank, and the bureau with its signatory.
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: Trace.Spacing.l) {
                PlayerPrint(identity: identity, width: Self.photoWidth)
                VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(identity.id.title)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, Trace.Spacing.m)
            .accessibilityElement(children: .combine)
            divider
            row(label: L10n.t("assignment.serviceNumber")) {
                Text(identity.id.serviceNumber)
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.benText)
            }
            divider
            row(label: L10n.t("profile.rank")) {
                StatusBadge(text: rank.title, color: Trace.Colors.benText, symbol: "●")
            }
            divider
            VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                Text(L10n.t("assignment.bureau"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.t("assignment.signatory"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
            }
            .padding(.top, Trace.Spacing.m)
            .accessibilityElement(children: .combine)
        }
        .padding(Trace.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
    }

    private var divider: some View {
        Rectangle().fill(Trace.Colors.line).frame(height: 1)
    }

    /// Label (section style) on the left, value on the right; 50 pt rows.
    private func row<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .center, spacing: Trace.Spacing.m) {
            Text(label).fieldLabel()
            Spacer(minLength: Trace.Spacing.s)
            value()
        }
        .frame(minHeight: Trace.Height.row)
        .accessibilityElement(children: .combine)
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
