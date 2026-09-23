#if os(iOS)
import SwiftUI
import CaseEngine

/// Top of every app root: "‹ Accueil", then the app's icon, name and a context line
/// ("Septembre 2026", "3 non lus"…). The player never has to guess which app is open.
struct AppBar<Trailing: View>: View {
    /// nil = the phone-wide search.
    let app: AppID?
    var title: String? = nil
    var subtitle: String? = nil
    let onHome: () -> Void
    @ViewBuilder var trailing: Trailing

    private var accent: Color { app.map(Theme.appAccent) ?? Theme.Colors.info }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
            Button(action: onHome) {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    Text(L10n.t("nav.home")).font(Theme.Fonts.bodyLarge)
                }
                .foregroundStyle(accent)
                .frame(minHeight: Theme.Size.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("app.back")

            HStack(alignment: .center, spacing: Theme.Spacing.s4) {
                icon
                VStack(alignment: .leading, spacing: 1) {
                    Text(title ?? app?.title ?? "")
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("app.title")
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: Theme.Spacing.s3)
                trailing
            }
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .padding(.bottom, Theme.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.bgBase.opacity(0.97))
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line2).frame(height: 1) }
    }

    @ViewBuilder
    private var icon: some View {
        if let app {
            AppTileGlyph(app: app, size: Theme.Size.headerIcon)
        } else {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: Theme.Size.headerIcon, height: Theme.Size.headerIcon)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.Colors.bgSelected))
        }
    }
}

extension AppBar where Trailing == EmptyView {
    init(app: AppID?, title: String? = nil, subtitle: String? = nil, onHome: @escaping () -> Void) {
        self.init(app: app, title: title, subtitle: subtitle, onHome: onHome) { EmptyView() }
    }
}

extension View {
    /// Root screen of an app: custom header on top, system bar hidden. The navigation title stays
    /// set so the next screen's back button reads "‹ Messages", "‹ Plans"…
    func appRoot<Trailing: View>(_ app: AppID, subtitle: String?, session: GameSession,
                                 @ViewBuilder trailing: () -> Trailing) -> some View {
        let bar = AppBar(app: app, subtitle: subtitle, onHome: { session.goHome() }, trailing: trailing)
        return self
            .navigationTitle(app.title)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { bar }
    }

    func appRoot(_ app: AppID, subtitle: String?, session: GameSession) -> some View {
        appRoot(app, subtitle: subtitle, session: session) { EmptyView() }
    }
}

/// Section title inside an app: accent overline + optional count ("AUJOURD'HUI · 3").
struct AppSectionHeader: View {
    let title: String
    var count: Int? = nil
    var color: Color = Theme.Colors.textSecondary

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Text(title).overline(color)
            if let count {
                Text("\(count)").font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .padding(.top, Theme.Spacing.s6)
        .padding(.bottom, Theme.Spacing.s3)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A grouped card (settings-style): rounded, raised, hairline separators handled by rows.
struct CardGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.line1))
            .padding(.horizontal, Theme.Spacing.marginCompact)
    }
}

/// Thin separator inside a card, inset from the leading icon.
struct RowDivider: View {
    var leading: CGFloat = Theme.Spacing.s5

    var body: some View {
        Rectangle().fill(Theme.Colors.line1).frame(height: 1).padding(.leading, leading)
    }
}

/// Coloured square with a white symbol (settings-style row icon).
struct SymbolTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous).fill(color))
            .accessibilityHidden(true)
    }
}

/// Small time-cost tag shown next to actions that spend seconds ("−10 s").
struct CostTag: View {
    let seconds: Int

    var body: some View {
        Text(L10n.f("common.cost", seconds))
            .font(Theme.Fonts.dataSmall)
            .foregroundStyle(Theme.Colors.signal)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(Capsule().fill(Theme.Colors.signalTint))
    }
}
#endif
