# CLAUDE.md — CONCLUDE : ENQUÊTES

Nom du jeu : **CONCLUDE : ENQUÊTES** (nom sous l'icône : « Conclude »). Anciens noms de travail : SCREENSHOT,
TRACE — ils restent dans les identifiants internes (cible Xcode `Screenshot`, package `ScreenshotKit`,
`Trace.*` pour le design, bundle `com.aizenpyth.screenshot`, à ne pas changer : TestFlight y est lié).
Studio : NOREL GAMES. Logo maître : `docs/brand/logo_conclude_master.png` ; dérivés (handoff final §H) : icône
`Screenshot/Assets.xcassets/AppIcon.appiconset`, tuile de lancement `LaunchTile`, `Art.xcassets/Brand/{logo_tile, logo_wordmark}`.

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
  personnage, aucun style enfantin ou cartoon. Avatars = initiales (aucun portrait). **Photos = vraies photographies
  uniquement** (jamais d'image IA) : voir « Photos (pipeline) ».

## Structure du dépôt

```
Screenshot.xcodeproj/     Coquille de l'app iOS (+ schéma partagé « Screenshot »)
Screenshot/               App : ScreenshotApp.swift, Assets.xcassets (icône), InfoPlist.xcstrings
ScreenshotUITests/        Tests d'interface (XCUITest) : parcours principal joué sur simulateur
Configs/Screenshot.xcconfig  Bundle ID, version, signature (source unique) ; Configs/Info.plist = écran de lancement
.github/workflows/        ios-build.yml (compilation iOS, chaque push) · tests-linux.yml (chaque push) ·
                          ios-testflight.yml (manuel + PR vers main). Contenu de référence : docs/CI_WORKFLOWS.md
docs/TESTFLIGHT_SETUP.md  Signature et TestFlight sans Mac
docs/CASE_AUTHORING.md    Écrire une nouvelle affaire (JSON)
docs/CINEMATIQUES_VEO.md  ARCHIVÉ — prompts Veo des anciennes cinématiques (retirées du jeu en V3)
docs/design_final/        Handoff FINAL V3.0 (NE PAS MODIFIER) — parcours, écrans 01–15, tutoriel, états, critères
docs/design/              Handoff design SCREENSHOT v1.0 (NE PAS MODIFIER) — tokens du téléphone
docs/brand/               Logo CONCLUDE : ENQUÊTES (source de l'icône)
docs/design_trace/        Handoff TRACE v2 « dossier d'enquête » (NE PAS MODIFIER) — tout ce qui est hors du téléphone
docs/design_story/        Handoff « Mode Histoire » (NE PAS MODIFIER) — Bureau à 3 modes, écrans h01–h19, 3D, décors, PNJ
docs/game_modes/          ALIBI.md, STORY.md (mode Histoire) ; docs/story/ : architecture, personnages, scènes,
                          progression, sauvegarde du mode Histoire (comment ajouter chapitre, scène, PNJ, décor…)
DESIGN_INTEGRATION.md     État de l'intégration du handoff + conflits à trancher
config/                   photo_pipeline.json (réglages du pipeline photo, à la main), photo_catalog.json (décision
                          par photo, généré puis éditable), photo_sources.json (provenance, généré)
config/photo_queries/     une fiche par affaire : décision et requêtes de chaque photo (REAL / PROCEDURAL / CUSTOM)
docs/photo_pipeline/      PHOTO_PIPELINE (fonctionnement), PHOTO_AUDIT, PHOTO_SOURCES (générés), PHOTO_INTEGRATION
docs/game_modes/          ALIBI.md (le mode), ALIBI_CASES.md (les vérifications livrées, écrire la suivante)
docs/game_design/         difficulté et chemin minimal de chaque affaire (README + case_00N.md)
ScreenshotKit/            Package Swift contenant tout le jeu
  Sources/CaseEngine/     Moteur en Swift pur (Foundation). Testable sous Linux.
    Model/                CaseFile (affaire), Moment (heure murale), ItemRef, GameRules, loader, validateur
    Engine/               Investigation (timer, coûts, données visibles, événements live, verdict),
                          MessageSearch, Verdict/score, CaseIndex, CaseAnalysis (résolvabilité)
    Support/              GameClock (SystemClock / ManualClock)
  Sources/CaseLibrary/    Données : Resources/Cases/case_XXX.json (enquêtes) + alibi_XXX.json (mode ALIBI) + Resources/Rules/rules.json
  Sources/ScreenshotUI/   Interface SwiftUI (iOS uniquement, fichiers entourés de #if os(iOS))
    Session/              GameSession (moteur, navigation, versement, bannières, haptiques), ProgressStore (tentatives,
                          meilleur résultat par niveau), Preferences (réglages, temps détendu), Player (enquêteur
                          choisi, rangs, affectation), Tutorial (3 bulles du #001), AudioDirector (sons)
    Phone/                Le téléphone : barre d'état, accueil, bannières, et chaque app (Apps/)
    Screens/              RootView (flux), AlibiScreens (mode ALIBI), LaunchScreen (01), TitleScreens (02 titre, 02b reprise, 03 qui enquête ?),
                          DossierView (04 briefing), CaseOpening (sachet → téléphone), InvestigationShell (téléphone,
                          pause, versement), InvestigationView (Carnet + Indice), EndScreens (09 conclusion, 10
                          vérification, 11 rapport, 12 affectation), DeskScreens (Bureau, Archives, Enquêteur),
                          MetaScreens (niveaux, archive, Paramètres)
    Components/           Avatar/Portrait, GeneratedPhoto, Pinnable (appui long 0,4 s → FilingSheet « Verser au
                          dossier »), CoachBubble (bulles du tutoriel),
                          Dossier (pièces à conviction, fiches suspects, chronologie), Controls (boutons,
                          maintien pour confirmer, segments, en-têtes, état vide)
    Story/                Mode Histoire (SceneKit) : StoryCoordinator, StageKit (décors, personnages, caméras),
                          StoryStageView, scène (sous-titres, choix), écrans h01–h19, StoryRootView
    Theme/, Support/      Tokens du téléphone (Theme.swift), design papier (TraceDesign.swift + ConcludeKit.swift : boutons,
                          logo, tampons PNG, post-it), polices, L10n, dates, ArtLibrary (images livrées)
    Resources/            Localizable.xcstrings (fr + en), Sounds/ (générés : scripts/audio/gen_sounds.py), Fonts/ (Geist, JetBrains Mono,
                          Instrument Serif, Newsreader, IBM Plex Mono, Caveat — OFL)
  Sources/StoryEngine/    Mode Histoire, moteur en Swift pur (Foundation) : personnage, décors, scènes, campagne,
                          StoryDirector (déterministe), validateur, sauvegarde versionnée + migrations
  Sources/StoryLibrary/   Données de l'histoire : Resources/Story/{characters,npcs,locations,campaign}.json + scenes/
  Sources/CaseLint/       CLI : valide chaque affaire et vérifie qu'elle est résolvable dans le temps (+ l'histoire)
  Tests/                  CaseEngineTests (moteur), CaseLibraryTests (affaires, parties complètes,
                          traductions, absence de vocabulaire de l'ancien prototype), StoryEngineTests (histoire)
scripts/                  test.sh, setup-linux-swift.sh, cases/ (générateurs d'affaires), audio/ (sons),
                          photos.sh + photos/ (pipeline photo : Pexels / Openverse → Art.xcassets/Photos)
```

## Deux modes

- **Enquêtes** (le cœur) : « Qui est responsable ? », 4 suspects, 8 min. Difficulté progressive #001 (très accessible,
  tutoriel) → #005 (intermédiaire +). Chaque affaire a son `minimalPath` (docs/game_design).
- **ALIBI** (« VÉRIFIER. CROISER. CONCLURE. ») : une personne, une déclaration, 3–6 min, verdict ALIBI CONFIRMÉ /
  ALIBI CONTREDIT. Carte secondaire sur le Bureau. `mode: "alibi"`, `claim`, `solution.alibiHolds`, numéros ≥ 101
  (affichés ALIBI #001). Voir docs/game_modes/ALIBI.md.

## Architecture — règles

1. **CaseEngine et StoryEngine n'importent jamais SwiftUI/UIKit/SceneKit.** Foundation uniquement.
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

## Design — « papier dehors, verre dedans » (handoff final V3)

- Sources de vérité : `docs/design_final/` (V3.0 : parcours, écrans 01–15, tutoriel, états ; prime sur
  les parcours des handoffs précédents), `docs/design_trace/` (matières : bureau, dossiers, pièces, carnet,
  tampons) et `docs/design/` (le téléphone saisi). Lecture seule.
- Premier lancement : Lancement → Titre → Qui enquête ? (Élise Morel / Vincent Delmas) → Dossier #001 →
  téléphone, avec 3 bulles (EXPLORER · VERSER AU DOSSIER · RELIER) au #001 seulement. La couche carrière
  (matricule, rang ENQUÊTEUR → INSPECTEUR → SENIOR → EXPÉRIMENTÉ, profil) n'apparaît qu'après l'écran 12
  « Affectation » (après #001). Lancements suivants : Bureau, ou Titre-reprise si une enquête est en cours.
- **Aucune cinématique** (décision du porteur de projet) : l'affaire est introduite par le briefing du
  dossier et une courte ouverture (sachet de scellé → téléphone ; écran verrouillé pour #002–#005).
  Le champ `introScene` des affaires reste dans les données mais n'est plus joué.
- Trois verbes partout : EXPLORER · VERSER AU DOSSIER · CONCLURE (jamais « Épingler », « Accuser »,
  « Recrue », « Stagiaire » : `LocalizationTests.bannedWordsAreGone`). Un seul bouton plein par écran.
  Le logo n'apparaît que sur 01, 02, 02b et À propos.
  État et conflits : `DESIGN_INTEGRATION.md` (à tenir à jour). Si la maquette contredit le brief ou
  le moteur : noter le conflit et demander.
- Hors du téléphone : `Trace.*` (TraceDesign.swift) — bureau sombre, papiers, kraft, encre, tampon
  rouge, stylo bleu ; Newsreader (texte), IBM Plex Mono (champs, pièces, chrono), Caveat (manuscrit du
  joueur uniquement). Le jeu n'écrit jamais à la main à la place du joueur : seuls les tampons
  administratifs sont imprimés.
- Dans le téléphone : tokens v1.0 `Theme.*` (6 noirs étagés, `textPrimary`, `signal`, `alert`,
  `trace`, `clear`), Geist / JetBrains Mono, aucune texture papier. Deux objets papier seulement sur
  le téléphone : l'étiquette du chrono et l'onglet kraft du Carnet.
- Vocabulaire : Verser au dossier, L'accuse / Le disculpe, Conclure l'enquête, « Qui est responsable ? »,
  Rapport de clôture, Classer le dossier, Bureau, Archives, Enquêteur. Pièce n° = ordre de versement.
- Conclure = maintenir 1,2 s « MAINTENIR : {PRÉNOM} EST RESPONSABLE » ; vérification tapée 1,4 s puis
  tampon PNG RÉSOLU / NON RÉSOLU. Non résolu : « Reprendre l'enquête » (chrono plein, pièces gardées).
  Note finale = 60 · bon suspect + 25 · trouvées/total + 10 · temps restant/durée + 5 · pièces
  pertinentes/pièces − coût des indices (valeurs dans `rules.json` et l'affaire).

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

## Photos (pipeline)

- **Vraies photos uniquement, jamais d'image IA** (décision non négociable). Sources : Wikimedia Commons (API officielle),
  Pexels (si le secret `PEXELS_API_KEY` existe), Openverse ; licences CC0 / domaine public / CC BY / CC BY-SA ; rejet
  ferme des images IA, dessins, cartes, photos anciennes, personnes identifiables. Préparées par
  `./scripts/photos.sh all` (workflow `photo-pipeline.yml`, le conteneur n'accède pas à ces API), livrées dans
  `Art.xcassets/Photos/caseNNN_photo_<id>` ; `GeneratedPhoto` les affiche à la place du dessin.
- Chaque affaire a sa fiche `config/photo_queries/case_NNN.json` (REAL / PROCEDURAL / CUSTOM). Si une vraie photo est
  impossible, on **adapte le scénario** (lieu, objet, légende) sans toucher à la solution. Une photo ne montre jamais un
  personnage de l'affaire. Captures d'écran, documents, tickets : rendus du téléphone (PROCEDURAL).
- Jamais d'appel réseau dans le jeu ; crédits dans Paramètres › À propos. Voir docs/photo_pipeline/ (rapport REAL PHOTO
  COMPLIANCE).

## CI / livraison

- `ios-build.yml` : compilation de l'app pour le simulateur (sans signature) sur macOS, puis tests
  d'interface `ScreenshotUITests` (parcours complet) sur simulateur, à chaque push touchant l'app.
  Captures de chaque étape publiées sur la branche `ci/ui-screenshots` (+ `results.txt`).
  Options de lancement Debug pour les tests : `-UITestReset YES`, `-UITestDuration <s>`,
  `-UITestFirstLaunch skip|show` (skip = joueur déjà affecté, tutoriel vu ; show = tout premier lancement).
- `tests-linux.yml` : `swift test` + `CaseLint` (image Docker `swift:6.0-noble`), à chaque push.
- `photo-pipeline.yml` : tests du pipeline puis `photos.sh all` à chaque modification de `config/photo_*.json` ou
  `scripts/photos/` (ou à la main) ; commite images, manifeste, crédits et rapports sur la branche.
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
- [x] Reprise d'une enquête (sauvegarde locale), recherche globale (toutes apps)
- [x] Quitter / reprendre, niveaux Enquêteur · Détective · Expert, carte réelle (MapKit) révélée par
      les indices, photos réalistes (styles), sons
- [x] Affaires #002–#005 : « PREMIER MÉTRO », « APRÈS LA FÊTE », « 90 SECONDES », « ROUTE DE NUIT » — chacune
      avec son téléphone (fond, batterie), ses lieux et sa structure d'indices
- [x] Direction artistique TRACE v2 : Bureau, Archives, Enquêteur, dossier ouvert, pièces à conviction, fiches
      suspects, carnet de terrain, plis d'indices, vérification finale, tampons, rapports (docs/design_trace)
- [x] Handoff final V3 : premier lancement en 4 écrans, choix de l'enquêteur, tutoriel en 3 bulles, appui long
      + feuille « Verser au dossier » dans toutes les apps, barre du dossier, Carnet en 3 onglets, conclusion
      nommée, rapport, affectation au BEN, rangs, temps détendu ; cinématiques retirées (docs/design_final)
- [x] Retour testeurs : difficulté inutile retirée (chemin minimal, indices en 3 plis, Carnet orienté), photos réelles
      uniquement (Wikimedia Commons, portraits IA supprimés), mode ALIBI (3 vérifications)
- [x] Mode ALIBI (vérifications courtes) et photos réelles (Wikimedia Commons / Openverse)
- [x] Mode HISTOIRE (handoff docs/design_story) : Bureau à 3 modes, création de l'enquêteur, scènes 3D SceneKit,
      chapitres 01–02 jouables (03–05 annoncés), carrière commune, bureau à 4 niveaux, sauvegarde séparée versionnée
- [ ] Mode HISTOIRE : modèles 3D / animations / voix (docs/story/SCENE_SYSTEM.md), chapitres 03–05
- [ ] Affaires #006–#015 (6 suspects, 8–10 min), vérifications ALIBI #004+
- [ ] Plusieurs téléphones par affaire (le modèle `devices` le permet déjà ; UI de bascule à faire)
- [ ] Monnaie / tickets d'indices, iCloud
- [ ] Sons, haptiques fines, finitions d'animation, accessibilité avancée
