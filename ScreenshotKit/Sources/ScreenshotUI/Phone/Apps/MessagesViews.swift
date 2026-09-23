#if os(iOS)
import SwiftUI
import CaseEngine

/// Screen 09 — conversation list + search in every message (search costs time).
struct MessagesListView: View {
    let session: GameSession
    @State private var query = ""
    @State private var results: [SearchHit]?

    var body: some View {
        let game = session.game
        let unread = game.conversations.reduce(0) { $0 + $1.unread }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SearchField(text: $query, prompt: L10n.f("messages.searchPrompt", session.rules.timeCosts.search)) {
                    results = session.search(query)
                } onClear: {
                    results = nil
                }
                .padding(.horizontal, Theme.Spacing.marginList)
                .padding(.vertical, Theme.Spacing.s4)

                if let results {
                    Text(L10n.f("messages.results", results.count))
                        .overline()
                        .padding(.horizontal, Theme.Spacing.marginList)
                        .padding(.bottom, Theme.Spacing.s3)
                    if results.isEmpty {
                        EmptyStateView(title: L10n.f("search.emptyTitle", query), message: L10n.t("search.emptyMessage"))
                    }
                    ForEach(results) { hit in
                        Button {
                            session.open(.conversation(hit.conversationID, focus: hit.message.id))
                        } label: {
                            SearchHitRow(hit: hit, query: query, game: game)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    if game.conversations.isEmpty {
                        EmptyStateView(title: L10n.t("empty.messagesTitle"), message: L10n.t("empty.messagesMessage"))
                    }
                    ForEach(game.conversations) { summary in
                        Button {
                            session.open(.conversation(summary.id))
                        } label: {
                            ConversationRow(summary: summary, game: game)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("conversation.\(summary.id)")
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .background(Theme.Colors.bgBase)
        .appRoot(.messages, subtitle: L10n.f("n.conversations", game.conversations.count) + " · " + L10n.f("n.unread", unread), session: session)
    }
}

/// SearchField: h 40, r 12; submit = search (costs time).
struct SearchField: View {
    @Binding var text: String
    let prompt: String
    let onSubmit: () -> Void
    let onClear: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.textTertiary)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(Theme.Colors.textTertiary))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .tint(Theme.Colors.signal)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { if !text.trimmingCharacters(in: .whitespaces).isEmpty { onSubmit() } }
            if !text.isEmpty {
                Button {
                    text = ""
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.t("a11y.clear")))
            }
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .frame(height: Theme.Size.searchField)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Colors.bgRaised))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm).strokeBorder(focused ? Theme.Colors.info : Theme.Colors.line1))
    }
}

struct ConversationRow: View {
    let summary: ConversationSummary
    let game: Investigation

    var body: some View {
        let conversation = summary.conversation
        let unread = summary.unread > 0
        HStack(spacing: Theme.Spacing.s4) {
            if conversation.isGroup {
                GroupAvatar(count: conversation.participants.count + 1)
            } else {
                Avatar(contact: game.contact(conversation.participants[0]))
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(game.title(of: conversation))
                        .font(unread ? Theme.Fonts.headline : Theme.Fonts.bodyLarge)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let last = summary.last {
                        Text(PhoneFormat.relative(last.message.at, now: game.phoneNow))
                            .font(Theme.Fonts.data)
                            .foregroundStyle(unread ? Theme.Colors.info : Theme.Colors.textTertiary)
                    }
                }
                Text(preview)
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(unread ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .frame(height: Theme.Size.conversationRow)
        .overlay(alignment: .leading) {
            if unread {
                Circle().fill(Theme.Colors.info)
                    .frame(width: Theme.Size.unreadDot, height: Theme.Size.unreadDot)
                    .padding(.leading, 7)
                    .accessibilityLabel(Text(L10n.t("a11y.unread")))
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Colors.line1).frame(height: 1).padding(.leading, 88)
        }
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
    let query: String
    let game: Investigation

    var body: some View {
        let message = hit.message.message
        VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
            HStack {
                Text(game.index.conversation(hit.conversationID).map { game.title(of: $0) } ?? "")
                    .font(Theme.Fonts.headline)
                Spacer()
                Text(PhoneFormat.shortDay(message.at) + " · " + PhoneFormat.time(message.at))
                    .font(Theme.Fonts.data)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Text(Highlighter.attributed("\(game.name(of: message.from)) : \(message.text ?? L10n.t("item.photo"))", query: query))
                .font(Theme.Fonts.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, Theme.Spacing.marginList)
        .padding(.vertical, Theme.Spacing.s4)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line1).frame(height: 1) }
        .contentShape(Rectangle())
    }
}

/// Highlights the searched term (amber 22 % background).
enum Highlighter {
    static func attributed(_ text: String, query: String) -> AttributedString {
        var result = AttributedString(text)
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty,
              let range = text.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]),
              let attributed = Range(range, in: result) else { return result }
        result[attributed].backgroundColor = Theme.Colors.signal.opacity(0.22)
        result[attributed].foregroundColor = Theme.Colors.textPrimary
        return result
    }
}

/// Screen 10 — one conversation. You read, you don't write: no input field.
struct ConversationView: View {
    let conversationID: String
    let focus: String?
    let session: GameSession

    /// Messages closer than this share one centered timestamp.
    private let groupGap: Int64 = 5 * 60

    var body: some View {
        let game = session.game
        let conversation = game.index.conversation(conversationID)
        let messages = game.loadedMessages(in: conversationID)
        let other = conversation.flatMap { $0.isGroup ? nil : game.contact($0.participants[0]) }
        let stopped = other.flatMap { contact in game.device.tracks.first { $0.contact == contact.id }?.sharingStoppedAt }

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if game.hasOlderMessages(in: conversationID) {
                        Button {
                            session.perform { $0.loadOlderMessages(in: conversationID) }
                        } label: {
                            Text(L10n.f("messages.loadOlder", session.rules.timeCosts.loadOlderMessages))
                                .font(Theme.Fonts.dataStrong)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .padding(.horizontal, Theme.Spacing.s5)
                                .frame(height: 32)
                                .background(Capsule().fill(Theme.Colors.line1))
                                .overlay(Capsule().strokeBorder(Theme.Colors.line2))
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, Theme.Spacing.s5)
                    } else {
                        SystemPill(text: L10n.t("messages.start"))
                            .padding(.vertical, Theme.Spacing.s5)
                    }
                    ForEach(Array(messages.enumerated()), id: \.element.id) { offset, visible in
                        let previous = offset > 0 ? messages[offset - 1].message : nil
                        let next = offset + 1 < messages.count ? messages[offset + 1].message : nil
                        let at = visible.message.at
                        if previous == nil || !(previous?.at.isSameDay(as: at) ?? false) {
                            Text(PhoneFormat.separatorCaps(at) + " · " + PhoneFormat.time(at))
                                .font(Theme.Fonts.dataSmall)
                                .tracking(0.7)
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.top, Theme.Spacing.s6)
                                .padding(.bottom, Theme.Spacing.s3)
                        } else if let previous, at.seconds - previous.at.seconds > groupGap {
                            Text(PhoneFormat.time(at))
                                .font(Theme.Fonts.dataSmall)
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.top, Theme.Spacing.s4)
                                .padding(.bottom, Theme.Spacing.s2)
                        }
                        if let stopped, let previous, previous.at < stopped, stopped <= at {
                            SystemPill(text: L10n.f("messages.stoppedSharing", other?.name ?? "", PhoneFormat.time(stopped)))
                                .padding(.vertical, Theme.Spacing.s3)
                        }
                        let lastOfGroup: Bool = next.map { $0.from != visible.message.from || $0.at.seconds - at.seconds > groupGap } ?? true
                        let showsSender: Bool = conversation?.isGroup == true && previous?.from != visible.message.from && !visible.message.isFromOwner
                        MessageBubble(visible: visible,
                                      senderName: showsSender ? game.name(of: visible.message.from) : nil,
                                      lastOfGroup: lastOfGroup,
                                      highlighted: visible.id == focus,
                                      session: session)
                            .id(visible.id)
                            .onAppear { session.markSeen(ItemRef(.message, visible.id)) }
                    }
                    // Like a real messenger: the owner's last message, if nothing came after it.
                    if let last = messages.last, last.message.isFromOwner, last.state != .removedBySender {
                        Text(L10n.t("messages.delivered"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, Theme.Spacing.s2)
                    }
                    if let draft = conversation?.draft {
                        DraftBubble(draft: draft)
                            .onAppear { session.markSeen(ItemRef(.draft, draft.id)) }
                            .pinnable(ItemRef(.draft, draft.id), session: session, radius: Theme.Radius.bubble)
                            .id(draft.id)
                    }
                }
                .padding(.horizontal, Theme.Spacing.marginCompact)
                .padding(.bottom, Theme.Spacing.bottomInset)
            }
            .defaultScrollAnchor(.bottom)
            .onAppear {
                if let focus { proxy.scrollTo(focus, anchor: .center) }
            }
        }
        .background(Theme.Colors.bgBase)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    if let other { session.open(.contact(other.id)) }
                } label: {
                    HStack(spacing: Theme.Spacing.s3) {
                        if let other { Avatar(contact: other, size: Theme.Size.avatarS) } else { GroupAvatar(count: (conversation?.participants.count ?? 0) + 1, size: Theme.Size.avatarS) }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(conversation.map { game.title(of: $0) } ?? "").font(Theme.Fonts.headline).lineLimit(1)
                            Text(meta(conversation, other: other, game: game))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(L10n.t("a11y.openContact")))
            }
        }
    }

    private func meta(_ conversation: Conversation?, other: Contact?, game: Investigation) -> String {
        guard let conversation else { return "" }
        let count = game.visibleMessages(in: conversation.id).count
        if let relation = other?.relation { return L10n.f("messages.meta", relation, count) }
        return L10n.f("messages.metaGroup", conversation.participants.count + 1, count)
    }
}

/// Centered pill for system messages ("Début de la conversation", "X a cessé de partager…").
struct SystemPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.caption)
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.s4)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.Colors.line1))
            .frame(maxWidth: .infinity)
    }
}

/// MessageBubble: received (grey, left) · sent (blue, right) · deleted (dashed, italic) ·
/// recovered · pinned (amber ring + dot) · photo. Max 76 % width, r 19, 6 on the sender side of the last one.
struct MessageBubble: View {
    let visible: VisibleMessage
    let senderName: String?
    let lastOfGroup: Bool
    let highlighted: Bool
    let session: GameSession

    var body: some View {
        let message = visible.message
        let mine = message.isFromOwner
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: Theme.Radius.bubble,
            bottomLeadingRadius: !mine && lastOfGroup ? Theme.Radius.bubbleTail : Theme.Radius.bubble,
            bottomTrailingRadius: mine && lastOfGroup ? Theme.Radius.bubbleTail : Theme.Radius.bubble,
            topTrailingRadius: Theme.Radius.bubble,
            style: .continuous)
        VStack(alignment: mine ? .trailing : .leading, spacing: 3) {
            if let senderName {
                Text(senderName)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 13)
                    .padding(.top, Theme.Spacing.s3)
            }
            Group {
                if visible.state == .removedBySender {
                    Text(L10n.t("messages.removed"))
                        .font(Theme.Fonts.body.italic())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .overlay(shape.stroke(Theme.Colors.line3, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        if let photoID = message.photo, let photo = session.game.index.photo(photoID) {
                            Button {
                                session.open(.photo(photoID))
                            } label: {
                                GeneratedPhoto(scene: photo.scene, seed: photo.id)
                                    .frame(width: Theme.Size.photoBubble, height: Theme.Size.photoBubble * 0.75)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(photo.caption))
                        }
                        if let text = message.text {
                            Text(text)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(mine ? Theme.Colors.bubbleOutText : Theme.Colors.textPrimary)
                        }
                    }
                    .padding(.horizontal, message.text == nil ? 4 : 13)
                    .padding(.vertical, message.text == nil ? 4 : 9)
                    .background(shape.fill(mine ? Theme.Colors.bubbleOut : Theme.Colors.bgBubbleIn))
                    .overlay(
                        shape.stroke(visible.state == .recovered ? Theme.Colors.signalLine : (highlighted ? Theme.Colors.line3 : .clear),
                                     style: StrokeStyle(lineWidth: 1, dash: visible.state == .recovered ? [4, 3] : []))
                    )
                }
            }
            .pinnable(ItemRef(.message, message.id), session: session, radius: Theme.Radius.bubble)
            if visible.state == .recovered {
                Text(L10n.t("messages.recovered"))
                    .font(Theme.Fonts.dataSmall)
                    .foregroundStyle(Theme.Colors.signal)
                    .padding(.horizontal, Theme.Spacing.s2)
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
        .padding(mine ? .leading : .trailing, Theme.Spacing.s10)
        .padding(.bottom, lastOfGroup ? 6 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(session.game.name(of: message.from)), \(PhoneFormat.time(message.at)) : \(message.text ?? L10n.t("item.photo"))"))
        .accessibilityIdentifier("message.\(message.id)")
    }
}

/// An unsent draft: dashed outline on the owner's side.
struct DraftBubble: View {
    let draft: Draft

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(draft.text)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                        .stroke(Theme.Colors.line3, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            Text(L10n.f("messages.draftAt", PhoneFormat.dayAndTime(draft.at)))
                .font(Theme.Fonts.dataSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, Theme.Spacing.s10)
        .padding(.top, Theme.Spacing.s5)
    }
}
#endif
