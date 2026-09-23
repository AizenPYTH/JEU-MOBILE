# CLAUDE.md — SCREENSHOT (nom de travail)

Jeu iOS d'**enquête psychologique / investigation numérique** qui se joue entièrement dans
l'interface d'un téléphone. Le joueur a un accès temporaire au téléphone d'une personne liée à une
affaire et doit, avant la fin du temps imparti, lire, chercher, remonter dans le temps, croiser les
informations et désigner le bon suspect.

**Le téléphone est le jeu.** Pas de personnage qui se déplace, pas de 3D, pas de visual novel, pas de
cinématiques, pas de jump scare. Proposition de valeur : « Je fouille un téléphone pour résoudre une
affaire avant que le temps soit écoulé. »

## Principes non négociables

- **Le temps est la mécanique centrale.** Chaque action coûte du temps (lire, charger l'historique,
  chercher, analyser une photo, ouvrir une localisation, récupérer un message, tenter un code).
  Le joueur doit sans cesse se demander si une information vaut les secondes qu'elle coûte.
- **Le jeu ne conclut jamais à la place du joueur.** Aucune fiche, aucun écran ne dit « X ment ».
  Le dossier des suspects ne fait que regrouper ce que le joueur a trouvé et coché.
- **Un téléphone réel est plein de banalités.** La majorité du contenu n'est pas un indice
  (CaseLint vérifie > 70 % de « bruit »). Fausses pistes vraies, informations inutiles, contradictions.
- **Un mauvais choix s'explique.** Le résultat n'est jamais « bon / mauvais » : ce que le joueur a
  trouvé de juste, ce que ça voulait vraiment dire, ce qu'il a manqué (révélé progressivement).
  La solution complète n'est montrée que sur demande, pour garder l'envie de rejouer.
- **Identité** : mystérieuse, moderne, réaliste, légèrement sombre, premium, adulte (16–40 ans).
  Noir, blanc, gris, quelques accents, transparences, flou, lignes fines. Aucune illustration de
  personnage, aucun style enfantin ou cartoon. Avatars = initiales, photos = images générées.

## Structure du dépôt

```
Screenshot.xcodeproj/     Coquille de l'app iOS (+ schéma partagé « Screenshot »)
Screenshot/               App : ScreenshotApp.swift, Assets.xcassets (icône), InfoPlist.xcstrings
ScreenshotUITests/        Tests d'interface (XCUITest) : parcours principal joué sur simulateur
Configs/Screenshot.xcconfig  Bundle ID, version, signature (source unique)
.github/workflows/        ios-build.yml (compilation iOS, chaque push) · tests-linux.yml (chaque push) ·
                          ios-testflight.yml (manuel + PR vers main). Contenu de référence : docs/CI_WORKFLOWS.md
docs/TESTFLIGHT_SETUP.md  Signature et TestFlight sans Mac
docs/CASE_AUTHORING.md    Écrire une nouvelle affaire (JSON)
docs/design/              Handoff design SCREENSHOT v1.0 (NE PAS MODIFIER) — lire README.md
DESIGN_INTEGRATION.md     État de l'intégration du handoff + conflits à trancher
ScreenshotKit/            Package Swift contenant tout le jeu
  Sources/CaseEngine/     Moteur en Swift pur (Foundation). Testable sous Linux.
    Model/                CaseFile (affaire), Moment (heure murale), ItemRef, GameRules, loader, validateur
    Engine/               Investigation (timer, coûts, données visibles, événements live, verdict),
                          MessageSearch, Verdict/score, CaseIndex, CaseAnalysis (résolvabilité)
    Support/              GameClock (SystemClock / ManualClock)
  Sources/CaseLibrary/    Données : Resources/Cases/case_XXX.json + Resources/Rules/rules.json
  Sources/ScreenshotUI/   Interface SwiftUI (iOS uniquement, fichiers entourés de #if os(iOS))
    Session/              GameSession (moteur, navigation, bannières, haptiques), ProgressStore (tentatives),
                          Preferences (réglages)
    Phone/                Le téléphone : barre d'état, accueil, bannières, et chaque app (Apps/)
    Screens/              RootView (flux), MetaScreens (Accueil, Affaires, Intro, Dossiers, Profil, Paramètres),
                          InvestigationView (téléphone + Carnet + Indices), EndScreens (temps écoulé,
                          accusation, résultat, score)
    Components/           Avatar/Portrait, GeneratedPhoto, Pinnable (épingler / lier), Controls (boutons,
                          maintien pour confirmer, segments, en-têtes, état vide)
    Theme/, Support/      Tokens du handoff (Theme.swift), polices (Fonts.swift), L10n, formats de date
    Resources/            Localizable.xcstrings (fr + en), Fonts/ (Geist, JetBrains Mono, Instrument Serif — OFL)
  Sources/CaseLint/       CLI : valide chaque affaire et vérifie qu'elle est résolvable dans le temps
  Tests/                  CaseEngineTests (moteur), CaseLibraryTests (affaires, parties complètes,
                          traductions, absence de vocabulaire de l'ancien prototype)
scripts/                  test.sh, setup-linux-swift.sh
```

## Architecture — règles

1. **CaseEngine n'importe jamais SwiftUI/UIKit.** Foundation uniquement.
2. **Aucune affaire dans le code.** Une affaire = un fichier JSON. Ajouter une affaire ne touche jamais
   le moteur (voir docs/CASE_AUTHORING.md). Les ids sont uniques dans toute l'affaire.
3. **Aucun réglage en dur.** Coûts en temps, taille des pages, score : `rules.json`.
4. **Le temps réel vient d'un `GameClock` injecté.** Jamais `Date()` dans CaseEngine. Les heures d'une
   affaire sont des `Moment` (heure murale, sans fuseau).
5. **Modèle de temps** : `écoulé = temps réel d'enquête + coûts des actions`. L'horloge du téléphone
   avance avec. Pause automatique quand l'app passe en arrière-plan.
6. **La présentation ne contient pas de règle de jeu** : elle appelle `Investigation` via `GameSession`.
   Ce qui s'affiche à l'écran est signalé gratuitement au moteur (`markSeen`). Une preuve est
   **trouvée** quand elle a été vue **et épinglée** dans le Carnet (`Investigation.isFound`) : voir ne
   suffit pas, le joueur doit reconnaître l'indice.
7. **Aucune couleur / police / taille en dur dans les vues** : `Theme.*`.
8. Textes d'interface dans le String Catalog (fr par défaut + en) via `L10n.t/f`. Le contenu d'une
   affaire est écrit dans la langue du téléphone saisi.
9. Pas de dépendance tierce sans accord du porteur de projet.

## Design (handoff SCREENSHOT v1.0)

- Source de vérité visuelle : `docs/design/` (lecture seule). État et conflits : `DESIGN_INTEGRATION.md`
  (à tenir à jour). Si la maquette contredit le brief ou le moteur : noter le conflit et demander.
- Tokens = noms du handoff dans `Theme` : 6 noirs étagés (`ink0` → `bgSelected`), le blanc cassé
  `textPrimary` est la couleur d'action, ambre `signal` = épinglé / important, `alert` = urgence et chrono
  critique, `trace` = liens, `clear` = disculpé / réussi. Jamais de noir pur ni de blanc pur.
- Polices : Geist (interface), JetBrains Mono (données, heures, chrono), Instrument Serif italique
  (voix narrative). Toujours `Theme.Fonts.*`.
- Apps en « tableau périodique » (2 lettres) ; barre d'état = pastille du chrono (normal / ≤ 60 s /
  ≤ 10 s) ; capsule Carnet en bas ; tout contenu s'épingle par appui long et se lie à un suspect.
- Accusation = maintenir 900 ms. Score = 60 · bon suspect + 25 · trouvées/total + 10 · temps restant/durée
  + 5 · épingles pertinentes/épingles − coût des indices (valeurs dans `rules.json` et l'affaire).

## Conventions

- Swift 6 (concurrence stricte), iOS 17 minimum, iPhone portrait, interface sombre.
- Code et commentaires en anglais ; docs pour le porteur de projet en français.
- Tests : Swift Testing. Toute nouvelle règle du moteur a ses tests ; toute affaire est couverte par
  CaseValidator + CaseAnalysis (tests automatiques).

## Commandes

```bash
./scripts/test.sh                        # tests + CaseLint
cd ScreenshotKit && swift test           # tests seuls
cd ScreenshotKit && swift run CaseLint   # rapport sur chaque affaire
```

Sous Linux (conteneur cloud, pas de Xcode) : `./scripts/setup-linux-swift.sh` puis
`export PATH=/opt/swift/usr/libexec/swift/bin:$PATH LD_LIBRARY_PATH=/opt/swift/usr/lib/x86_64-linux-gnu`.
L'interface (ScreenshotUI) ne compile qu'avec Xcode : c'est `ios-build.yml` (macOS) qui la vérifie.

## CI / livraison

- `ios-build.yml` : compilation de l'app pour le simulateur (sans signature) sur macOS, puis tests
  d'interface `ScreenshotUITests` (parcours complet) sur simulateur, à chaque push touchant l'app.
  Captures de chaque étape publiées sur la branche `ci/ui-screenshots` (+ `results.txt`).
  Options de lancement Debug pour les tests : `-UITestReset YES`, `-UITestDuration <s>`.
- `tests-linux.yml` : `swift test` + `CaseLint` (image Docker `swift:6.0-noble`), à chaque push.
- `ios-testflight.yml` : macOS, manuel ou PR vers `main`. Tests, archive signée, export, envoi
  TestFlight via clé API. Build = `<run_number + BUILD_NUMBER_OFFSET>.<attempt>`. Sans secrets :
  compile pour le simulateur seulement.
- Ne jamais mettre `DEVELOPMENT_TEAM` / `PROVISIONING_PROFILE_SPECIFIER` en ligne de commande :
  passer par `APP_TEAM_ID` / `APP_PROFILE_SPECIFIER` (sinon les cibles du package cassent).

## Feuille de route

- [x] Prototype jouable : accueil, téléphone (12 apps), timer + coûts, notifications en direct,
      recherche, corbeille, app verrouillée, dossier des suspects, indices payants, accusation,
      résultat narratif + score. Affaire #001 « LE DERNIER MESSAGE ».
- [x] Intégration du handoff v1.0 : tokens, polices, composants, écrans méta, carnet, fin de partie
      (reste : voir DESIGN_INTEGRATION.md §3)
- [ ] Recherche globale (toutes apps, filtres par date / contact / app)
- [ ] Affaires #002–#005 (4 suspects, 5 min) puis #006–#015 (6 suspects, 8–10 min)
- [ ] Plusieurs téléphones par affaire (le modèle `devices` le permet déjà ; UI de bascule à faire)
- [ ] Monnaie / tickets d'indices, sauvegarde d'une enquête en cours, iCloud
- [ ] Sons, haptiques fines, finitions d'animation, accessibilité avancée
