#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Browser

/// Browser: the history grouped by day (searches with a magnifier,
/// pages with a site badge and their address).
struct BrowserHistoryView: View {
    let session: GameSession

    var body: some View {
        let entries = session.game.device.browser.sorted { $0.at > $1.at }
        let days = Dictionary(grouping: entries, by: { $0.at.dayNumber })
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if entries.isEmpty {
                    EmptyStateView(title: L10n.t("empty.browserTitle"), message: L10n.t("empty.browserMessage"))
                }
                ForEach(days.keys.sorted(by: >), id: \.self) { day in
                    let items = (days[day] ?? []).sorted { $0.at > $1.at }
                    AppSectionHeader(title: items.first.map { PhoneFormat.longDayCapitalized($0.at) } ?? "", count: items.count)
                    CardGroup {
                        ForEach(Array(items.enumerated()), id: \.element.id) { offset, entry in
                            Button {
                                session.open(.browserEntry(entry.id))
                            } label: {
                                BrowserRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .onAppear { session.markSeen(ItemRef(.browser, entry.id)) }
                            .pinnable(ItemRef(.browser, entry.id), session: session, radius: Theme.Radius.sm)
                            if offset < items.count - 1 { RowDivider(leading: 60) }
                        }
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.browser, subtitle: L10n.t("browser.history") + " · " + L10n.f("n.pages", entries.count), session: session)
    }
}

struct BrowserRow: View {
    let entry: BrowserEntry

    var body: some View {
        HStack(spacing: Theme.Spacing.s4) {
            SiteBadge(entry: entry)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind == .search ? "« \(entry.text) »" : entry.text)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
                Text(entry.kind == .search ? L10n.t("browser.searchLabel") : (entry.url.map(BrowserFormat.domain) ?? ""))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(entry.kind == .search ? Theme.Colors.textSecondary : Theme.appAccent(.browser))
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Spacing.s3)
            Text(PhoneFormat.time(entry.at)).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.s4)
        .contentShape(Rectangle())
    }
}

/// A search (magnifier) or a site (first letter of its domain on a tinted square).
struct SiteBadge: View {
    let entry: BrowserEntry

    var body: some View {
        Group {
            if entry.kind == .search {
                Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .semibold))
            } else {
                Text(String(entry.url.map(BrowserFormat.domain)?.first ?? "•").uppercased())
                    .font(.custom(Theme.FontName.semibold, fixedSize: 15))
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .frame(width: 32, height: 32)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(entry.kind == .search ? Theme.Colors.bgSelected : Theme.iconGradient(.browser).bottom))
        .accessibilityHidden(true)
    }
}

/// The browser's address field (read-only: the player browses the history, not the web).
struct AddressBar: View {
    let text: String
    let secure: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Image(systemName: secure ? "lock.fill" : "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(text)
                .font(Theme.Fonts.callout)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .frame(height: Theme.Size.searchField)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgRaised))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).strokeBorder(Theme.Colors.line1))
    }
}

enum BrowserFormat {
    /// "https://www.example.fr/a/b" → "example.fr"
    static func domain(_ url: String) -> String {
        var host = url
        for prefix in ["https://", "http://"] where host.hasPrefix(prefix) { host.removeFirst(prefix.count) }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return String(host.split(separator: "/").first ?? Substring(host))
    }
}

struct BrowserPageView: View {
    let entryID: String
    let session: GameSession

    var body: some View {
        if let entry = session.game.index.browserEntry(entryID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    AddressBar(text: entry.url.map(BrowserFormat.domain) ?? L10n.f("browser.searchURL", entry.text),
                               secure: entry.url != nil)
                    VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                        if let url = entry.url {
                            Text(url).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.appAccent(.browser)).lineLimit(1)
                        }
                        Text(entry.kind == .search ? L10n.f("browser.resultsFor", entry.text) : entry.text)
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Rectangle().fill(Theme.Colors.line2).frame(height: 1)
                        Text(entry.summary ?? L10n.t("browser.noPreview"))
                            .font(Theme.Fonts.bodyLarge)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineSpacing(3)
                    }
                    .padding(Theme.Spacing.s5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.line1))
                    Label(L10n.f("browser.visited", PhoneFormat.dayAndTime(entry.at)), systemImage: "clock")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.marginCompact)
                .padding(.bottom, Theme.Spacing.bottomInset)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Mail

/// Mail: Inbox / Sent switch, then messages with sender, subject, preview and date; unread in bold with a blue dot.
struct MailListView: View {
    let session: GameSession
    @State private var folder: Mail.Folder = .inbox

    var body: some View {
        let all = session.game.device.mails
        let mails = all.filter { $0.folder == folder }.sorted { $0.at > $1.at }
        let unread = all.filter { $0.folder == .inbox && $0.unread == true }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Segmented(options: [(Mail.Folder.inbox, L10n.t("mail.inbox")), (Mail.Folder.sent, L10n.t("mail.sent"))], selection: $folder)
                    .padding(.horizontal, Theme.Spacing.marginList)
                    .padding(.vertical, Theme.Spacing.s4)
                AppSectionHeader(title: folder == .inbox ? L10n.t("mail.inbox") : L10n.t("mail.sent"), count: mails.count,
                                 color: Theme.appAccent(.mail))
                CardGroup {
                    ForEach(Array(mails.enumerated()), id: \.element.id) { offset, mail in
                        Button {
                            session.open(.mail(mail.id))
                        } label: {
                            MailRow(mail: mail, showsRecipient: folder == .sent, now: session.game.phoneNow)
                        }
                        .buttonStyle(.plain)
                        if offset < mails.count - 1 { RowDivider(leading: 28) }
                    }
                }
                if mails.isEmpty {
                    EmptyStateView(title: L10n.t("mail.emptyTitle"), message: L10n.t("mail.emptyMessage"))
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.mail, subtitle: L10n.f("n.unread", unread), session: session)
    }
}

struct MailRow: View {
    let mail: Mail
    let showsRecipient: Bool
    let now: Moment

    var body: some View {
        let unread = mail.unread == true && !showsRecipient
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            Circle().fill(unread ? Theme.Colors.info : .clear)
                .frame(width: 8, height: 8)
                .padding(.top, 7)
                .accessibilityLabel(Text(unread ? L10n.t("a11y.unread") : ""))
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(showsRecipient ? L10n.f("mail.to", mail.to) : mail.fromName)
                        .font(unread ? Theme.Fonts.headline : Theme.Fonts.bodyLarge)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if mail.attachments?.isEmpty == false {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .accessibilityLabel(Text(L10n.t("mail.hasAttachment")))
                    }
                    Text(PhoneFormat.relative(mail.at, now: now))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(unread ? Theme.Colors.info : Theme.Colors.textTertiary)
                }
                Text(mail.subject)
                    .font(unread ? Theme.Fonts.calloutStrong : Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text(mail.body.replacingOccurrences(of: "\n", with: " "))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(Theme.Spacing.s4)
        .contentShape(Rectangle())
    }
}

struct MailView: View {
    let mailID: String
    let session: GameSession
    @State private var attachmentTapped: String?

    var body: some View {
        if let mail = session.game.index.mail(mailID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    Text(mail.subject).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                    HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                        Text(String(mail.fromName.prefix(1)).uppercased())
                            .font(.custom(Theme.FontName.semibold, fixedSize: 17))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(width: Theme.Size.avatarS, height: Theme.Size.avatarS)
                            .background(Circle().fill(Theme.iconGradient(.mail).bottom))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(mail.fromName).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Text(PhoneFormat.dayAndTime(mail.at)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Text(mail.fromAddress).font(Theme.Fonts.caption).foregroundStyle(Theme.appAccent(.mail))
                            Text(L10n.f("mail.to", mail.to)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    Rectangle().fill(Theme.Colors.line2).frame(height: 1)
                    Text(mail.body).font(Theme.Fonts.bodyLarge).foregroundStyle(Theme.Colors.textPrimary).lineSpacing(3)
                    if let attachments = mail.attachments, !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                            Label(L10n.f("mail.attachments", attachments.count), systemImage: "paperclip").overline(Theme.appAccent(.mail))
                            ForEach(attachments, id: \.self) { name in
                                Button { attachmentTapped = name } label: { AttachmentChip(name: name) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, Theme.Spacing.s3)
                    }
                }
                .padding(Theme.Spacing.marginList)
                .padding(.bottom, Theme.Spacing.bottomInset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.mail, mail.id), session: session)
            .alert(L10n.t("mail.attachmentMissingTitle"), isPresented: Binding(get: { attachmentTapped != nil }, set: { if !$0 { attachmentTapped = nil } })) {
                Button(L10n.t("common.ok"), role: .cancel) {}
            } message: {
                Text(L10n.f("mail.attachmentMissing", attachmentTapped ?? ""))
            }
        }
    }
}

/// A mail attachment: file-type badge, name, "not downloaded" (the phone never fetched it).
struct AttachmentChip: View {
    let name: String

    private var ext: String { (name.split(separator: ".").last.map(String.init) ?? "").uppercased() }

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Text(ext)
                .font(.custom(Theme.FontName.monoBold, fixedSize: 9))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 34, height: 40)
                .background(RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(ext == "PDF" ? Theme.Colors.alert.opacity(0.8) : ext == "XLSX" ? Theme.Colors.clear.opacity(0.7) : Theme.Colors.bgSelected))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                Label(L10n.t("mail.notDownloaded"), systemImage: "icloud.and.arrow.down")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.s3)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).strokeBorder(Theme.Colors.line1))
        .contentShape(Rectangle())
    }
}

// MARK: - Contacts

/// Contacts: my card, the people of the case, then everyone else in alphabetical sections.
struct ContactsListView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let owner = game.device.contacts.first { $0.isOwner == true }
        let suspectContacts = Set(game.caseFile.suspects.map(\.contact))
        let caseContacts = game.device.contacts.filter { suspectContacts.contains($0.id) }
        let others = game.device.contacts.filter { $0.isOwner != true && !suspectContacts.contains($0.id) }.sorted { $0.name < $1.name }
        let letters = Dictionary(grouping: others, by: { String($0.name.prefix(1)).uppercased() })
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let owner {
                    Button { session.open(.contact(owner.id)) } label: {
                        HStack(spacing: Theme.Spacing.s4) {
                            Avatar(contact: owner, size: Theme.Size.avatarM + 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(owner.name).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                                Text(L10n.t("contacts.myCard")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Spacing.s4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                    .padding(.horizontal, Theme.Spacing.marginCompact)
                    .padding(.top, Theme.Spacing.s4)
                }
                AppSectionHeader(title: L10n.t("contacts.casePeople"), count: caseContacts.count, color: Theme.Colors.special)
                CardGroup {
                    ForEach(Array(caseContacts.enumerated()), id: \.element.id) { offset, contact in
                        contactRow(contact, subtitle: contact.relation)
                        if offset < caseContacts.count - 1 { RowDivider(leading: 64) }
                    }
                }
                ForEach(letters.keys.sorted(), id: \.self) { letter in
                    let group = letters[letter] ?? []
                    AppSectionHeader(title: letter)
                    CardGroup {
                        ForEach(Array(group.enumerated()), id: \.element.id) { offset, contact in
                            contactRow(contact, subtitle: nil)
                            if offset < group.count - 1 { RowDivider(leading: 64) }
                        }
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.contacts, subtitle: L10n.f("n.contacts", game.device.contacts.count - (owner == nil ? 0 : 1)), session: session)
    }

    private func contactRow(_ contact: Contact, subtitle: String?) -> some View {
        Button { session.open(.contact(contact.id)) } label: {
            HStack(spacing: Theme.Spacing.s4) {
                Avatar(contact: contact, size: Theme.Size.avatarS)
                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.name).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                    if let subtitle {
                        Text(subtitle).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.s4)
            .padding(.vertical, Theme.Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A contact card: big avatar, name, relation, quick actions, details, recent calls.
struct ContactDetailView: View {
    let contactID: ContactID
    let session: GameSession

    var body: some View {
        let game = session.game
        if let contact = game.contact(contactID) {
            let conversation = game.device.conversations.first { !$0.isGroup && $0.participants == [contact.id] }
            let calls = game.calls.filter { $0.contact == contact.id }
            ScrollView {
                VStack(spacing: Theme.Spacing.s5) {
                    VStack(spacing: Theme.Spacing.s3) {
                        Avatar(contact: contact, size: Theme.Size.avatarL)
                        Text(contact.name).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                        if let relation = contact.relation {
                            Text(relation).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        if let conversation {
                            Button {
                                session.open(.conversation(conversation.id))
                            } label: {
                                Label(L10n.t("contacts.message"), systemImage: "message.fill")
                                    .font(Theme.Fonts.calloutStrong)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .padding(.horizontal, Theme.Spacing.s5)
                                    .frame(minHeight: Theme.Size.hit)
                                    .background(Capsule().fill(Theme.iconGradient(.messages).bottom))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, Theme.Spacing.s2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Theme.Spacing.s4)

                    CardGroup {
                        InfoRow(icon: "phone.fill", label: L10n.t("contacts.phone"), value: contact.phone).padding(Theme.Spacing.s4)
                        if let email = contact.email {
                            RowDivider()
                            InfoRow(icon: "envelope.fill", label: L10n.t("contacts.email"), value: email).padding(Theme.Spacing.s4)
                        }
                        if let birthday = contact.birthday {
                            RowDivider()
                            InfoRow(icon: "gift.fill", label: L10n.t("contacts.birthday"), value: birthday).padding(Theme.Spacing.s4)
                        }
                    }
                    if !calls.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            AppSectionHeader(title: L10n.t("contacts.recentCalls"), count: calls.count, color: Theme.appAccent(.phone))
                            CardGroup {
                                ForEach(Array(calls.prefix(6).enumerated()), id: \.element.id) { offset, call in
                                    CallRow(call: call, game: game)
                                        .onAppear { session.markSeen(ItemRef(.call, call.id)) }
                                    if offset < min(calls.count, 6) - 1 { RowDivider(leading: 64) }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, Theme.Spacing.bottomInset)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.contact, contact.id), session: session)
        }
    }
}

// MARK: - Trash

/// "Récemment supprimés": who and when are visible; the content costs time to recover.
struct TrashView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                Label(L10n.t("trash.footer"), systemImage: "info.circle")
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.s4)
                ForEach(game.trash) { item in
                    TrashCard(item: item, session: session)
                        .pinnable(ItemRef(.message, item.message.id), session: session, radius: Theme.Radius.md)
                }
                if game.trash.isEmpty {
                    EmptyStateView(title: L10n.t("trash.emptyTitle"), message: L10n.t("trash.emptyMessage"))
                }
            }
            .padding(.horizontal, Theme.Spacing.marginCompact)
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.trash, subtitle: L10n.f("trash.subtitle", game.trash.count), session: session)
    }
}

struct TrashCard: View {
    let item: TrashItem
    let session: GameSession

    var body: some View {
        let game = session.game
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack(spacing: Theme.Spacing.s3) {
                Avatar(contact: game.contact(item.message.from), size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(game.name(of: item.message.from)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                    Text(L10n.t("trash.typeMessage") + " · " + PhoneFormat.dayAndTime(item.message.at))
                        .font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
            }
            if item.isRecovered {
                Text(item.message.text ?? L10n.t("item.photo"))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Label(L10n.t("trash.recovered"), systemImage: "checkmark.circle.fill")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.clear)
            } else {
                Text(L10n.t("trash.hidden"))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .redacted(reason: .placeholder)
                Button {
                    session.perform { $0.recoverMessage(item.message.id) }
                } label: {
                    HStack {
                        Label(L10n.t("trash.recoverAction"), systemImage: "arrow.uturn.backward")
                            .font(Theme.Fonts.calloutStrong)
                        Spacer()
                        CostTag(seconds: session.rules.timeCosts.recoverMessage)
                    }
                    .foregroundStyle(Theme.Colors.info)
                    .padding(.horizontal, Theme.Spacing.s4)
                    .frame(minHeight: Theme.Size.hit)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.infoTint))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.f("trash.recover", session.rules.timeCosts.recoverMessage)))
            }
            Text(L10n.f("trash.deletedAt", PhoneFormat.dayAndTime(item.deletedAt)))
                .font(Theme.Fonts.dataSmall)
                .foregroundStyle(Theme.appAccent(.trash))
        }
        .padding(Theme.Spacing.s4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .strokeBorder(Theme.Colors.line3, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }
}

// MARK: - Settings

struct SettingsView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let owner = game.device.contacts.first { $0.isOwner == true }
        let shared = game.device.tracks.filter { $0.contact != ownerContactID }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Theme.Spacing.s4) {
                    Avatar(contact: owner, size: Theme.Size.avatarM + 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(owner?.name ?? "").font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                        Text(owner?.email ?? "").font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(Theme.Spacing.s4)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                .padding(.horizontal, Theme.Spacing.marginCompact)
                .padding(.top, Theme.Spacing.s4)

                AppSectionHeader(title: L10n.t("settings.device"))
                CardGroup {
                    settingRow("iphone", Theme.Colors.bgSelected, L10n.t("settings.model"), game.device.model)
                    RowDivider(leading: 56)
                    settingRow("phone.fill", Theme.iconGradient(.phone).bottom, L10n.t("contacts.phone"), owner?.phone ?? "")
                }
                AppSectionHeader(title: L10n.t("settings.sharing"))
                CardGroup {
                    ForEach(Array(shared.enumerated()), id: \.element.id) { offset, track in
                        settingRow("location.fill", Theme.Colors.info, game.name(of: track.contact),
                                   track.sharingStoppedAt.map { L10n.f("settings.sharingStopped", PhoneFormat.dayAndTime($0)) }
                                       ?? L10n.t("settings.sharingOn"))
                        if offset < shared.count - 1 { RowDivider(leading: 56) }
                    }
                }
                AppSectionHeader(title: L10n.t("settings.security"))
                CardGroup {
                    ForEach(Array(game.device.lockedApps.enumerated()), id: \.element.app) { offset, lock in
                        settingRow("lock.fill", Theme.Colors.alert, lock.app.title, L10n.t("settings.codeOn"))
                        if offset < game.device.lockedApps.count - 1 { RowDivider(leading: 56) }
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.settings, subtitle: game.device.model, session: session)
    }

    private func settingRow(_ symbol: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack(spacing: Theme.Spacing.s4) {
            SymbolTile(symbol: symbol, color: color)
            Text(label).font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textPrimary)
            Spacer(minLength: Theme.Spacing.s3)
            Text(value).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .frame(minHeight: Theme.Size.hit + 4)
    }
}

// MARK: - Notifications

/// Notification centre: every notification received during the investigation, as cards.
struct NotificationsView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                AppSectionHeader(title: L10n.t("notif.today"), count: game.notifications.count, color: Theme.appAccent(.notifications))
                    .padding(.horizontal, -Theme.Spacing.marginCompact)
                if game.notifications.isEmpty {
                    EmptyStateView(title: L10n.t("notif.emptyTitle"), message: L10n.t("notif.empty"))
                }
                ForEach(game.notifications) { notification in
                    Button {
                        session.open(notification)
                    } label: {
                        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                            AppTileGlyph(app: notification.app, size: Theme.Size.avatarS)
                            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                                HStack {
                                    Text(notification.app.title.uppercased())
                                        .font(Theme.Fonts.dataSmall)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                    Spacer()
                                    Text(PhoneFormat.time(notification.at)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                                }
                                Text(notification.title).font(Theme.Fonts.calloutStrong).foregroundStyle(Theme.Colors.textPrimary)
                                Text(notification.body).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(Theme.Spacing.s4)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous).fill(Theme.Colors.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous)
                            .strokeBorder(notification.level == .normal ? Theme.Colors.line1 : Theme.Colors.line3))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.marginCompact)
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.notifications, subtitle: L10n.f("n.unreadF", game.unreadNotificationsCount), session: session)
        .onAppear { session.perform { $0.markNotificationsRead() } }
    }
}
#endif
