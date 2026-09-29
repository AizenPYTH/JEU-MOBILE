# Mode Histoire — architecture

Trois couches, comme le reste du jeu : un moteur en Swift pur (testé sous Linux), des données JSON, une présentation
SwiftUI + SceneKit (iOS). La présentation ne contient aucune règle d'histoire.

```
ScreenshotKit/Sources/
  StoryEngine/                 Moteur (Foundation seulement, aucun import SwiftUI/SceneKit)
    Model/Character.swift      Apparence par variantes (slots), catalogue, modèles de départ, joueur, PNJ, accord
    Model/World.swift          Décors : ancres, caméras nommées (focale), accessoires, points du bureau (hotspots)
    Model/Scene.swift          Scènes : plans (beats), caméras, dialogues, choix (silence, remember), conditions, effets
    Model/Campaign.swift       Campagne : chapitres, étapes (scène / enquête / résultat / bureau), carrière, récompenses
    Engine/StoryDirector.swift Machine à états déterministe : joue les étapes, les plans, les répliques, les choix,
                               la carrière, la relecture d'un chapitre, « PASSER » ; met la sauvegarde à jour à chaque action
    Engine/StoryText.swift     {player.lastName}, {player.rank}, {g:masc|fem|neutre}…
    Engine/StoryValidator.swift Vérifie toutes les références et la grammaire des plans (tests + CaseLint)
    Save/StorySave.swift       Sauvegarde versionnée + migrations (v0 → v1 → v2)
  StoryLibrary/Resources/Story/  Données : characters.json, npcs.json, locations.json, campaign.json, scenes/*.json
  CaseLibrary/Resources/Cases/story_001.json   Affaire propre à l'histoire (mode "story", numéros 201–300)
  ScreenshotUI/Story/          Présentation iOS
    StoryCoordinator.swift     Possède le directeur et la sauvegarde ; événements → sons, transitions, écrans ;
                               réglages (StoryPreferences) ; portrait S4
    StageKit.swift             SceneKit : décors, lumières, accessoires, personnage (rig), caméras nommées, portrait
    StoryStageView.swift       Vue 3D déclarative (suit l'état du directeur) + aperçu du personnage (studio)
    StoryScenePlayer.swift     h11/h12 : sous-titres, choix, silence, HUD (JOURNAL · AUTO · PASSER), journal
    StoryOfficeView.swift      h09 : mon bureau (points interactifs)
    StoryEntryScreens.swift    h01 Bureau à 3 modes, h04 hub, h05/h06 création et studio
    StoryPaperScreens.swift    h07 profil, h08 carrière, h10 chapitre, h15 nouveau dossier, h16–h18, h19 réglages
    StoryRootView.swift        Aiguillage entre ces écrans
  ScreenshotUI/Theme/StoryDesign.swift  Jetons du handoff (couleurs, typographie, composants partagés)
```

`GameRoot` (Screens/RootView.swift) joue les affaires de l'histoire avec le moteur d'enquête existant, dans un
emplacement de sauvegarde à part (`SaveSlot.story`), puis rend la main au coordinateur (`caseFinished`).

## Principes

- **Déterministe** : même sauvegarde + mêmes choix = même scène. La reprise rejoue les plans déjà vus en silence
  (placement, caméra) sans réappliquer une conséquence.
- **Tout est donnée** : ajouter un chapitre, une scène, un PNJ, une tenue, un décor ne touche pas au moteur.
- **Jamais d'impasse** : une sauvegarde qui pointe vers un contenu disparu ramène au hub ; un décor ou une caméra
  manquant retombe sur la première caméra du décor ; un son manquant est ignoré.
- **Aucune vidéo** : les scènes sont jouées en 3D temps réel (SceneKit). Aucune scène n'attend ni ne lit de fichier
  vidéo ; le modèle n'a pas de champ pour en désigner un (les tests refusent une scène qui en déclarerait).

## Ajouter…

- **un chapitre** : une entrée dans `campaign.json` (`status: "playable"`, `steps`, `summary`, `summaryUnsolved`,
  `note`), ses scènes dans `scenes/chapter_NN.json`. Une étape `result` est obligatoire (fin de chapitre, carrière).
  Le chapitre suivant se débloque à la fin du précédent.
- **une scène** : voir SCENE_SYSTEM.md (plans, caméras, règles vérifiées par le validateur).
- **un PNJ** : `npcs.json` (id, nom, titre, rôle, apparence, taille, carrure, `extras` : lunettes, cravate…).
  Il peut alors être `participant` d'une scène et parler.
- **un dialogue / un choix** : `dialogue` de la scène ; un choix a `text`, `kind`, `effects`, `next`, et
  éventuellement `silent: true`, `remember` (phrase de fin de chapitre), `shot` (plan au moment de la réponse).
- **un décor** : `locations.json` (taille, couleurs, éclairage, ambiance, ancres, caméras `cam_*` à l'intérieur de la
  pièce, accessoires). Voir SCENE_SYSTEM.md.
- **une animation** : un nom dans les données (`animate`) + son geste dans `StoryStageView.pose(...)` ; un nom
  inconnu est ignoré.
- **une tenue** : deux variantes `outfit_NNa/b` (même `group`) dans `characters.json` ; `shape` choisit la
  silhouette (parka, coat, suit, leather…).
- **une récompense** : `reward.items` d'une étape `result` (id = déblocage, nom, provenance) + l'objet dans le
  bureau du joueur (`requires` = cet id, `hotspot` pour le rendre cliquable).

## Tests

- `Tests/StoryEngineTests/StoryEngineTests.swift` : personnage, textes, directeur (plans, choix, silence,
  mémoire, résultat, carrière, relecture, PASSER), sauvegarde (reprise partout, migrations), validateur.
- `ShippedStoryTests.swift` : le contenu livré est valide, chaque chapitre jouable se termine quels que soient les
  choix et les résultats, le chapitre 01 suit STORY_SCENES §5, le créateur offre les options du handoff.
- `ScreenshotUITests/MainFlowTests.testStoryFirstChapter` : premier lancement → création → scène → affaire →
  fin de chapitre → bureau ; reprise en pleine scène après avoir quitté l'app ; ENQUÊTES / ALIBI puis retour.
- `swift run CaseLint` affiche aussi un résumé de l'histoire (chapitres, scènes, durées estimées) et échoue si le
  validateur trouve un problème.
