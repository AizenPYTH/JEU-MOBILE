#if os(iOS)
import SwiftUI
import CaseEngine

/// Messages: conversation list + search across every message (search costs time).
struct MessagesListView: View {
    let session: GameSession
    @State private var query = ""
    @State private var results: [SearchHit]?

    var body: some View {
        let game = session.game
        List {
            if let results {
                Section {
                    if results.isEmpty {
                        Text(L10n.t("messages.noResult"))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    ForEach(results) { hit in
                        Button {
                            session.open(.conversation(hit.conversationID, focus: hit.message.id))
                        } label: {
                            SearchHitRow(hit: hit, game: game)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(L10n.f("messages.results", results.count))
                }
            } else {
                ForEach(game.conversations) { summary in
                    Button {
                        session.open(.conversation(summary.id))
                    } label: {
                        ConversationRow(summary: summary, game: game)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.Colors.background)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle(AppID.messages.title)
        .searchable(text: $query, prompt: Text(L10n.f("messages.searchPrompt", session.rules.timeCosts.search)))
        .onSubmit(of: .search) {
            results = session.search(query)
        }
        .onChange(of: query) { _, newValue in
            if newValue.isEmpty { results = nil }
        }
    }
}

struct ConversationRow: View {
    let summary: ConversationSummary
    let game: Investigation

    var body: some View {
        let conversation = summary.conversation
        HStack(spacing: Theme.Spacing.m) {
            Circle()
                .fill(summary.unread > 0 ? Theme.Colors.link : .clear)
                .frame(width: 9, height: 9)
            if conversation.isGroup {
                GroupAvatar(contacts: conversation.participants.compactMap { game.contact($0) })
            } else {
                Avatar(contact: game.contact(conversation.participants[0]))
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack {
                    Text(game.title(of: conversation))
                        .font(Theme.Fonts.headline)
                        .lineLimit(1)
                    Spacer()
                    if let last = summary.last {
                        Text(PhoneFormat.relative(last.message.at, now: game.phoneNow))
                            .font(Theme.Fonts.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Text(preview)
                    .font(Theme.Fonts.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
    }

    private var preview: String {
        guard let last = summary.last else { return "" }
        if last.state == .removedBySender { return L10n.t("messages.removed") }
        let prefix = summary.conversation.isGroup ? "\(game.name(of: last.message.from).split(separator: " ").first ?? "") : " : ""
        return prefix + (last.message.text ?? L10n.t("item.photo"))
    }
}

struct SearchHitRow: View {
    let hit: SearchHit
    let game: Investigation

    var body: some View {
        let message = hit.message.message
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            HStack {
                Text(game.index.conversation(hit.conversationID).map { game.title(of: $0) } ?? "")
                    .font(Theme.Fonts.subheadline.weight(.semibold))
                Spacer()
                Text(PhoneFormat.dayAndTime(message.at))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Text("\(game.name(of: message.from)) : \(message.text ?? L10n.t("item.photo"))")
                .font(Theme.Fonts.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, Theme.Spacing.xxs)
        .contentShape(Rectangle())
    }
}

/// One conversation: bubbles, day separators, exact times, older pages, draft.
struct ConversationView: View {
    let conversationID: String
    let focus: String?
    let session: GameSession

    var body: some View {
        let game = session.game
        let conversation = game.index.conversation(conversationID)
        let messages = game.loadedMessages(in: conversationID)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xs) {
                    if game.hasOlderMessages(in: conversationID) {
                        Button {
                            session.perform { $0.loadOlderMessages(in: conversationID) }
                        } label: {
                            Label(L10n.f("messages.loadOlder", session.rules.timeCosts.loadOlderMessages), systemImage: "clock.arrow.circlepath")
                                .font(Theme.Fonts.footnote.weight(.medium))
                                .padding(.vertical, Theme.Spacing.s)
                                .padding(.horizontal, Theme.Spacing.l)
                                .background(Capsule().fill(Theme.Colors.surfaceElevated))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.vertical, Theme.Spacing.m)
                    } else {
                        Text(L10n.t("messages.start"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .padding(.vertical, Theme.Spacing.m)
                    }
                    ForEach(Array(messages.enumerated()), id: \.element.id) { offset, visible in
                        let previous = offset > 0 ? messages[offset - 1].message : nil
                        if previous == nil || visible.message.at.seconds - (previous?.at.seconds ?? 0) > 3_600 {
                            Text(PhoneFormat.separator(visible.message.at, now: game.phoneNow))
                                .font(Theme.Fonts.caption.weight(.medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .padding(.top, Theme.Spacing.m)
                        }
                        MessageBubble(visible: visible,
                                      senderName: conversation?.isGroup == true && previous?.from != visible.message.from
                                          ? game.name(of: visible.message.from) : nil,
                                      highlighted: visible.id == focus,
                                      session: session)
                            .id(visible.id)
                            .onAppear { session.markSeen(ItemRef(.message, visible.id)) }
                    }
                    if let draft = conversation?.draft {
                        DraftBubble(draft: draft)
                            .onAppear { session.markSeen(ItemRef(.draft, draft.id)) }
                            .pinnable(ItemRef(.draft, draft.id), session: session)
                            .id(draft.id)
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.l)
            }
            .defaultScrollAnchor(.bottom)
            .onAppear {
                if let focus { proxy.scrollTo(focus, anchor: .center) }
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle(conversation.map { game.title(of: $0) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let conversation, !conversation.isGroup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.open(.contact(conversation.participants[0]))
                    } label: {
                        Avatar(contact: game.contact(conversation.participants[0]), size: Theme.Size.avatarS)
                    }
                    .accessibilityLabel(Text(L10n.t("a11y.openContact")))
                }
            }
        }
    }
}

struct MessageBubble: View {
    let visible: VisibleMessage
    let senderName: String?
    let highlighted: Bool
    let session: GameSession

    var body: some View {
        let message = visible.message
        let mine = message.isFromOwner
        VStack(alignment: mine ? .trailing : .leading, spacing: Theme.Spacing.xxs) {
            if let senderName {
                Text(senderName)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.m)
            }
            if visible.state == .removedBySender {
                Label(L10n.t("messages.removed"), systemImage: "nosign")
                    .font(Theme.Fonts.subheadline.italic())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.bubble).strokeBorder(Theme.Colors.separator))
            } else {
                if let photoID = message.photo, let photo = session.game.index.photo(photoID) {
                    Button {
                        session.open(.photo(photoID))
                    } label: {
                        GeneratedPhoto(scene: photo.scene, seed: photo.id)
                            .frame(width: 200, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.bubble))
                    }
                    .buttonStyle(.plain)
                }
                if let text = message.text {
                    Text(text)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                                .fill(mine ? Theme.Colors.bubbleOwner : Theme.Colors.bubbleOther)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                                .strokeBorder(highlighted ? Theme.Colors.warning : (visible.state == .recovered ? Theme.Colors.recovered : .clear),
                                              lineWidth: highlighted || visible.state == .recovered ? 2 : 0)
                        )
                }
            }
            HStack(spacing: Theme.Spacing.xs) {
                if visible.state == .recovered {
                    Text(L10n.t("messages.recovered"))
                        .foregroundStyle(Theme.Colors.recovered)
                }
                Text(PhoneFormat.time(message.at))
            }
            .font(Theme.Fonts.caption2)
            .foregroundStyle(Theme.Colors.textTertiary)
            .padding(.horizontal, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
        .padding(mine ? .leading : .trailing, Theme.Spacing.xxl + Theme.Spacing.l)
        .pinnable(ItemRef(.message, message.id), session: session)
    }
}

struct DraftBubble: View {
    let draft: Draft

    var body: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
            Text(draft.text)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary.opacity(0.8))
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                        .strokeBorder(Theme.Colors.bubbleOwner, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
            Text(L10n.f("messages.draftAt", PhoneFormat.dayAndTime(draft.at)))
                .font(Theme.Fonts.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, Theme.Spacing.xxl + Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
    }
}
#endif
