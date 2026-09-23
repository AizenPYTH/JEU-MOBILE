import XCTest

/// Plays the main path of SCREENSHOT on a simulator, like a player would, and keeps a screenshot of
/// every step (exported by CI as the "ui-screenshots" artifact).
///
/// Home → Cases → case intro → phone → notification → apps (Messages, Photos, Notifications)
/// → pin evidence → notebook → timer → accusation → result → reconstruction → score → archive.
final class MainFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = baseArguments + ["-UITestOnboarding", "skip"]
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
        XCTAssertEqual(XCTWaiter().wait(for: [hittable], timeout: 5), .completed, "Not tappable: \(what)")
        usleep(700_000) // screen transitions last up to 0.7 s
        element.tap()
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
        let pinButton = app.buttons["Épingler"]
        wait(pinButton, 5, "context menu « Épingler »")
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

        let card = element("case.case_001")
        tap(element("menu.cases"), "Affaires", expecting: card)
        snap("02-affaires")
        tap(card, "carte de l'affaire 001", expecting: element("intro.start"))
        sleep(3) // let the serif lines fade in
        snap("03-intro")
        tap(element("intro.start"), "Commencer l'enquête", expecting: element("phone.timer"))
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
        openApp("notifications")
        sleep(1)
        snap("13-notifications")
        XCTAssertTrue(app.staticTexts["Lucas Ferrand"].firstMatch.exists, "La notification de Lucas devrait être listée")

        // The phone's clock runs with the investigation: start time (10:00) + time spent on the timer.
        goHome()
        assertPhoneClockMatchesTimer(caseDurationSeconds: 480, startMinuteOfDay: 10 * 60)
        snap("13b-horloge")

        // Notebook.
        element("phone.carnet").tap()
        sleep(1)
        snap("14-carnet-suspects")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Preuves'")).firstMatch.tap()
        wait(element("notebook.row"), 5, "élément épinglé dans le carnet")
        snap("15-carnet-preuves")
        element("notebook.close").tap()
        XCTAssertTrue(element("notebook.accuse").waitForNonExistence(timeout: 5), "Le carnet ne se ferme pas")
        snap("15b-carnet-ferme")

        // Timer → "Accuser maintenant ?"
        dismissUrgentBanner()
        tap(element("phone.timer"), "chrono", expecting: element("accuseNow.confirm"))
        snap("16-accuser-maintenant")
        let emma = element("accuse.suspect.s_emma")
        tap(element("accuseNow.confirm"), "Accuser maintenant", expecting: emma)

        // Accusation: choose Emma, hold to confirm.
        snap("17-accusation")
        choose(emma)
        snap("18-accusation-emma")
        holdToAccuse()

        // Result + reconstruction, step by step.
        snap("19-resultat")
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
        element("score.next").tap()
        sleep(1)
        snap("22-apres-score")

        // Archive: the attempt is listed and its reconstruction opens.
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Accueil'")).firstMatch.tap()
        wait(element("home.start"), 5, "retour à l'accueil")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Dossiers'")).firstMatch.tap()
        sleep(1)
        snap("23-dossiers")
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'dernier message'")).firstMatch.tap()
        sleep(1)
        snap("24-dossier-reconstitution")
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

        // Shown once: the next launch opens straight on the home screen.
        app.terminate()
        app.launchArguments = baseArguments
        app.launch()
        wait(element("home.start"), 20, "Accueil au 2e lancement")
        XCTAssertFalse(element("onboarding.next").exists, "L'onboarding ne doit apparaître qu'au premier lancement")
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
