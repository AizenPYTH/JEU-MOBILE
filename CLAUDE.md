# CLAUDE.md — Bistro (nom de code)

Jeu mobile iOS idle / gestion de restaurant « cozy ». Le joueur tient un bistrot de quartier qui
tourne tout seul ; le plaisir vient du **labo de recettes** (découvrir des plats en combinant des
ingrédients) et des **habitués** (clients récurrents avec affinité et histoires).

Ne jamais utiliser « Idle » + « Tycoon » dans le nom (marque déposée).

## Principes non négociables

- Pas de prestige / remise à zéro. Le restaurant grandit en permanence.
- Pas de pub forcée : uniquement des pubs récompensées choisies par le joueur, plafonnées par jour et par type.
- Boutique simple, jamais agressive. Aucun achat nécessaire pour progresser.
- Toujours quelque chose d'intéressant à faire à l'ouverture.
- Ambiance douce, jamais stressante. Public 25–55 ans, sessions de 3 à 10 min.

## Structure du dépôt

```
Bistro.xcodeproj/        Coquille de l'app iOS (ouvre ce fichier dans Xcode)
Bistro/                  Code de l'app : uniquement BistroApp.swift + Assets.xcassets
BistroKit/               Package Swift contenant TOUT le jeu
  Sources/GameCore/      Moteur en Swift pur (Foundation seulement). Testable sous Linux.
  Sources/GameData/      Fichiers JSON embarqués (aucune logique)
    Resources/Content/   Contenu : ingredients, stations, recipes, regulars, zones, decorations
    Resources/Config/    Équilibrage : economy, lab, affinity, progression, offline, ads
  Sources/BistroUI/      Présentation SwiftUI + SpriteKit (Apple uniquement, exclu sous Linux)
    Theme/               DesignTokens (couleurs, typo, espacements, rayons, ombres, animations)
    Components/          Composants réutilisables (GameImage + placeholder, boutons, cartes…)
    Screens/             Écrans
    Localization/        L10n (accès au String Catalog)
    Resources/           Localizable.xcstrings (en + fr)
  Sources/BalanceSim/    Outil CLI de simulation d'équilibrage (`swift run BalanceSim`)
  Tests/                 GameCoreTests, GameDataTests (Swift Testing)
scripts/                 test.sh, setup-linux-swift.sh
HANDOFF_INTEGRATION.md   Ce que l'on attend du design (tokens, composants, assets)
```

## Architecture — règles

1. **GameCore n'importe jamais SwiftUI, UIKit ni SpriteKit.** Foundation uniquement.
2. **Le temps vient toujours d'un `GameClock` injecté** (`SystemClock` en prod, `ManualClock` en test/simu).
   Jamais de `Date()` dans GameCore.
3. **Aucun nombre d'équilibrage en dur dans le Swift.** Tout va dans `GameData/Resources/Config/*.json`.
   Prix de base et temps de préparation d'un plat vivent dans `recipes.json` (JSON, donc réglables).
4. **Aucun contenu en dur.** Tout va dans `GameData/Resources/Content/*.json`.
5. **Aucun texte affiché dans le JSON.** Les textes sont dans le String Catalog, avec des clés dérivées de
   l'id via `LocalizationKey` (ex. `dish.bruschetta.name`, `regular.margot.story.2`).
6. **Aucun nom d'asset écrit à la main.** Toujours `AssetName.*` (ex. `AssetName.ingredient("tomato")` → `ing_tomato`).
   Un asset manquant affiche un placeholder visible (`GameImage`), jamais de crash.
7. **Aucune couleur / police / taille / durée en dur dans les vues.** Toujours `Theme.*`.
8. La présentation lit l'état du moteur et lui envoie des actions ; elle ne contient pas de règles de jeu.
9. Pas de dépendance tierce sans accord explicite du porteur de projet.
10. Services externes (pubs, analytics, achats) derrière des protocoles avec implémentation factice.

## Conventions

- Swift 6 (mode de langage 6, concurrence stricte), iOS 17 minimum, iPhone portrait uniquement.
- Code, identifiants et commentaires de code en anglais ; docs pour le porteur de projet en français.
- Ids de contenu : `snake_case` minuscule (vérifié par `ContentValidator`). Ils sont partagés avec
  Claude Design : ne jamais renommer un id sans mettre à jour HANDOFF_INTEGRATION.md.
- Chaque fichier JSON a un `schemaVersion`. Toute évolution incompatible = incrément + migration.
- Tests : Swift Testing (`import Testing`, `@Test`, `#expect`). Tout nouveau système de GameCore a ses tests.
- Toute modif de contenu ou de config doit laisser `swift test` au vert (les tests valident les JSON et
  la présence des traductions en/fr pour chaque id).

## Commandes

```bash
cd BistroKit && swift test          # tests moteur + validation des données
cd BistroKit && swift run BalanceSim # simulateur d'équilibrage
./scripts/test.sh                    # les deux
```

Sous Linux (conteneur cloud, pas de Xcode) : `./scripts/setup-linux-swift.sh` puis
`export PATH=/opt/swift/usr/libexec/swift/bin:$PATH LD_LIBRARY_PATH=/opt/swift/usr/lib/x86_64-linux-gnu`.
BistroUI et l'app ne compilent que sur Mac avec Xcode 16+.

## Choix techniques

- **SpriteKit** (via `SpriteView`) pour la scène vivante du restaurant : actions, atlas de textures,
  particules (pièces, découvertes) et gestion du z-order gratuits. SwiftUI pour tout le reste (HUD, panneaux, popups).
- **Sauvegarde** : JSON Codable versionné avec migrations, écrit de façon atomique ; structure pensée pour iCloud plus tard.

## Jalons

- [x] M0 – Mise en place (modules, Theme, JSON valides, tests, docs)
- [ ] M1 – Moteur de base (état, pièces, clients, stations, menu, service, sauvegarde, horloge)
- [ ] M2 – Scène jouable provisoire (placeholders, tap pour accélérer, HUD, améliorations)
- [ ] M3 – Labo de recettes (combinaisons, indices, livre de recettes, gestion du menu, ~30 recettes)
- [ ] M4 – Habitués (fréquences, demandes, affinité, carnet, histoires)
- [ ] M5 – Progression long terme (réputation, zones, hors ligne, demande du jour, séries)
- [ ] M6 – Simulateur d'équilibrage + premier rapport
- [ ] M7 – Monétisation derrière interfaces (mock pubs, StoreKit 2) + analytics
- [ ] M8 – Tutoriel + localisation FR/EN complète + réglages
- [ ] M9 – (à préciser)
