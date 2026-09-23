#if os(iOS)
import SwiftUI
import CaseEngine

/// Screen 11 — search across the phone: messages, calendar, notes, mail, browser, contacts.
/// Each query costs the same time as a search in Messages. Chips filter by app (with counts);
/// results are grouped by app, oldest first; tapping one opens it in its app.
struct GlobalSearchView: View {
    let session: GameSession
    @State private var query = ""
    @State private var searched = ""
    @State private var results: [PhoneSearchResult]?
    @State private var filter: AppID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SearchField(text: $query, prompt: L10n.f("search.prompt", session.rules.timeCosts.search)) {
                    searched = query
                    filter = nil
                    results = session.searchPhone(query)
                } onClear: {
                    results = nil
                }
                .accessibilityIdentifier("search.field")
                .padding(.horizontal, Theme.Spacing.marginList)
                .padding(.vertical, Theme.Spacing.s4)

                if let results {
                    chips(results)
                    if results.isEmpty {
                        EmptyStateView(title: L10n.f("search.emptyTitle", searched), message: L10n.t("search.emptyMessage"))
                    }
                    ForEach(PhoneSearch.apps.filter { filter == nil || filter == $0 }, id: \.self) { app in
                        let group = results.filter { $0.app == app }
                        if !group.isEmpty {
                            HStack(spacing: Theme.Spacing.s3) {
                                AppTileGlyph(app: app, size: 22)
                                Text(L10n.f("search.group", app.title.uppercased(), group.count))
                                    .overline(Theme.appAccent(app))
                            }
                            .padding(.horizontal, Theme.Spacing.marginList)
                            .padding(.top, Theme.Spacing.s5)
                            .padding(.bottom, Theme.Spacing.s2)
                            ForEach(group) { result in
                                Button { session.open(result) } label: {
                                    GlobalSearchRow(result: result, query: searched)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("search.result.\(result.ref.description)")
                            }
                        }
                    }
                } else {
                    Text(L10n.t("search.help"))
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.marginList)
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .background(Theme.Colors.bgBase)
        .navigationTitle(L10n.t("search.title"))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            AppBar(app: nil, title: L10n.t("search.title"), subtitle: L10n.t("search.subtitle"), onHome: { session.goHome() })
        }
    }

    /// "Tout (12)" · "Messages (7)" · … — only apps with results.
    private func chips(_ results: [PhoneSearchResult]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s3) {
                chip(L10n.f("search.all", results.count), selected: filter == nil) { filter = nil }
                ForEach(PhoneSearch.apps, id: \.self) { app in
                    let count = results.filter { $0.app == app }.count
                    if count > 0 {
                        chip("\(app.title) (\(count))", selected: filter == app) { filter = app }
                            .accessibilityIdentifier("search.chip.\(app.rawValue)")
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.marginList)
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            Text(label)
                .font(Theme.Fonts.calloutStrong)
                .foregroundStyle(selected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.s4)
                .frame(height: 32)
                .background(Capsule().fill(selected ? Theme.Colors.bgSelected : Theme.Colors.bgRaised))
                .overlay(Capsule().strokeBorder(selected ? Theme.Colors.textPrimary : Theme.Colors.line1, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Name + mono date, then the excerpt on 2 lines with the term highlighted.
struct GlobalSearchRow: View {
    let result: PhoneSearchResult
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
            HStack(alignment: .firstTextBaseline) {
                Text(Highlighter.attributed(result.title, query: query))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Spacer()
                if let at = result.at {
                    Text(PhoneFormat.shortDay(at) + " · " + PhoneFormat.time(at))
                        .font(Theme.Fonts.data)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            if !result.excerpt.isEmpty {
                Text(Highlighter.attributed(result.excerpt, query: query))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .padding(.vertical, Theme.Spacing.s4)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line1).frame(height: 1) }
        .contentShape(Rectangle())
    }
}
#endif
