#if os(iOS)
import SwiftUI
import CaseEngine

/// The seized phone: its own status bar, home screen, apps, notification banners and home bar.
/// Everything inside feels like somebody else's real phone.
struct PhoneView: View {
    let session: GameSession

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background
            VStack(spacing: 0) {
                PhoneStatusBar(session: session)
                NavigationStack(path: Binding(get: { session.path }, set: { session.setPath($0) })) {
                    HomeScreen(session: session)
                        .navigationDestination(for: PhoneRoute.self) { route in
                            destination(route)
                        }
                }
                .tint(Theme.Colors.link)
                HomeIndicator { session.goHome() }
            }
            if let banner = session.banner {
                NotificationBanner(notification: banner, contactFor: { session.game.contact($0) }) {
                    session.open(banner)
                } onDismiss: {
                    session.dismissBanner()
                }
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.top, Theme.Size.statusBarHeight + Theme.Spacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(Theme.Motion.spring, value: session.banner)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.phone, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.phone, style: .continuous)
                .strokeBorder(Theme.Colors.separator, lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func destination(_ route: PhoneRoute) -> some View {
        switch route {
        case .app(let app): AppContainer(app: app, session: session)
        case .conversation(let id, let focus): ConversationView(conversationID: id, focus: focus, session: session)
        case .contact(let id): ContactDetailView(contactID: id, session: session)
        case .photo(let id): PhotoDetailView(photoID: id, session: session)
        case .track(let id): TrackView(trackID: id, session: session)
        case .calendarEvent(let id): CalendarEventView(eventID: id, session: session)
        case .note(let id): NoteView(noteID: id, session: session)
        case .mail(let id): MailView(mailID: id, session: session)
        case .browserEntry(let id): BrowserPageView(entryID: id, session: session)
        }
    }
}

/// Routes an app to its screen, or to its lock screen.
struct AppContainer: View {
    let app: AppID
    let session: GameSession

    var body: some View {
        Group {
            if session.game.access(to: app) == .locked {
                AppLockView(app: app, session: session)
            } else {
                switch app {
                case .messages: MessagesListView(session: session)
                case .phone: CallsView(session: session)
                case .photos: PhotosGridView(session: session)
                case .location: LocationView(session: session)
                case .calendar: CalendarListView(session: session)
                case .notes: NotesListView(session: session)
                case .browser: BrowserHistoryView(session: session)
                case .mail: MailListView(session: session)
                case .contacts: ContactsListView(session: session)
                case .trash: TrashView(session: session)
                case .settings: SettingsView(session: session)
                case .notifications: NotificationsView(session: session)
                }
            }
        }
        .background(Theme.Colors.background)
    }
}

/// The phone's own status bar: its clock (case time), network, battery.
struct PhoneStatusBar: View {
    let session: GameSession

    var body: some View {
        HStack {
            Text(PhoneFormat.time(session.game.phoneNow))
                .font(Theme.Fonts.subheadline.weight(.semibold))
                .monospacedDigit()
            Spacer()
            Image(systemName: "cellularbars")
            Image(systemName: "wifi")
            Image(systemName: "battery.25")
        }
        .font(Theme.Fonts.caption)
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, Theme.Spacing.xl)
        .frame(height: Theme.Size.statusBarHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("a11y.phoneTime", PhoneFormat.time(session.game.phoneNow))))
    }
}

/// Bottom bar of the phone: tap to go back to the home screen.
struct HomeIndicator: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(Theme.Colors.textPrimary.opacity(0.85))
                .frame(width: Theme.Size.homeIndicator.width, height: Theme.Size.homeIndicator.height)
                .frame(maxWidth: .infinity, minHeight: Theme.Spacing.xl)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("a11y.home")))
    }
}

struct NotificationBanner: View {
    let notification: PhoneNotification
    let contactFor: (ContactID) -> Contact?
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                AppIconGlyph(app: notification.app, size: Theme.Size.avatarS + 6)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack {
                        Text(notification.title)
                            .font(Theme.Fonts.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer()
                        Text(L10n.t("notif.now"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Text(notification.body)
                        .font(Theme.Fonts.subheadline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(Theme.Spacing.m)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        }
        .buttonStyle(.plain)
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            if value.translation.height < -10 { onDismiss() }
        })
        .accessibilityHint(Text(L10n.t("a11y.openNotification")))
    }
}
#endif
