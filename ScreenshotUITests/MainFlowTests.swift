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
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR", "-UITestReset", "YES"]
    }

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

        // Notebook.
        goHome()
        element("phone.carnet").tap()
        sleep(1)
        snap("14-carnet-suspects")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Preuves'")).firstMatch.tap()
        wait(element("notebook.row"), 5, "élément épinglé dans le carnet")
        snap("15-carnet-preuves")
        // Close the sheet by swiping its title down.
        element("notebook.title").swipeDown(velocity: .fast)
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
