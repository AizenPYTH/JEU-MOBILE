import XCTest

/// Plays the main path of SCREENSHOT on a simulator, like a player would, and keeps a screenshot of
/// every step (exported by CI as the "ui-screenshots" artifact).
///
/// Home → Cases → case intro → phone → notification → apps (Messages, Photos, Notifications)
/// → pin evidence → notebook → timer → accusation → result → reconstruction → score → archive.
/// Plus: quitting and resuming, the three challenge levels and replaying, the map, the opening sequence.
final class MainFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = baseArguments + ["-UITestOnboarding", "skip", "-UITestCinematic", "skip"]
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
    private func tap(_ element: XCUIElement, _ what: String, expecting result: XCUIElement) {
        tapWhenReady(element, what)
        if !result.waitForExistence(timeout: 4) {
            snap("retry-\(what)")
            element.tap()
        }
        wait(result, 6, "après « \(what) »")
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

    private func pin(_ target: XCUIElement, _ name: String) {
        target.press(forDuration: 1.2)
        let pinButton = app.buttons["Verser au dossier"]
        wait(pinButton, 5, "context menu « Verser au dossier »")
        snap(name)
        pinButton.tap()
    }

    /// Selects a suspect card on the accusation screen (checked through its "selected" trait).
    private func choose(_ suspect: XCUIElement) {
        tapWhenReady(suspect, "suspect")
        if !suspect.isSelected {
            usleep(500_000)
            suspect.tap()
        }
        XCTAssertTrue(suspect.isSelected, "Le suspect n'est pas sélectionné")
    }

    /// "Maintenir pour confirmer" (900 ms): hold well past the threshold, once more if needed.
    private func holdToAccuse() {
        let hold = element("accuse.hold")
        let result = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier IN %@", ["result.primary", "result.reveal"])).firstMatch
        wait(hold, 5, "bouton maintenir")
        usleep(500_000)
        hold.press(forDuration: 2.0)
        if !result.waitForExistence(timeout: 5) {
            snap("retry-maintenir")
            hold.press(forDuration: 2.5)
        }
        wait(result, 8, "écran de résultat")
    }

    /// Reads the home screen clock and the timer, and checks clock = 10:00 + time spent (±1 min for
    /// a minute boundary crossed between the two reads).
    private func assertPhoneClockMatchesTimer(caseDurationSeconds: Int, startMinuteOfDay: Int) {
        let clock = wait(element("phone.clock"), 5, "horloge du téléphone").label   // "10:02"
        let timer = element("phone.timer").label                                       // "…06:31"
        func minutesSeconds(_ text: String) -> (Int, Int)? {
            let parts = text.suffix(5).split(separator: ":").compactMap { Int($0) }
            return parts.count == 2 ? (parts[0], parts[1]) : nil
        }
        guard let (ch, cm) = minutesSeconds(clock), let (tm, ts) = minutesSeconds(timer) else {
            return XCTFail("Horloge ou chrono illisible : « \(clock) » / « \(timer) »")
        }
        let spent = caseDurationSeconds - (tm * 60 + ts)
        let expected = startMinuteOfDay + spent / 60
        let shown = ch * 60 + cm
        XCTAssertTrue(abs(shown - expected) <= 1, "Horloge \(clock) incohérente avec le chrono \(timer)")
        if spent >= 90 { XCTAssertNotEqual(clock, "10:00", "L'horloge du téléphone ne devrait plus être à 10:00") }
    }

    private func startCase() {
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        snap("01-accueil")
        openCaseScreen(shot: "02-affaires")
        sleep(3) // let the serif lines fade in
        snap("03-intro")
        tap(element("intro.start"), "Commencer l'enquête", expecting: element("phone.timer"))
    }

    /// Home (or the case list) → the presentation screen of a case (001 by default).
    private func openCaseScreen(_ id: String = "case_001", shot: String? = nil) {
        let card = element("case.\(id)")
        if !card.waitForExistence(timeout: 2) {
            tap(element("menu.cases"), "Affaires", expecting: card)
        }
        scrollTo(card)
        if let shot { snap(shot) }
        tap(card, "carte de l'affaire \(id)", expecting: element("intro.start"))
    }

    /// "Suivant" on the score screen proposes the next case; close it to go home.
    private func leaveNextCaseScreen() {
        tap(wait(element("score.next"), 8, "score"), "Suivant", expecting: element("intro.close"))
        tap(element("intro.close"), "fermer l'affaire suivante", expecting: element("home.start"))
    }

    /// Accuses Emma straight from the timer and goes through the result and score screens.
    private func accuseEmmaAndFinish(_ shot: String) {
        dismissUrgentBanner()
        tap(element("phone.timer"), "chrono", expecting: element("accuseNow.confirm"))
        let emma = element("accuse.suspect.s_emma")
        tap(element("accuseNow.confirm"), "Accuser maintenant", expecting: emma)
        choose(emma)
        holdToAccuse()
        snap(shot)
        let primary = element("result.primary")
        wait(primary, 5, "résultat")
        scrollTo(primary)
        primary.tap()
        leaveNextCaseScreen()
    }

    private func quitInvestigation() {
        dismissUrgentBanner()
        tapWhenReady(element("phone.quit"), "Quitter l'enquête")
        let confirm = app.alerts.buttons["Quitter"]
        if !confirm.waitForExistence(timeout: 4) {
            // A live notification can land on the tap: clear it and ask again.
            snap("retry-quitter")
            dismissUrgentBanner()
            tapWhenReady(element("phone.quit"), "Quitter l'enquête (2e essai)")
        }
        wait(confirm, 5, "confirmation « Quitter l'enquête ? »")
        confirm.tap()
    }

    // MARK: - Solving the case, accusing early from the timer

    func testMainPathSolvedEarly() {
        startCase()
        snap("04-telephone-accueil")

        // The timer really counts down.
        let timer = element("phone.timer")
        let before = timer.label
        sleep(3)
        XCTAssertNotEqual(before, timer.label, "Le chrono ne bouge pas")

        // The phone keeps living: Lucas writes 25 s in.
        wait(element("phone.banner"), 40, "notification en direct")
        snap("05-notification")

        // Messages → Emma → pin her 22:30 "alibi" message.
        openApp("messages")
        wait(element("conversation.c_emma"), 5, "conversation Emma")
        snap("06-messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        snap("07-conversation")
        pin(alibi, "08-menu-epingler")
        XCTAssertTrue(element("phone.carnet").label.contains("1"), "Le carnet devrait compter 1 élément")
        snap("09-epingle")

        // Annotate it against Emma: long press → "L'accuse…" → Emma Roussel.
        _ = element("phone.toast").waitForNonExistence(timeout: 4)
        alibi.press(forDuration: 1.2)
        let linkMenu = app.buttons["L'accuse…"]
        wait(linkMenu, 5, "menu « L'accuse… »")
        linkMenu.tap()
        // The conversation header is also labelled "Emma Roussel": take the item under the menu title.
        let menuTop = linkMenu.frame.maxY
        let emmaChoices = app.buttons.matching(NSPredicate(format: "label == 'Emma Roussel'"))
        wait(emmaChoices.firstMatch, 5, "Emma dans le sous-menu")
        usleep(500_000)
        let emmaChoice = emmaChoices.allElementsBoundByIndex.first { $0.frame.minY > menuTop }
        XCTAssertNotNil(emmaChoice, "Emma introuvable dans le sous-menu")
        emmaChoice?.tap()
        if !linkMenu.waitForNonExistence(timeout: 4) {
            // A tap during the submenu's animation can be swallowed: tap the choice again.
            snap("retry-lier-emma")
            if let emmaChoice, emmaChoice.exists { emmaChoice.tap() }
        }
        XCTAssertTrue(linkMenu.waitForNonExistence(timeout: 5), "Le menu ne se ferme pas")
        sleep(1)
        snap("09b-lie-a-emma")

        // Photos → the photo "at home" → analyse its metadata → pin the analysis.
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

        // Notifications app: the live events so far.
        visitApp("notifications", "Notifications", "13-notifications")
        XCTAssertTrue(app.staticTexts["Lucas Ferrand"].firstMatch.exists, "La notification de Lucas devrait être listée")

        // Every app says where the player is (icon + name in its header).
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

        // Notebook.
        element("phone.carnet").tap()
        sleep(1)
        snap("14-carnet-suspects")
        XCTAssertTrue(element("notebook.objective").exists, "Le carnet devrait rappeler l'objectif")
        element("notebook.tab.1").tap()
        wait(element("notebook.row"), 5, "élément épinglé dans le carnet")
        snap("15-carnet-indices")
        element("notebook.tab.2").tap()
        sleep(1)
        snap("15a-carnet-chronologie")
        element("notebook.tab.3").tap()
        sleep(1)
        snap("15a2-carnet-notes")
        // A suspect's file: what the phone holds about them, their statement, the linked chain.
        element("notebook.tab.0").tap()
        tap(element("notebook.suspect.s_emma"), "fiche d'Emma", expecting: element("suspect.name"))
        // The message annotated from the phone hangs from Emma's file, already marked "L'accuse";
        // "Le disculpe" is the other hand annotation.
        let against = element("suspect.stance.incriminates.0")
        scrollTo(against)
        if !against.isSelected {
            against.tap()
            usleep(600_000)
        }
        XCTAssertTrue(against.isSelected, "« L'accuse » devrait être sélectionné")
        XCTAssertFalse(element("suspect.stance.clears.0").isSelected, "« Le disculpe » ne doit pas l'être")
        sleep(1)
        snap("15a3-fiche-suspect")
        app.navigationBars.buttons.firstMatch.tap()
        wait(element("notebook.suspect.s_emma"), 5, "retour aux suspects")
        element("notebook.close").tap()
        XCTAssertTrue(element("notebook.accuse").waitForNonExistence(timeout: 5), "Le carnet ne se ferme pas")
        snap("15b-carnet-ferme")

        // Help: what each tier gives and costs (score, never time).
        dismissUrgentBanner()
        tap(element("phone.hints"), "Aide", expecting: element("hints.close"))
        sleep(1)
        snap("15c-aide")
        element("hints.close").tap()
        XCTAssertTrue(element("hints.close").waitForNonExistence(timeout: 5), "L'aide ne se ferme pas")

        // Timer → "Accuser maintenant ?"
        dismissUrgentBanner()
        tap(element("phone.timer"), "chrono", expecting: element("accuseNow.confirm"))
        snap("16-accuser-maintenant")
        let emma = element("accuse.suspect.s_emma")
        tap(element("accuseNow.confirm"), "Accuser maintenant", expecting: emma)

        // Accusation: choose Emma, hold to confirm.
        snap("17-accusation")
        XCTAssertTrue(app.staticTexts["Qui est responsable ?"].exists, "La décision finale doit poser la question")
        choose(emma)
        let accused = wait(element("accuse.youAccuse"), 5, "panneau « Vous accusez »")
        XCTAssertTrue(accused.label.contains("Emma"), "Le panneau devrait nommer la personne accusée")
        snap("18-accusation-emma")
        holdToAccuse()

        // Result: who was responsible, the decisive evidence, then the reconstruction step by step.
        snap("19-resultat")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'était responsable'")).firstMatch.exists,
                      "Le résultat doit dire qui était responsable")
        XCTAssertTrue(element("result.keyEvidence").exists, "Le résultat doit lister les éléments déterminants")
        sleep(7)
        snap("20-reconstitution")
        // The pinned 22:30 message (with the analysed photo) is officially found: ● in the reconstruction.
        let found = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Trouvé, 22:30'")).firstMatch
        XCTAssertTrue(found.exists, "La preuve épinglée devrait apparaître comme trouvée dans la reconstitution")
        scrollTo(element("result.primary"))
        element("result.primary").tap()

        // Score.
        wait(element("score.value"), 5, "score")
        sleep(3)
        snap("21-score")
        // "Suivant" proposes the next case (#002), with its own story.
        tap(element("score.next"), "Suivant", expecting: element("intro.close"))
        sleep(2)
        snap("22-affaire-suivante")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[cd] %@", "PREMIER MÉTRO")).firstMatch.exists, "L'affaire suivante devrait être la #002")

        // Archive: the attempt is listed and its reconstruction opens.
        tap(element("intro.close"), "fermer l'affaire suivante", expecting: element("home.start"))
        tap(element("menu.cases"), "Archives", expecting: element("case.case_001"))
        sleep(1)
        snap("23-archives")
        tap(element("case.case_001"), "dossier 001 aux archives", expecting: element("dossier.tab.4"))
        element("dossier.tab.4").tap()
        wait(element("dossier.reconstruction"), 5, "reconstitution du dossier clos")
        sleep(1)
        snap("24-dossier-reconstitution")
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

    // MARK: - Leaving the app during an investigation, then resuming it

    private func secondsLeft() -> Int {
        let parts = element("phone.timer").label.suffix(5).split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? parts[0] * 60 + parts[1] : -1
    }

    func testResumeAfterQuittingTheApp() {
        startCase()
        openApp("messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        pin(alibi, "50-epingler-avant-de-quitter")
        let before = secondsLeft()
        snap("51-avant-de-quitter")

        // Leave the app (it pauses and saves), kill it, stay away 10 s, relaunch without resetting.
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.terminate()
        sleep(10)
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR", "-UITestOnboarding", "skip"]
        app.launch()

        let resume = wait(element("home.resume"), 20, "carte « Reprendre l'enquête »")
        XCTAssertFalse(element("home.start").exists, "La carte Reprendre remplace « Affaire suivante »")
        XCTAssertTrue(element("home.resumeMeta").label.contains("1"), "La carte devrait compter 1 élément épinglé")
        snap("52-accueil-reprendre")
        tap(resume, "Reprendre l'enquête", expecting: element("phone.timer"))

        // Same screen, same notebook; the timer goes on from where it was (time away does not count).
        wait(element("message.m_emma_2230"), 5, "retour dans la conversation d'Emma")
        snap("53-repris-meme-ecran")
        let after = secondsLeft()
        XCTAssertTrue(after <= before && before - after <= 8,
                      "Chrono incohérent après reprise : \(before) s avant, \(after) s après")
        XCTAssertTrue(element("phone.carnet").label.contains("1"), "Le carnet devrait toujours compter 1 élément")
        goHome()
        assertPhoneClockMatchesTimer(caseDurationSeconds: 480, startMinuteOfDay: 10 * 60)
        snap("54-horloge-apres-reprise")

        // The case then ends normally.
        tap(element("phone.timer"), "chrono", expecting: element("accuseNow.confirm"))
        let emma = element("accuse.suspect.s_emma")
        tap(element("accuseNow.confirm"), "Accuser maintenant", expecting: emma)
        choose(emma)
        holdToAccuse()
        snap("55-resultat-apres-reprise")
        wait(element("result.primary"), 5, "résultat")

        // Finished: nothing left to resume.
        app.terminate()
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        XCTAssertFalse(element("home.resume").exists, "Une affaire terminée ne se reprend pas")
    }

    // MARK: - First launch: the three-step onboarding

    func testOnboarding() {
        app.launchArguments = baseArguments + ["-UITestOnboarding", "show"]
        app.launch()
        let next = wait(element("onboarding.next"), 20, "onboarding")
        XCTAssertFalse(next.isEnabled, "« Continuer » doit attendre que le geste soit fait")
        snap("40-onboarding-explorer")

        // 1 · Explorer: open Photos, analyse the photo (the demo timer loses 15 s).
        tap(element("onboarding.app.photos"), "Photos (démo)", expecting: element("onboarding.analyze"))
        tap(element("onboarding.analyze"), "Analyser (démo)", expecting: element("onboarding.metadata"))
        snap("41-onboarding-analyse")
        XCTAssertTrue(next.isEnabled)
        next.tap()

        // 2 · Épingler: hold the message.
        let target = wait(element("onboarding.pinTarget"), 5, "message à épingler")
        snap("42-onboarding-epingler")
        usleep(700_000)
        target.press(forDuration: 1.0)
        let carnet = element("onboarding.carnet")
        let pinned = expectation(for: NSPredicate(format: "label CONTAINS '1'"), evaluatedWith: carnet)
        XCTAssertEqual(XCTWaiter().wait(for: [pinned], timeout: 5), .completed, "Le carnet de la démo devrait compter 1")
        snap("43-onboarding-epingle")
        next.tap()

        // 3 · Accuser: choose, hold to confirm.
        let suspect = wait(element("onboarding.suspect.0"), 5, "suspects de la démo")
        snap("44-onboarding-accuser")
        choose(suspect)
        let hold = element("onboarding.hold")
        usleep(500_000)
        hold.press(forDuration: 2.0)
        wait(element("onboarding.accused"), 5, "accusation de la démo")
        snap("45-onboarding-accuse")
        next.tap()

        wait(element("home.start"), 10, "Accueil après l'onboarding")
        snap("46-accueil-apres-onboarding")

        // The app as it appears on the iPhone's home screen: name "TRACE" under its icon.
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var icon = springboard.icons["TRACE"]
        for _ in 0..<3 where !icon.waitForExistence(timeout: 3) {
            springboard.swipeLeft()
            icon = springboard.icons["TRACE"]
        }
        XCTAssertTrue(icon.exists, "L'icône « TRACE » devrait être sur l'écran d'accueil")
        snap("47-icone-ecran-accueil-ios")

        // Shown once: the next launch opens straight on the home screen.
        app.terminate()
        app.launchArguments = baseArguments
        app.launch()
        wait(element("home.start"), 20, "Accueil au 2e lancement")
        XCTAssertFalse(element("onboarding.next").exists, "L'onboarding ne doit apparaître qu'au premier lancement")
    }

    // MARK: - Quitting the investigation (saved), resuming from home and from the case screen

    func testQuitAndResume() {
        startCase()
        openApp("messages")
        let alibi = element("message.m_emma_2230")
        tap(element("conversation.c_emma"), "conversation Emma", expecting: alibi)
        pin(alibi, "70-epingle-avant-quitter")

        // "← Quitter" asks first; "Continuer l'enquête" goes back to the same screen.
        dismissUrgentBanner()
        tapWhenReady(element("phone.quit"), "Quitter l'enquête")
        let alert = app.alerts.firstMatch
        wait(alert, 5, "confirmation")
        XCTAssertTrue(alert.staticTexts["Quitter l'enquête ?"].exists, "La confirmation doit poser la question")
        XCTAssertTrue(alert.staticTexts["Votre progression sera sauvegardée."].exists)
        snap("71-quitter-confirmation")
        alert.buttons["Continuer l'enquête"].tap()
        wait(alibi, 5, "retour dans la conversation après « Continuer »")
        let before = secondsLeft()

        // Quit for real: home offers to resume; time away does not count.
        quitInvestigation()
        let resume = wait(element("home.resume"), 10, "carte « Reprendre l'enquête »")
        snap("72-accueil-reprendre")
        sleep(5)

        // The case screen offers it too.
        openCaseScreen()
        let introResume = wait(element("intro.resume"), 5, "« Reprendre l'enquête » sur l'écran de l'affaire")
        sleep(2)
        snap("73-affaire-reprendre")
        tap(introResume, "Reprendre (écran de l'affaire)", expecting: element("phone.timer"))
        wait(element("message.m_emma_2230"), 5, "même écran après reprise")
        XCTAssertTrue(element("phone.carnet").label.contains("1"), "Le carnet est conservé")
        let after = secondsLeft()
        XCTAssertTrue(after <= before && before - after <= 8, "Chrono incohérent : \(before) s avant, \(after) s après")
        snap("74-repris")

        // Quit again and resume from home.
        quitInvestigation()
        tap(resume, "Reprendre l'enquête (accueil)", expecting: element("phone.timer"))
        wait(element("message.m_emma_2230"), 5, "même écran après reprise depuis l'accueil")
    }

    // MARK: - Challenge levels: same case, three durations, best result per level, unlocking Expert

    func testChallengeLevelsAndReplay() {
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        openCaseScreen()
        let investigator = element("challenge.investigator")
        let detective = element("challenge.detective")
        let expert = element("challenge.expert")
        scrollTo(expert)
        XCTAssertTrue(investigator.label.contains("15:00"), "Enquêteur : 15 min (\(investigator.label))")
        XCTAssertTrue(detective.label.contains("08:00"), "Détective : 8 min (\(detective.label))")
        XCTAssertTrue(expert.label.contains("05:00"), "Expert : 5 min (\(expert.label))")
        XCTAssertTrue(detective.isSelected, "Détective est le niveau proposé par défaut")
        XCTAssertFalse(expert.isEnabled, "Expert est verrouillé tant que l'affaire n'est pas résolue en Détective")
        snap("80-niveaux")

        // Enquêteur: 15 minutes on the clock.
        investigator.tap()
        XCTAssertTrue(investigator.isSelected)
        XCTAssertTrue(element("intro.start").label.contains("15:00"), "Le bouton annonce la durée du niveau choisi")
        snap("81-niveau-enqueteur")
        tap(element("intro.start"), "Commencer (Enquêteur)", expecting: element("phone.timer"))
        XCTAssertTrue(secondsLeft() > 14 * 60, "Enquêteur démarre à 15:00 (\(secondsLeft()) s)")
        accuseEmmaAndFinish("82-resolue-enqueteur")

        // Solved at Enquêteur: shown on its card; Expert still locked.
        openCaseScreen()
        scrollTo(expert)
        XCTAssertTrue(investigator.label.contains("Résolue"), "Meilleur résultat affiché (\(investigator.label))")
        XCTAssertTrue(detective.label.contains("Non tentée") || !detective.label.contains("Résolue"))
        XCTAssertFalse(expert.isEnabled, "Résoudre en Enquêteur ne débloque pas Expert")
        snap("83-apres-enqueteur")

        // Replay the same case at Détective (8 minutes): Expert unlocks.
        detective.tap()
        tap(element("intro.start"), "Commencer (Détective)", expecting: element("phone.timer"))
        let left = secondsLeft()
        XCTAssertTrue(left > 7 * 60 && left <= 8 * 60, "Détective démarre à 08:00 (\(left) s)")
        accuseEmmaAndFinish("84-resolue-detective")
        openCaseScreen()
        scrollTo(expert)
        XCTAssertTrue(expert.isEnabled, "Expert se débloque après une réussite en Détective")
        expert.tap()
        XCTAssertTrue(element("intro.start").label.contains("05:00"))
        snap("85-expert-debloque")
        tap(element("intro.start"), "Commencer (Expert)", expecting: element("phone.timer"))
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

    // MARK: - The opening sequence, into the phone

    func testCinematicIntoThePhone() {
        app.launchArguments = baseArguments + ["-UITestOnboarding", "skip"]
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        openCaseScreen()
        tapWhenReady(element("intro.start"), "Commencer l'enquête")

        wait(element("cinematic.shot.title"), 5, "écran noir d'ouverture")
        snap("A0-intro-noir")
        wait(element("cinematic.shot.broadcast"), 10, "reportage")
        sleep(2)
        snap("A1-intro-reportage")
        let subtitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'parking du Quai 9' OR label CONTAINS 'signe de vie' OR label CONTAINS 'téléphone parlera'")).firstMatch
        wait(subtitle, 5, "sous-titres du reportage")
        sleep(5)
        snap("A2-intro-reportage-suite")
        wait(element("cinematic.shot.phone"), 15, "le téléphone sur la table")
        sleep(3)
        snap("A3-intro-telephone")
        wait(element("cinematic.shot.unlock"), 10, "déverrouillage")
        usleep(1_500_000)
        snap("A4-intro-deverrouillage")

        // The phone picked up is the game's phone; the clock did not run during the opening.
        wait(element("phone.timer"), 15, "le téléphone de l'enquête")
        XCTAssertFalse(element("cinematic.skip").exists)
        XCTAssertTrue(secondsLeft() >= 8 * 60 - 6, "Le chrono démarre quand le téléphone est en main (\(secondsLeft()) s)")
        snap("A5-telephone-en-main")
    }

    func testCinematicCanBeSkipped() {
        app.launchArguments = baseArguments + ["-UITestOnboarding", "skip"]
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        openCaseScreen()
        tapWhenReady(element("intro.start"), "Commencer l'enquête")
        let skip = wait(element("cinematic.skip"), 5, "bouton Passer")
        sleep(1)
        tap(skip, "Passer", expecting: element("phone.timer"))
        XCTAssertTrue(secondsLeft() >= 8 * 60 - 4, "Passer l'ouverture ne coûte pas de temps")
    }

    // MARK: - Cases #002–#005: each one opens its own phone

    /// A conversation that only exists in that case's phone, and the case's title.
    private let newCases: [(id: String, title: String, conversation: String)] = [
        ("case_002", "PREMIER MÉTRO", "c_anais"),
        ("case_003", "APRÈS LA FÊTE", "c_family"),
        ("case_004", "90 SECONDES", "c_team"),
        ("case_005", "ROUTE DE NUIT", "c_redac"),
    ]

    func testEveryNewCaseOpensItsOwnPhone() {
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        for (n, item) in newCases.enumerated() {
            openCaseScreen(item.id)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[cd] %@", item.title)).firstMatch.exists, "Écran de présentation de \(item.id)")
            sleep(2)
            snap("B\(n)0-\(item.id)-presentation")
            tap(element("intro.start"), "Commencer \(item.id)", expecting: element("phone.timer"))
            dismissUrgentBanner()
            snap("B\(n)1-\(item.id)-accueil-telephone")
            openApp("messages")
            wait(element("conversation.\(item.conversation)"), 8, "conversation propre à \(item.id)")
            snap("B\(n)2-\(item.id)-messages")
            openApp("photos")
            sleep(1)
            snap("B\(n)3-\(item.id)-photos")
            openApp("location")
            wait(element("location.map"), 10, "carte de \(item.id)")
            sleep(2)
            snap("B\(n)4-\(item.id)-carte")
            quitInvestigation()
            wait(element("home.resume"), 10, "reprise proposée pour \(item.id)")
        }
    }

    /// The four new opening sequences, each with its own place and phone.
    func testNewCinematics() {
        app.launchArguments = baseArguments + ["-UITestOnboarding", "skip"]
        app.launch()
        wait(element("home.start"), 20, "Accueil")
        for (n, item) in newCases.enumerated() {
            openCaseScreen(item.id)
            tapWhenReady(element("intro.start"), "Commencer \(item.id)")
            wait(element("cinematic.shot.scene"), 6, "premier plan de \(item.id)")
            sleep(3)
            snap("C\(n)0-\(item.id)-plan1")
            sleep(4)
            snap("C\(n)1-\(item.id)-plan2")
            wait(element("cinematic.shot.phone"), 25, "le téléphone de \(item.id)")
            sleep(4)
            snap("C\(n)2-\(item.id)-telephone")
            wait(element("phone.timer"), 30, "fin de l'ouverture de \(item.id)")
            snap("C\(n)3-\(item.id)-en-main")
            quitInvestigation()
            wait(element("home.resume"), 10, "retour à l'accueil")
        }
    }

    // MARK: - Time runs out, wrong accusation, reveal

    func testTimeUpWrongAccusationThenReveal() {
        app.launchArguments += ["-UITestDuration", "20"]
        startCase()
        snap("30-chrono-court")

        wait(app.staticTexts["00:00"], 40, "écran temps écoulé")
        snap("31-temps-ecoule")

        let lucas = wait(element("accuse.suspect.s_lucas"), 10, "accusation après le temps écoulé")
        snap("32-accusation-forcee")
        choose(lucas)
        holdToAccuse()

        let reveal = element("result.reveal")
        snap("33-resultat-negatif")
        scrollTo(reveal)
        reveal.tap()
        let confirm = app.sheets.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Révéler'")).firstMatch
        wait(confirm, 5, "confirmation de révélation")
        snap("34-confirmation-revelation")
        confirm.tap()

        wait(element("result.primary"), 10, "solution révélée")
        sleep(7)
        snap("35-solution-revelee")
    }
}
