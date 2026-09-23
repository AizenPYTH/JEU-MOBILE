/// A problem in a case file. Case issues are bugs: tests fail on any of them.
public struct CaseIssue: Sendable, Hashable, CustomStringConvertible {
    public var caseID: String
    public var message: String

    public var description: String { "[\(caseID)] \(message)" }
}

/// Cross-checks a case: unique ids, every reference points to something, the solution is a
/// suspect, evidence exists for the culprit, live events are well formed…
public enum CaseValidator {
    public static func validate(_ file: CaseFile) -> [CaseIssue] {
        var issues: [CaseIssue] = []
        func fail(_ message: String) { issues.append(CaseIssue(caseID: file.id, message: message)) }

        if file.durationSeconds <= 0 { fail("durationSeconds must be > 0") }
        if file.devices.isEmpty { fail("a case needs at least one device") }
        if file.suspects.count < 2 { fail("a case needs at least two suspects") }

        // Global id uniqueness (all references share one namespace).
        var seen: [String: String] = [:]
        func register(_ id: String, _ what: String) {
            if let other = seen[id] { fail("duplicate id '\(id)' (\(what) and \(other))") } else { seen[id] = what }
        }

        var known = Set<ItemRef>()
        for device in file.devices {
            register(device.id, "device")
            let contactIDs = Set(device.contacts.map(\.id)).union([ownerContactID])
            let placeIDs = Set(device.places.map(\.id))
            let photoIDs = Set(device.photos.map(\.id))
            let conversationIDs = Set(device.conversations.map(\.id))

            for contact in device.contacts {
                register(contact.id, "contact"); known.insert(ItemRef(.contact, contact.id))
            }
            for place in device.places {
                register(place.id, "place")
                if !(0...1).contains(place.x) || !(0...1).contains(place.y) { fail("place '\(place.id)' is off the map") }
            }
            var messageIDs = Set<String>()
            for conversation in device.conversations {
                register(conversation.id, "conversation")
                if conversation.participants.isEmpty { fail("conversation '\(conversation.id)' has no participant") }
                for p in conversation.participants where !contactIDs.contains(p) {
                    fail("conversation '\(conversation.id)' has unknown participant '\(p)'")
                }
                for m in conversation.messages {
                    register(m.id, "message"); messageIDs.insert(m.id); known.insert(ItemRef(.message, m.id))
                    if !contactIDs.contains(m.from) { fail("message '\(m.id)' from unknown contact '\(m.from)'") }
                    if m.text == nil && m.photo == nil { fail("message '\(m.id)' is empty") }
                    if let p = m.photo, !photoIDs.contains(p) { fail("message '\(m.id)' has unknown photo '\(p)'") }
                    if let d = m.deletedAt, d < m.at { fail("message '\(m.id)' deleted before being sent") }
                }
                if let draft = conversation.draft {
                    register(draft.id, "draft"); known.insert(ItemRef(.draft, draft.id))
                }
            }
            for call in device.calls {
                register(call.id, "call"); known.insert(ItemRef(.call, call.id))
                if !contactIDs.contains(call.contact) { fail("call '\(call.id)' with unknown contact '\(call.contact)'") }
            }
            for track in device.tracks {
                register(track.id, "track"); known.insert(ItemRef(.track, track.id))
                if !contactIDs.contains(track.contact) { fail("track '\(track.id)' of unknown contact '\(track.contact)'") }
                for point in track.points {
                    register(point.id, "track point")
                    if !placeIDs.contains(point.place) { fail("track point '\(point.id)' at unknown place '\(point.place)'") }
                }
                if track.points.isEmpty { fail("track '\(track.id)' has no point") }
            }
            for photo in device.photos {
                register(photo.id, "photo")
                known.insert(ItemRef(.photo, photo.id)); known.insert(ItemRef(.photoInfo, photo.id))
                if photo.source == .received && (photo.from == nil || photo.receivedAt == nil) {
                    fail("received photo '\(photo.id)' needs 'from' and 'receivedAt'")
                }
                if let from = photo.from, !contactIDs.contains(from) { fail("photo '\(photo.id)' from unknown contact '\(from)'") }
            }
            for event in device.calendar { register(event.id, "calendar event"); known.insert(ItemRef(.calendar, event.id)) }
            for note in device.notes { register(note.id, "note"); known.insert(ItemRef(.note, note.id)) }
            for mail in device.mails { register(mail.id, "mail"); known.insert(ItemRef(.mail, mail.id)) }
            for entry in device.browser { register(entry.id, "browser entry"); known.insert(ItemRef(.browser, entry.id)) }
            for app in AppID.allCases { known.insert(ItemRef(.app, app.rawValue)) }

            for event in device.liveEvents {
                register(event.id, "live event")
                if event.afterSeconds < 0 || event.afterSeconds >= file.durationSeconds {
                    fail("live event '\(event.id)' happens outside the investigation")
                }
                switch event.kind {
                case .message:
                    guard let c = event.conversation, conversationIDs.contains(c), let m = event.message else {
                        fail("live message '\(event.id)' needs a known 'conversation' and a 'message'"); break
                    }
                    register(m.id, "live message"); messageIDs.insert(m.id); known.insert(ItemRef(.message, m.id))
                    if !contactIDs.contains(m.from) { fail("live message '\(m.id)' from unknown contact '\(m.from)'") }
                case .call:
                    guard let call = event.call else { fail("live call '\(event.id)' needs a 'call'"); break }
                    register(call.id, "live call"); known.insert(ItemRef(.call, call.id))
                    if !contactIDs.contains(call.contact) { fail("live call '\(event.id)' with unknown contact") }
                case .deletion:
                    if event.deletesMessage == nil || event.conversation == nil {
                        fail("deletion '\(event.id)' needs 'conversation' and 'deletesMessage'")
                    }
                case .reminder:
                    break
                }
            }
            for event in device.liveEvents where event.kind == .deletion {
                if let target = event.deletesMessage, !messageIDs.contains(target) {
                    fail("deletion '\(event.id)' targets unknown message '\(target)'")
                }
            }
            for lock in device.lockedApps where lock.code.isEmpty { fail("empty code for locked app '\(lock.app.rawValue)'") }
        }

        let suspectIDs = Set(file.suspects.map(\.id))
        for suspect in file.suspects {
            register(suspect.id, "suspect")
            if !file.devices.contains(where: { $0.contacts.contains { $0.id == suspect.contact } }) {
                fail("suspect '\(suspect.id)' has no contact '\(suspect.contact)'")
            }
        }
        if !suspectIDs.contains(file.solution.culprit) { fail("the culprit '\(file.solution.culprit)' is not a suspect") }

        for evidence in file.evidence {
            register(evidence.id, "evidence")
            if evidence.refs.isEmpty { fail("evidence '\(evidence.id)' has no reference") }
            for ref in evidence.refs where !known.contains(ref) { fail("evidence '\(evidence.id)' references unknown '\(ref)'") }
            for s in evidence.suspects where !suspectIDs.contains(s) { fail("evidence '\(evidence.id)' about unknown suspect '\(s)'") }
        }
        let keyAboutCulprit = file.evidence.filter { $0.importance == .key && $0.suspects.contains(file.solution.culprit) }
        if keyAboutCulprit.count < 2 { fail("the culprit needs at least 2 key pieces of evidence (found \(keyAboutCulprit.count))") }
        if !file.evidence.contains(where: { $0.importance == .falseLead }) { fail("a case needs at least one false lead") }

        for hint in file.hints {
            register(hint.id, "hint")
            if hint.scoreCost < 0 { fail("hint '\(hint.id)' has a negative cost") }
        }
        let evidenceIDs = Set(file.evidence.map(\.id))
        for step in file.solution.reveal {
            if let e = step.evidence, !evidenceIDs.contains(e) { fail("reveal step references unknown evidence '\(e)'") }
        }
        if file.solution.reveal.isEmpty { fail("the solution needs reveal steps") }
        for suspect in file.suspects {
            if let e = suspect.alibiEvidence, !evidenceIDs.contains(e) { fail("suspect '\(suspect.id)' alibi references unknown evidence '\(e)'") }
            if suspect.id != file.solution.culprit && suspect.alibi == nil { fail("innocent suspect '\(suspect.id)' needs an alibi") }
        }
        for device in file.devices {
            for event in device.liveEvents {
                if let ref = event.opens, !known.contains(ref) { fail("live event '\(event.id)' opens unknown '\(ref)'") }
            }
        }
        return issues
    }
}
