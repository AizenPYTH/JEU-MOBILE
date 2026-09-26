import XCTest

/// Plays CONCLUDE : ENQUÊTES on a simulator, like a player would, and keeps a screenshot of every
/// step (published by CI on the `ci/ui-screenshots` branch).
///
/// First launch (final handoff §C): Lancement → Titre → Qui enquête ? → Dossier #001 → ouverture →
/// téléphone with the three tutorial bubbles → verser au dossier → Carnet → conclure → vérification →
/// rapport → affectation → Bureau. Then, as a returning player: the apps, the search, pause and
/// resume, the challenge levels, the map, the opening of cases #002–#005, time up and a wrong
/// conclusion with « Reprendre l'enquête ».
final class MainFlowTests: XCTestCase {
    private var app: XCUIApplication!

    /// A returning player, already assigned to the BEN, tutorial seen.
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = baseArguments + ["-UITestFirstLaunch", "skip"]
    }

    private let baseArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR", "-UITestReset", "YES"]

    // MARK: - Helpers

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @discardableResult
    private func wait(_ element: XCUIElement, _ timeout: TimeInterval = 10, _ what: String = "") -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing: \(what.isEmpty ? element.debugDescription : what)")
        return element
    }

    /// Waits until the element can be tapped and the screen transition has settled, then taps.
    private func tapWhenReady(_ element: XCUIElement, _ what: String) {
        wait(element, 10, what)
        let hittable = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: element)
        let ready = XCTWaiter().wait(for: [hittable], timeout: 5) == .completed
        usleep(700_000) // screen transitions last up to 0.7 s
        if ready {
            element.tap()
        } else {
            // XCUITest sometimes reports a visible SwiftUI element as not hittable right after an
            // animation: tap its centre. The caller still checks that the expected result appears.
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// Taps, and taps once more if the expected result did not appear (a tap during an animation
    /// can be swallowed by SwiftUI).
    private func tap(_ element: XCUIElement, _ what: String, expecting result: XCUIElement, timeout: TimeInterval = 6) {
        tapWhenReady(element, what)
        if !result.waitForExistence(timeout: 4) {
            snap("retry-\(what)")
            if element.exists { element.tap() }
        }
        wait(result, timeout, "après « \(what) »")
    }

    /// An urgent notification covers the phone with a scrim until it is dismissed.
    private func dismissUrgentBanner() {
        if app.buttons["banner.open"].exists {
            snap("urgent-banner")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()
            _ = app.buttons["banner.open"].waitForNonExistence(timeout: 3)
        }
    }

    private func goHome() {
        dismissUrgentBanner()
        element("phone.home").tap()
    }

    private func openApp(_ id: String) {
        goHome()
        wait(element("app.\(id)"), 5, "app tile \(id)").tap()
    }

    /// Opens an app from the home screen and checks it announces itself in its header.
    private func visitApp(_ id: String, _ title: String, _ shot: String) {
        openApp(id)
        let header = wait(element("app.title"), 5, "en-tête de l'app \(id)")
        XCTAssertEqual(header.label, title, "L'app ouverte devrait s'annoncer « \(title) »")
        snap(shot)
    }

    private func scrollTo(_ element: XCUIElement, maxSwipes: Int = 12) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists && element.isHittable, "Could not scroll to \(element.debugDescription)")
    }

    /// Long press (0.4 s in the game) → the « VERSER AU DOSSIER » sheet → confirm.
    private func file(_ target: XCUIElement, _ name: String) {
        dismissUrgentBanner()
        let confirm = element("filing.confirm")
        target.press(forDuration: 0.9)
        if !confirm.waitForExistence(timeout: 4) {
            snap("retry-verser-\(name)")
            dismissUrgentBanner()
            target.press(forDuration: 1.2)
        }
        wait(confirm, 5, "feuille « Verser au dossier »")
        snap(name)
        confirm.tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5), "La feuille de versement ne se ferme pas")
    }

    /// The dossier bar counts the pieces filed.
    private func assertPieces(_ n: Int) {
        let bar = wait(element("phone.bar"), 5, "barre du dossier")
        let counted = expectation(for: NSPredicate(format: "label CONTAINS %@", "\(n) pièce"), evaluatedWith: bar)
        XCTAssertEqual(XCTWaiter().wait(for: [counted], timeout: 5), .completed, "La barre devrait compter \(n) pièce(s) : « \(bar.label) »")
    }

    private func openCarnet() {
        dismissUrgentBanner()
        tap(element("phone.carnet"), "Carnet", expecting: element("notebook.title"))
    }

    /// Carnet › PIÈCES: piece `n` accuses (or clears) a suspect.
    private func link(piece n: Int, to suspect: String, accuses: Bool = true) {
        element("notebook.tab.0").tap()
        let stance = element(accuses ? "notebook.accuses.\(n)" : "notebook.clears.\(n)")
        let chip = element("notebook.suspectChip.\(suspect)")
        scrollTo(stance, maxSwipes: 6)
        tap(stance, "L'accuse / Le disculpe (pièce \(n))", expecting: chip)
        tapWhenReady(chip, "suspect \(suspect)")
        usleep(600_000)
    }

    /// Selects a suspect card on the conclusion screen (checked through its "selected" trait).
    private func choose(_ suspect: XCUIElement) {
        tapWhenReady(suspect, "suspect")
        if !suspect.isSelected {
            usleep(500_000)
            suspect.tap()
        }
        XCTAssertTrue(suspect.isSelected, "Le suspect n'est pas sélectionné")
    }

    /// « MAINTENIR : {PRÉNOM} EST RESPONSABLE » (1.2 s): hold well past the threshold, once more if needed.
    private func holdToConclude() {
        let hold = element("accuse.hold")
        let verification = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier IN %@", ["verify.view", "result.read", "result.report"])).firstMatch
        wait(hold, 5, "bouton maintenir")
        usleep(500_000)
        hold.press(forDuration: 2.2)
        if !verification.waitForExistence(timeout: 5) {
            snap("retry-maintenir")
            hold.press(forDuration: 2.6)
        }
        wait(verification, 8, "vérification du dossier")
    }

    /// Vérification (typed, stamp) → [LIRE LE RAPPORT] → the report.
    private func readReport(_ shot: String) {
        let read = wait(element("result.read"), 15, "« Lire le rapport »")
        sleep(1)
        snap(shot)
        tap(read, "Lire le rapport", expecting: element("result.report"))
    }

    /// Carnet → CONCLURE → the conclusion screen.
    private func concludeFromCarnet() {
        openCarnet()
        let conclude = element("notebook.accuse")
        let title = element("accuse.title")
        tapWhenReady(conclude, "Conclure l'enquête")
        let anyway = element("notebook.concludeAnyway")
        if anyway.waitForExistence(timeout: 2) { anyway.tap() }
        wait(title, 8, "écran de conclusion")
    }

    /// Designates Emma (#001's culprit) from the Carnet, reads the report and files the case.
    private func concludeEmmaAndFile(_ shot: String) {
        concludeFromCarnet()
        choose(element("accuse.suspect.s_emma"))
        holdToConclude()
        readReport(shot)
        let fileIt = element("result.file")
        scrollTo(fileIt)
        fileIt.tap()
        wait(element("home.title"), 10, "retour au Bureau")
    }

    /// Reads the phone's clock and the timer: clock = 10:00 + time spent (±1 min at a minute boundary).
    private func assertPhoneClockMatchesTimer(caseDurationSeconds: Int, startMinuteOfDay: Int) {
        let clock = wait(element("phone.clock"), 5, "horloge du téléphone").label   // "10:02"
        let left = secondsLeft()
        let digits = clock.filter { $0.isNumber || $0 == ":" }
        let parts = digits.suffix(5).split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, left >= 0 else {
            return XCTFail("Horloge ou chrono illisible : « \(clock) » / \(left) s")
        }
        let spent = caseDurationSeconds - left
        let expected = startMinuteOfDay + spent / 60
        let shown = parts[0] * 60 + parts[1]
        XCTAssertTrue(abs(shown - expected) <= 1, "Horloge \(clock) incohérente avec le chrono (\(left) s restantes)")
    }

    /// Seconds left, from the timer's label or value ("06:31" somewhere in it).
    private func secondsLeft() -> Int {
        let timer = element("phone.timer")
        for text in [timer.value as? String ?? "", timer.label] {
            if let range = text.range(of: #"\d{2}:\d{2}"#, options: .regularExpression) {
                let parts = text[range].split(separator: ":").compactMap { Int($0) }
                if parts.count == 2 { return parts[0] * 60 + parts[1] }
            }
        }
        return -1
    }

    /// Bureau → the case file (briefing) of a case.
    private func openCaseFile(_ id: String = "case_001", shot: String? = nil) {
        let start = element("intro.start")
        let row = element("case.\(id)")
        if row.waitForExistence(timeout: 3) {
            scrollTo(row)
            if let shot { snap(shot) }
            tap(row, "dossier \(id)", expecting: start)
        } else {
            // The featured folder of the Bureau (the next case to open).
            tap(element("home.start"), "Ouvrir le dossier", expecting: start)
        }
    }

    /// From the briefing to the phone: the opening transition (automatic unlock for #001; the lock
    /// screen of cases #002–#005 waits for the player).
    private func openPhone(_ what: String = "Ouvrir le téléphone") {
        tapWhenReady(element("intro.start"), what)
        let timer = element("phone.timer")
        let unlock = element("opening.unlock")
        if !timer.waitForExistence(timeout: 5), unlock.waitForExistence(timeout: 3) {
            tapWhenReady(unlock, "déverrouiller")
        }
        wait(timer, 10, "le téléphone de l'enquête")
    }

    private func startCase() {
        app.launch()
        wait(element("home.title"), 20, "Bureau")
        snap("01-bureau")
        openCaseFile()
        sleep(1)
        snap("02-dossier")
        openPhone()
    }

    /// « Pause » (the phone's ‹): confirm, back to the Bureau.
    private func pauseInvestigation() {
        dismissUrgentBanner()
        tapWhenReady(element("phone.quit"), "Mettre en pause")
        let confirm = element("pause.confirm")
        if !confirm.waitForExistence(timeout: 4) {
            // A live notification can land on the tap: clear it and ask again.
            snap("retry-pause")
            dismissUrgentBanner()
            tapWhenReady(element("phone.quit"), "Mettre en pause (2e essai)")
        }
        wait(confirm, 5, "« Mettre l'enquête en pause ? »")
        confirm.tap()
    }

    // MARK: - First launch: 4 taps to the phone, the tutorial of #001, the assignment

    func testFirstLaunchToTheBureau() {
        app.launchArguments = baseArguments + ["-UITestFirstLaunch", "show"]
        app.launch()

        // 01 · Launch, then 02 · Title: the banner, the promise, the three verbs, one button.
        let start = wait(element("title.start"), 20, "écran titre")
        sleep(1)
        snap("F01-titre")
        XCTAssertTrue(element("title.settings").exists, "⚙ sur l'écran titre")
        XCTAssertTrue(app.staticTexts["Un téléphone. Une disparition. Quelqu'un ment."].exists, "L'accroche")
        for verb in ["EXPLORER", "VERSER AU DOSSIER", "CONCLURE"] {
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", verb)).firstMatch.exists, "Verbe \(verb)")
        }

        // 03 · Who investigates: Élise preselected, no service number, no rank.
        tap(start, "Commencer l'enquête", expecting: element("who.continue"))
        let elise = element("who.elise")
        XCTAssertTrue(elise.isSelected, "Élise est présélectionnée")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'BEN-0'")).firstMatch.exists, "Aucun matricule avant l'affectation")
        snap("F02-qui-enquete")
        tapWhenReady(element("who.vincent"), "Vincent")
        XCTAssertTrue(element("who.vincent").isSelected, "Vincent choisi")
        snap("F03-vincent")
        tapWhenReady(elise, "Élise")

        // 04 · The briefing of #001: the mission and the three steps.
        tap(element("who.continue"), "Continuer", expecting: element("intro.start"))
        sleep(1)
        snap("F04-briefing")
        XCTAssertFalse(element("challenge.expert").exists, "Pas de choix de niveau à la première partie")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'BEN-0'")).firstMatch.exists)

        // The opening (automatic unlock), then the phone: bubble 1 under Messages.
        openPhone()
        XCTAssertTrue(secondsLeft() >= 8 * 60 - 8, "Le chrono démarre quand le téléphone est en main (\(secondsLeft()) s)")
        let bubble1 = wait(element("coach.bubble.1"), 6, "bulle 1 EXPLORER")
        snap("F05-telephone-bulle-1")

        // Bubble 1 never blocks: tapping Messages answers it.
        tap(element("app.messages"), "Messages", expecting: element("conversation.c_emma"))
        XCTAssertTrue(bubble1.waitForNonExistence(timeout: 3), "La bulle 1 disparaît quand on ouvre une app")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)

        // Bubble 2 after 2 s of reading in a conversation that holds a piece.
        if element("coach.bubble.2").waitForExistence(timeout: 6) {
            snap("F06-bulle-2")
        }
        scrollTo(alibi, maxSwipes: 4)
        file(alibi, "F07-feuille-verser")
        XCTAssertFalse(element("coach.bubble.2").exists, "Verser la pièce ferme la bulle 2")
        wait(element("piece.badge"), 5, "étiquette « PIÈCE 01 » sur le message")
        assertPieces(1)
        sleep(1)
        snap("F08-piece-versee")

        // 08 · Carnet: bubble 3 above CONCLURE, the piece on top, L'ACCUSE → Emma.
        openCarnet()
        wait(element("notebook.row"), 5, "la pièce dans le carnet")
        if element("coach.bubble.3").waitForExistence(timeout: 3) {
            snap("F09-carnet-bulle-3")
        }
        link(piece: 1, to: "s_emma")
        XCTAssertFalse(element("coach.bubble.3").exists, "Relier une pièce ferme la bulle 3")
        snap("F10-piece-reliee")

        // 09 · Conclusion: named button, hold 1.2 s.
        tapWhenReady(element("notebook.accuse"), "Conclure l'enquête")
        let emma = wait(element("accuse.suspect.s_emma"), 8, "écran de conclusion")
        snap("F11-conclusion")
        choose(emma)
        let hold = element("accuse.hold")
        XCTAssertTrue(hold.label.uppercased().contains("EMMA"), "Le bouton nomme la personne désignée (\(hold.label))")
        snap("F12-conclusion-emma")
        // A short press sends nothing.
        hold.press(forDuration: 0.3)
        sleep(1)
        XCTAssertTrue(element("accuse.title").exists, "Relâcher avant 1,2 s n'envoie rien")
        holdToConclude()

        // 10–11 · Verification, stamp, report.
        readReport("F13-verification-resolu")
        sleep(1)
        snap("F14-rapport")
        XCTAssertTrue(element("result.keyEvidence").exists, "Pièces clés du rapport")
        let fileIt = element("result.file")
        scrollTo(fileIt)

        // 12 · Assignment (once), then 13 · the Bureau.
        tap(fileIt, "Classer le dossier", expecting: element("assignment.desk"), timeout: 10)
        sleep(2)
        snap("F15-affectation")
        tap(element("assignment.desk"), "Aller au Bureau", expecting: element("home.title"))
        sleep(1)
        snap("F16-bureau")

        // The profile now shows the service number and the rank.
        tap(element("tab.investigator"), "Enquêteur", expecting: element("profile.view"))
        sleep(1)
        snap("F17-profil")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'BEN-04821'")).firstMatch.exists,
                      "Le matricule apparaît après l'affectation")

        // The app as it appears on the iPhone's home screen: « Conclude » under its icon.
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var icon = springboard.icons["Conclude"]
        for _ in 0..<3 where !icon.waitForExistence(timeout: 3) {
            springboard.swipeLeft()
            icon = springboard.icons["Conclude"]
        }
        XCTAssertTrue(icon.exists, "L'icône « Conclude » devrait être sur l'écran d'accueil")
        snap("F18-icone-ecran-accueil-ios")

        // Next launch: straight to the Bureau, no title, no assignment again.
        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
        wait(element("home.title"), 20, "Bureau au lancement suivant")
        XCTAssertFalse(element("title.start").exists, "Pas d'écran titre après l'affectation")
    }

    // MARK: - The phone, the pieces, the Carnet, the hints, concluding early

    func testMainPathSolvedEarly() {
        startCase()
        snap("04-telephone-accueil")
        XCTAssertFalse(element("coach.bubble.1").exists, "Pas de bulle pour un joueur qui connaît le jeu")

        // The timer really counts down.
        let before = secondsLeft()
        sleep(3)
        XCTAssertTrue(secondsLeft() < before, "Le chrono ne bouge pas")

        // The phone keeps living: Lucas writes 25 s in.
        wait(element("phone.banner"), 40, "notification en direct")
        snap("05-notification")

        // Messages → Emma → file her 22:30 "alibi" message.
        openApp("messages")
        wait(element("conversation.c_emma"), 5, "conversation Emma")
        snap("06-messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        snap("07-conversation")
        file(alibi, "08-verser-au-dossier")
        assertPieces(1)
        snap("09-piece-versee")

        // Filing the same piece again: « déjà au dossier » → see it in the Carnet.
        _ = element("phone.toast").waitForNonExistence(timeout: 4)
        alibi.press(forDuration: 0.9)
        let viewIt = element("filing.viewInCarnet")
        if viewIt.waitForExistence(timeout: 4) {
            snap("09b-deja-au-dossier")
            tap(viewIt, "Voir dans le carnet", expecting: element("notebook.title"))
            element("notebook.close").tap()
            XCTAssertTrue(element("notebook.title").waitForNonExistence(timeout: 5), "Le carnet ne se ferme pas")
        }

        // Photos → the photo "at home" → analyse its metadata.
        openApp("photos")
        snap("10-photos")
        let couch = element("photo.p_emma_couch")
        scrollTo(couch)
        let analyze = element("photo.analyze")
        tap(couch, "photo d'Emma", expecting: analyze)
        snap("11-photo")
        analyze.tap()
        sleep(1)
        snap("12-photo-analysee")

        // Every app says where the player is (icon + name in its header).
        visitApp("notifications", "Notifications", "13-notifications")
        visitApp("calendar", "Calendrier", "13c-calendrier")
        visitApp("location", "Carte", "13d-carte")
        visitApp("phone", "Téléphone", "13e-appels")
        visitApp("mail", "Mail", "13f-mail")
        visitApp("browser", "Navigateur", "13g-navigateur")
        visitApp("contacts", "Contacts", "13h-contacts")
        visitApp("notes", "Notes", "13i-notes")
        visitApp("trash", "Corbeille", "13j-corbeille")
        visitApp("settings", "Réglages", "13k-reglages")

        // The phone's clock runs with the investigation: start time (10:00) + time spent on the timer.
        goHome()
        assertPhoneClockMatchesTimer(caseDurationSeconds: 480, startMinuteOfDay: 10 * 60)
        snap("13b-horloge")

        // Carnet: PIÈCES · SUSPECTS · CHRONOLOGIE.
        openCarnet()
        wait(element("notebook.row"), 5, "pièce dans le carnet")
        sleep(1)
        snap("14-carnet-pieces")
        link(piece: 1, to: "s_emma")
        snap("15-carnet-liee")
        element("notebook.tab.1").tap()
        wait(element("notebook.suspect.s_emma"), 5, "fiche d'Emma")
        sleep(1)
        snap("15a-carnet-suspects")
        element("notebook.tab.2").tap()
        sleep(1)
        snap("15b-carnet-chronologie")

        // Help: each hint costs points on the final note, never time.
        tap(element("notebook.hint"), "Indice", expecting: element("hints.close"))
        sleep(1)
        snap("15c-indice")
        element("hints.close").tap()
        XCTAssertTrue(element("hints.close").waitForNonExistence(timeout: 5), "L'indice ne se ferme pas")
        element("notebook.close").tap()
        XCTAssertTrue(element("notebook.title").waitForNonExistence(timeout: 5), "Le carnet ne se ferme pas")

        // Conclude early, from the Carnet.
        concludeFromCarnet()
        snap("17-conclusion")
        choose(element("accuse.suspect.s_emma"))
        snap("18-conclusion-emma")
        holdToConclude()
        readReport("19-verification")
        sleep(1)
        snap("20-rapport")
        XCTAssertTrue(element("result.keyEvidence").exists, "Le rapport liste les pièces clés")
        let fileIt = element("result.file")
        scrollTo(fileIt)
        snap("20b-rapport-bas")
        fileIt.tap()

        // Back on the Bureau; the case is in the Archives.
        wait(element("home.title"), 10, "Bureau")
        snap("21-bureau-apres")
        tap(element("menu.cases"), "Archives", expecting: element("case.case_001"))
        sleep(1)
        snap("23-archives")
    }

    // MARK: - Phone-wide search

    func testGlobalSearchAcrossApps() {
        startCase()
        let before = secondsLeft()
        tap(element("phone.search"), "Rechercher", expecting: app.textFields.firstMatch)
        snap("60-recherche")
        let field = app.textFields.firstMatch
        field.tap()
        field.typeText("Quai 9\n")

        // Results from several apps, grouped, with chips; the search cost time.
        let calendarResult = element("search.result.calendar:c_quai9")
        wait(calendarResult, 10, "rendez-vous « P. Quai 9 » dans l'agenda")
        wait(element("search.chip.calendar"), 5, "puce Agenda")
        // The browser history too; the deleted message stays out of reach until it is recovered.
        wait(element("search.result.browser:w15"), 5, "recherche « parking quai 9 » du navigateur")
        XCTAssertFalse(element("search.result.message:m_emma_del1").exists, "Un message supprimé ne doit pas être trouvé")
        XCTAssertTrue(before - secondsLeft() >= 8, "Une recherche coûte du temps")
        snap("61-resultats-quai9")

        // Filter by app, then open the calendar result in its app.
        element("search.chip.calendar").tap()
        sleep(1)
        snap("62-filtre-agenda")
        XCTAssertFalse(element("search.result.browser:w15").exists, "Le filtre Agenda doit masquer le navigateur")
        tap(calendarResult, "résultat agenda", expecting: app.staticTexts["P. Quai 9 — E."].firstMatch)
        snap("63-evenement-ouvert")

        // A date in French: "12 sept" finds that Saturday's items.
        goHome()
        tap(element("phone.search"), "Rechercher", expecting: app.textFields.firstMatch)
        let field2 = app.textFields.firstMatch
        field2.tap()
        field2.typeText("12 sept\n")
        wait(element("search.result.calendar:c_quai9"), 10, "recherche par date")
        snap("64-recherche-date")
    }

    // MARK: - Leaving the app during an investigation, then resuming it (02b)

    func testResumeAfterQuittingTheApp() {
        startCase()
        openApp("messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        file(alibi, "50-verser-avant-de-quitter")
        let before = secondsLeft()
        snap("51-avant-de-quitter")

        // Leave the app (it pauses and saves), kill it, stay away 10 s, relaunch without resetting.
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.terminate()
        sleep(10)
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        // 02b · Titre, reprise: the investigation in progress, one button.
        let resume = wait(element("title.resume"), 20, "« Reprendre l'enquête » (écran titre)")
        XCTAssertTrue(element("title.desk").exists, "Lien « Aller au Bureau »")
        sleep(1)
        snap("52-titre-reprise")
        tap(resume, "Reprendre l'enquête", expecting: element("phone.timer"))

        // Same screen, same pieces; the timer goes on from where it was (time away does not count).
        wait(element("message.m_emma_2230"), 5, "retour dans la conversation d'Emma")
        snap("53-repris-meme-ecran")
        let after = secondsLeft()
        XCTAssertTrue(after <= before && before - after <= 8,
                      "Chrono incohérent après reprise : \(before) s avant, \(after) s après")
        assertPieces(1)
        goHome()
        assertPhoneClockMatchesTimer(caseDurationSeconds: 480, startMinuteOfDay: 10 * 60)
        snap("54-horloge-apres-reprise")

        // The case then ends normally.
        concludeFromCarnet()
        choose(element("accuse.suspect.s_emma"))
        holdToConclude()
        readReport("55-resultat-apres-reprise")

        // Finished: nothing left to resume.
        app.terminate()
        app.launch()
        wait(element("home.title"), 20, "Bureau")
        XCTAssertFalse(element("home.resume").exists, "Une affaire terminée ne se reprend pas")
        XCTAssertFalse(element("title.resume").exists)
    }

    // MARK: - Pausing the investigation (saved), resuming from the Bureau and from the case file

    func testQuitAndResume() {
        startCase()
        openApp("messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        file(alibi, "70-verse-avant-pause")

        // ‹ asks first; « Continuer » goes back to the same screen.
        dismissUrgentBanner()
        tapWhenReady(element("phone.quit"), "Mettre en pause")
        let cancel = wait(element("pause.cancel"), 5, "« Mettre l'enquête en pause ? »")
        XCTAssertTrue(element("pause.confirm").exists)
        sleep(1)
        snap("71-pause-confirmation")
        cancel.tap()
        wait(alibi, 5, "retour dans la conversation après « Continuer »")
        let before = secondsLeft()

        // Pause for real: the Bureau offers to resume; time away does not count.
        pauseInvestigation()
        let resume = wait(element("home.resume"), 10, "« Reprendre l'enquête » au Bureau")
        snap("72-bureau-reprendre")
        sleep(5)

        // The case file offers it too.
        openCaseFile()
        let introResume = wait(element("intro.resume"), 5, "« Reprendre l'enquête » sur le dossier")
        sleep(1)
        snap("73-dossier-reprendre")
        tap(introResume, "Reprendre (dossier)", expecting: element("phone.timer"))
        wait(element("message.m_emma_2230"), 5, "même écran après reprise")
        assertPieces(1)
        let after = secondsLeft()
        XCTAssertTrue(after <= before && before - after <= 8, "Chrono incohérent : \(before) s avant, \(after) s après")
        snap("74-repris")

        // Pause again and resume from the Bureau.
        pauseInvestigation()
        tap(resume, "Reprendre l'enquête (Bureau)", expecting: element("phone.timer"))
        wait(element("message.m_emma_2230"), 5, "même écran après reprise depuis le Bureau")
    }

    // MARK: - Challenge levels: same case, three durations, unlocking Expert

    /// The level choice may be folded behind a « NIVEAU » row on the case file.
    private func showLevels(_ level: XCUIElement) {
        if !level.waitForExistence(timeout: 3), element("briefing.level").exists {
            tapWhenReady(element("briefing.level"), "Niveau")
        }
        scrollTo(level)
    }

    func testChallengeLevelsAndReplay() {
        app.launch()
        wait(element("home.title"), 20, "Bureau")
        openCaseFile()
        let investigator = element("challenge.investigator")
        let detective = element("challenge.detective")
        let expert = element("challenge.expert")
        showLevels(expert)
        XCTAssertTrue(investigator.label.contains("15:00"), "Enquêteur : 15 min (\(investigator.label))")
        XCTAssertTrue(detective.label.contains("08:00"), "Détective : 8 min (\(detective.label))")
        XCTAssertTrue(expert.label.contains("05:00"), "Expert : 5 min (\(expert.label))")
        XCTAssertTrue(detective.isSelected, "Détective est le niveau proposé par défaut")
        XCTAssertFalse(expert.isEnabled, "Expert est verrouillé tant que l'affaire n'est pas résolue en Détective")
        snap("80-niveaux")

        // Enquêteur: 15 minutes on the clock.
        tapWhenReady(investigator, "Enquêteur")
        XCTAssertTrue(investigator.isSelected)
        snap("81-niveau-enqueteur")
        openPhone("Ouvrir le téléphone (Enquêteur)")
        XCTAssertTrue(secondsLeft() > 14 * 60, "Enquêteur démarre à 15:00 (\(secondsLeft()) s)")
        concludeEmmaAndFile("82-resolue-enqueteur")

        // Replay at Détective (8 minutes): Expert unlocks.
        openCaseFile()
        showLevels(detective)
        tapWhenReady(detective, "Détective")
        openPhone("Ouvrir le téléphone (Détective)")
        let left = secondsLeft()
        XCTAssertTrue(left > 7 * 60 && left <= 8 * 60, "Détective démarre à 08:00 (\(left) s)")
        concludeEmmaAndFile("84-resolue-detective")
        openCaseFile()
        showLevels(expert)
        XCTAssertTrue(expert.isEnabled, "Expert se débloque après une réussite en Détective")
        tapWhenReady(expert, "Expert")
        snap("85-expert-debloque")
        openPhone("Ouvrir le téléphone (Expert)")
        XCTAssertTrue(secondsLeft() <= 5 * 60, "Expert : 5 minutes")
    }

    // MARK: - The map: a real, explorable map; places appear as the player learns about them

    func testInteractiveMap() {
        startCase()
        openApp("location")
        let map = wait(element("location.map"), 10, "carte interactive")
        sleep(2)
        snap("90-carte")
        XCTAssertTrue(element("map.pin.pl_levant").exists, "Le Levant (connu) est sur la carte")
        XCTAssertFalse(element("map.pin.pl_quai9").exists, "Le Quai 9 n'est pas encore connu")

        // Explore: zoom in, pan, zoom out, double tap.
        map.pinch(withScale: 2.2, velocity: 1.5)
        sleep(1)
        snap("91-carte-zoom")
        map.swipeLeft()
        map.pinch(withScale: 0.5, velocity: -1.5)
        map.doubleTap()
        sleep(1)
        snap("92-carte-exploree")

        // Alex's location history: the route through the port reveals the Quai 9.
        let track = element("track.t_me")
        scrollTo(track, maxSwipes: 4)
        tap(track, "historique d'Alex", expecting: element("location.map"))
        sleep(2)
        snap("93-trajet")
        XCTAssertTrue(element("map.pin.pl_quai9").exists, "Le trajet passe par le Quai 9 : il apparaît sur la carte")
    }

    // MARK: - Cases #002–#005: the opening (lock screen) and each case's own phone

    /// A conversation that only exists in that case's phone, and the case's title.
    private let newCases: [(id: String, title: String, conversation: String)] = [
        ("case_002", "PREMIER MÉTRO", "c_anais"),
        ("case_003", "APRÈS LA FÊTE", "c_family"),
        ("case_004", "90 SECONDES", "c_team"),
        ("case_005", "ROUTE DE NUIT", "c_redac"),
    ]

    func testEveryNewCaseOpensItsOwnPhone() {
        app.launch()
        wait(element("home.title"), 20, "Bureau")
        for (n, item) in newCases.enumerated() {
            openCaseFile(item.id)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[cd] %@", item.title)).firstMatch.exists, "Dossier de \(item.id)")
            sleep(1)
            snap("B\(n)0-\(item.id)-dossier")

            // The opening: the sealed bag, then the phone's lock screen, which waits for the player.
            tapWhenReady(element("intro.start"), "Ouvrir le téléphone \(item.id)")
            if n > 0 {
                // The previous case is still in progress (paused): starting this one asks first.
                wait(element("start.cancelReplace"), 5, "« Une autre enquête est en cours » (\(item.id))")
                if n == 1 { snap("B\(n)0b-\(item.id)-autre-enquete-en-cours") }
                tapWhenReady(element("start.confirmReplace"), "Commencer quand même \(item.id)")
            }
            let unlock = wait(element("opening.unlock"), 8, "écran verrouillé de \(item.id)")
            sleep(1)
            snap("B\(n)1-\(item.id)-verrouille")
            XCTAssertFalse(element("phone.timer").exists, "Le chrono ne tourne pas avant le déverrouillage")
            tap(unlock, "déverrouiller \(item.id)", expecting: element("phone.timer"))
            XCTAssertTrue(secondsLeft() >= 8 * 60 - 6, "Le chrono démarre au déverrouillage (\(secondsLeft()) s)")
            dismissUrgentBanner()
            snap("B\(n)2-\(item.id)-accueil-telephone")
            openApp("messages")
            wait(element("conversation.\(item.conversation)"), 8, "conversation propre à \(item.id)")
            snap("B\(n)3-\(item.id)-messages")
            openApp("location")
            wait(element("location.map"), 10, "carte de \(item.id)")
            sleep(2)
            snap("B\(n)4-\(item.id)-carte")
            pauseInvestigation()
            wait(element("home.resume"), 10, "reprise proposée pour \(item.id)")
        }
    }

    // MARK: - Settings: relaxed time, replay the tutorial

    func testSettingsRelaxedTime() {
        app.launch()
        wait(element("home.title"), 20, "Bureau")
        tap(element("tab.investigator"), "Enquêteur", expecting: element("profile.view"))
        let settings = element("menu.settings")
        scrollTo(settings)
        tap(settings, "Paramètres", expecting: element("settings.relaxedTime"))
        sleep(1)
        snap("S0-parametres")
        // A SwiftUI toggle flips on its switch, not on its label.
        let relaxed = element("settings.relaxedTime")
        scrollTo(relaxed)
        let toggle = relaxed.switches.firstMatch
        (toggle.exists ? toggle : relaxed).coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        usleep(500_000)
        XCTAssertEqual((toggle.exists ? toggle : relaxed).value as? String, "1", "« Temps détendu » activé")
        let replay = element("settings.replayTutorial")
        scrollTo(replay)
        replay.tap()
        sleep(1)
        snap("S1-parametres-modifies")
        tap(element("settings.back"), "retour", expecting: element("tab.bureau"))
        tap(element("tab.bureau"), "Bureau", expecting: element("home.title"))

        // « Temps détendu »: 08:00 becomes 12:00.
        openCaseFile()
        openPhone()
        let left = secondsLeft()
        XCTAssertTrue(left > 11 * 60 && left <= 12 * 60, "Temps détendu : 12:00 au lieu de 08:00 (\(left) s)")
        // « Revoir le tutoriel »: bubble 1 is back in #001.
        wait(element("coach.bubble.1"), 6, "bulle 1 après « Revoir le tutoriel »")
        snap("S2-temps-detendu-bulle")
        element("coach.close").tap()
        XCTAssertTrue(element("coach.bubble.1").waitForNonExistence(timeout: 3), "La bulle se ferme")
    }

    // MARK: - Time runs out, wrong conclusion, « Reprendre l'enquête », the solution

    func testTimeUpWrongConclusionThenRetry() {
        app.launchArguments += ["-UITestDuration", "30"]
        startCase()
        openApp("messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        file(alibi, "30-piece-avant-la-fin")

        // 00:00: the conclusion is forced, « TEMPS ÉCOULÉ », no way back.
        wait(element("accuse.timeUp"), 40, "« TEMPS ÉCOULÉ »")
        XCTAssertFalse(element("accuse.back").exists, "Pas de retour possible après la fin du chrono")
        snap("31-temps-ecoule")

        // A wrong conclusion: Lucas.
        choose(wait(element("accuse.suspect.s_lucas"), 10, "suspects"))
        holdToConclude()
        readReport("32-verification-non-resolu")
        sleep(1)
        snap("33-rapport-non-resolu")

        // « Reprendre l'enquête »: the timer full again, the pieces kept.
        let retry = element("result.retry")
        scrollTo(retry)
        tap(retry, "Reprendre l'enquête", expecting: element("phone.timer"))
        XCTAssertTrue(secondsLeft() >= 20, "Chrono plein à la reprise (\(secondsLeft()) s)")
        assertPieces(1)
        snap("34-reprise-apres-echec")

        // Second attempt, wrong again, then the solution on request.
        wait(element("accuse.timeUp"), 45, "« TEMPS ÉCOULÉ » (2e fois)")
        choose(wait(element("accuse.suspect.s_lucas"), 10, "suspects"))
        holdToConclude()
        readReport("35-verification-2")
        let reveal = element("result.reveal")
        scrollTo(reveal)
        reveal.tap()
        let confirmReveal = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'Révéler' OR label BEGINSWITH[c] 'Consulter'")).firstMatch
        if !reveal.waitForNonExistence(timeout: 3), confirmReveal.exists {
            confirmReveal.tap()
        }
        XCTAssertTrue(reveal.waitForNonExistence(timeout: 8), "La solution s'affiche")
        sleep(2)
        snap("36-solution-revelee")
    }
}
