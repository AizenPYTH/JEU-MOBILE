#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Browser

struct BrowserHistoryView: View {
    let session: GameSession

    var body: some View {
        let entries = session.game.device.browser.sorted { $0.at > $1.at }
        let days = Dictionary(grouping: entries, by: { $0.at.dayNumber })
        List {
            ForEach(days.keys.sorted(by: >), id: \.self) { day in
                let items = (days[day] ?? []).sorted { $0.at > $1.at }
                Section(items.first.map { PhoneFormat.longDayCapitalized($0.at) } ?? "") {
                    ForEach(items) { entry in
                        Button {
                            session.open(.browserEntry(entry.id))
                        } label: {
                            HStack(spacing: Theme.Spacing.s4) {
                                Image(systemName: entry.kind == .search ? "magnifyingglass" : "globe")
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                                    Text(entry.text).font(Theme.Fonts.body).lineLimit(2)
                                    if let url = entry.url {
                                        Text(url).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text(PhoneFormat.time(entry.at)).font(Theme.Fonts.callout).monospacedDigit()
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onAppear { session.markSeen(ItemRef(.browser, entry.id)) }
                        .pinnable(ItemRef(.browser, entry.id), session: session)
                    }
                }
            }
        }
        .navigationTitle(L10n.t("browser.history"))
    }
}

struct BrowserPageView: View {
    let entryID: String
    let session: GameSession

    var body: some View {
        if let entry = session.game.index.browserEntry(entryID) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                HStack {
                    Image(systemName: "lock.fill").font(Theme.Fonts.caption)
                    Text(entry.url ?? L10n.f("browser.searchURL", entry.text)).lineLimit(1)
                }
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.s3)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.xs).fill(Theme.Colors.bgRaised))
                Text(entry.kind == .search ? L10n.f("browser.resultsFor", entry.text) : entry.text)
                    .font(Theme.Fonts.title)
                Text(entry.summary ?? L10n.t("browser.noPreview"))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(L10n.f("browser.visited", PhoneFormat.dayAndTime(entry.at)))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                Spacer()
            }
            .padding(Theme.Spacing.s5)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Mail

struct MailListView: View {
    let session: GameSession
    @State private var folder: Mail.Folder = .inbox

    var body: some View {
        let mails = session.game.device.mails.filter { $0.folder == folder }.sorted { $0.at > $1.at }
        List(mails) { mail in
            Button {
                session.open(.mail(mail.id))
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                    HStack {
                        Text(folder == .sent ? mail.to : mail.fromName).font(Theme.Fonts.headline).lineLimit(1)
                        Spacer()
                        Text(PhoneFormat.relative(mail.at, now: session.game.phoneNow))
                            .font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Text(mail.subject).font(Theme.Fonts.callout).lineLimit(1)
                    Text(mail.body.replacingOccurrences(of: "\n", with: " "))
                        .font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary).lineLimit(2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(folder == .inbox ? L10n.t("mail.inbox") : L10n.t("mail.sent"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("", selection: $folder) {
                    Text(L10n.t("mail.inbox")).tag(Mail.Folder.inbox)
                    Text(L10n.t("mail.sent")).tag(Mail.Folder.sent)
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct MailView: View {
    let mailID: String
    let session: GameSession

    var body: some View {
        if let mail = session.game.index.mail(mailID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                    Text(mail.subject).font(Theme.Fonts.title)
                    VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                        Text("\(mail.fromName) <\(mail.fromAddress)>").font(Theme.Fonts.callout.weight(.semibold))
                        Text(L10n.f("mail.to", mail.to)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                        Text(PhoneFormat.dayAndTime(mail.at)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Divider().overlay(Theme.Colors.line2)
                    Text(mail.body).font(Theme.Fonts.body)
                }
                .padding(Theme.Spacing.s5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.mail, mail.id), session: session)
        }
    }
}

// MARK: - Contacts

struct ContactsListView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let owner = game.device.contacts.first { $0.isOwner == true }
        let suspectContacts = Set(game.caseFile.suspects.map(\.contact))
        let caseContacts = game.device.contacts.filter { suspectContacts.contains($0.id) }
        let others = game.device.contacts.filter { $0.isOwner != true && !suspectContacts.contains($0.id) }.sorted { $0.name < $1.name }
        List {
            Section(L10n.t("contacts.casePeople")) {
                ForEach(caseContacts) { contact in
                    Button { session.open(.contact(contact.id)) } label: {
                        HStack(spacing: Theme.Spacing.s4) {
                            Avatar(contact: contact, size: Theme.Size.avatarS)
                            VStack(alignment: .leading) {
                                Text(contact.name).font(Theme.Fonts.headline)
                                if let relation = contact.relation {
                                    Text(relation).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if let owner {
                Section {
                    Button { session.open(.contact(owner.id)) } label: {
                        HStack(spacing: Theme.Spacing.s4) {
                            Avatar(contact: owner, size: Theme.Size.avatarM + 8)
                            VStack(alignment: .leading) {
                                Text(owner.name).font(Theme.Fonts.headline)
                                Text(L10n.t("contacts.myCard")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Section {
                ForEach(others) { contact in
                    Button { session.open(.contact(contact.id)) } label: {
                        HStack(spacing: Theme.Spacing.s4) {
                            Avatar(contact: contact, size: Theme.Size.avatarS)
                            Text(contact.name).font(Theme.Fonts.body)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(AppID.contacts.title)
    }
}

struct ContactDetailView: View {
    let contactID: ContactID
    let session: GameSession

    var body: some View {
        let game = session.game
        if let contact = game.contact(contactID) {
            let conversation = game.device.conversations.first { !$0.isGroup && $0.participants == [contact.id] }
            List {
                Section {
                    VStack(spacing: Theme.Spacing.s3) {
                        Avatar(contact: contact, size: Theme.Size.avatarL)
                        Text(contact.name).font(Theme.Fonts.title)
                        if let relation = contact.relation {
                            Text(relation).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        if let conversation {
                            Button {
                                session.open(.conversation(conversation.id))
                            } label: {
                                Label(L10n.t("contacts.message"), systemImage: "message.fill")
                                    .font(Theme.Fonts.callout.weight(.semibold))
                                    .padding(.horizontal, Theme.Spacing.s5)
                                    .padding(.vertical, Theme.Spacing.s3)
                                    .background(Capsule().fill(Theme.Colors.bgRaised))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.Colors.trace)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.s3)
                }
                Section {
                    InfoRow(icon: "phone", label: L10n.t("contacts.phone"), value: contact.phone)
                    if let email = contact.email { InfoRow(icon: "envelope", label: L10n.t("contacts.email"), value: email) }
                    if let birthday = contact.birthday { InfoRow(icon: "gift", label: L10n.t("contacts.birthday"), value: birthday) }
                }
                let calls = game.calls.filter { $0.contact == contact.id }
                if !calls.isEmpty {
                    Section(L10n.t("contacts.recentCalls")) {
                        ForEach(calls.prefix(6)) { call in
                            CallRow(call: call, game: game)
                                .onAppear { session.markSeen(ItemRef(.call, call.id)) }
                        }
                    }
                }
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
        List {
            Section {
                ForEach(game.trash) { item in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        Text(L10n.t("trash.typeMessage")).overline()
                        HStack {
                            Text(game.name(of: item.message.from)).font(Theme.Fonts.headline)
                            Spacer()
                            Text(PhoneFormat.dayAndTime(item.message.at)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        if item.isRecovered {
                            Text(item.message.text ?? L10n.t("item.photo")).font(Theme.Fonts.body)
                            Text(L10n.t("trash.recovered")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.signal)
                        } else {
                            Text(L10n.t("trash.hidden"))
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .redacted(reason: .placeholder)
                            Button {
                                session.perform { $0.recoverMessage(item.message.id) }
                            } label: {
                                Label(L10n.f("trash.recover", session.rules.timeCosts.recoverMessage), systemImage: "arrow.uturn.backward")
                                    .font(Theme.Fonts.callout.weight(.semibold))
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(Theme.Colors.signal)
                        }
                        Text(L10n.f("trash.deletedAt", PhoneFormat.dayAndTime(item.deletedAt)))
                            .font(Theme.Fonts.dataSmall)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(Theme.Spacing.s4)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm).stroke(Theme.Colors.line3, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .pinnable(ItemRef(.message, item.message.id), session: session, radius: Theme.Radius.sm)
                }
            } footer: {
                Text(L10n.t("trash.footer"))
            }
        }
        .navigationTitle(L10n.t("trash.title"))
    }
}

// MARK: - Settings

struct SettingsView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let owner = game.device.contacts.first { $0.isOwner == true }
        List {
            Section {
                HStack(spacing: Theme.Spacing.s4) {
                    Avatar(contact: owner, size: Theme.Size.avatarM + 12)
                    VStack(alignment: .leading) {
                        Text(owner?.name ?? "").font(Theme.Fonts.headline)
                        Text(owner?.email ?? "").font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            Section(L10n.t("settings.device")) {
                InfoRow(icon: "iphone", label: L10n.t("settings.model"), value: game.device.model)
                InfoRow(icon: "phone", label: L10n.t("contacts.phone"), value: owner?.phone ?? "")
            }
            Section(L10n.t("settings.sharing")) {
                ForEach(game.device.tracks.filter { $0.contact != ownerContactID }) { track in
                    InfoRow(icon: "location", label: game.name(of: track.contact),
                            value: track.sharingStoppedAt.map { L10n.f("settings.sharingStopped", PhoneFormat.dayAndTime($0)) }
                                ?? L10n.t("settings.sharingOn"))
                }
            }
            Section(L10n.t("settings.security")) {
                ForEach(game.device.lockedApps, id: \.app) { lock in
                    InfoRow(icon: "lock", label: lock.app.title, value: L10n.t("settings.codeOn"))
                }
            }
        }
        .navigationTitle(AppID.settings.title)
    }
}

// MARK: - Notifications

struct NotificationsView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        List {
            if game.notifications.isEmpty {
                Text(L10n.t("notif.empty")).foregroundStyle(Theme.Colors.textSecondary)
            }
            ForEach(game.notifications) { notification in
                Button {
                    session.open(notification)
                } label: {
                    HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                        AppTileGlyph(app: notification.app, size: Theme.Size.avatarS)
                        VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                            HStack {
                                Text(notification.title).font(Theme.Fonts.callout.weight(.semibold))
                                Spacer()
                                Text(PhoneFormat.time(notification.at)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Text(notification.body).font(Theme.Fonts.callout)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(AppID.notifications.title)
        .onAppear { session.perform { $0.markNotificationsRead() } }
    }
}
#endif
