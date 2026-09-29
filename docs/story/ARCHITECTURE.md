# Mode Histoire — architecture

Trois couches, comme le reste du jeu : un moteur en Swift pur (testé sous Linux), des données JSON, une présentation
SwiftUI en 2D (iOS, rendu V4 « Dossier lisible » : docs/design_v4). La présentation ne contient aucune règle
d'histoire. **Aucune 3D** (décision du porteur de projet) : SceneKit n'est plus utilisé nulle part.

```
ScreenshotKit/Sources/
  StoryEngine/                 Moteur (Foundation seulement, aucun import SwiftUI/UIKit)
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
                               réglages (StoryPreferences) ; lieu et personnes présentes de la scène
    StoryScenePlayer.swift     h11/h12 : le compte rendu d'entretien (lieu, présents, réplique, réponses, silence,
                               cartons, notifications), HUD (JOURNAL · AUTO · PASSER), journal
    StoryOfficeView.swift      h09 : mon bureau vu de dessus (objets en fiches, feuille de l'objet)
    StoryEntryScreens.swift    h04 hub (chemise d'agent), h05 création (identité → carte BEN)
    StoryPaperScreens.swift    h07 profil, h08 carrière, h10 chapitre, h15 nouveau dossier, h16–h18, h19 réglages
    StoryRootView.swift        Aiguillage entre ces écrans
  ScreenshotUI/Theme/StoryDesign.swift  Jetons de l'histoire sur la palette V4 (papier, encre, kraft, bureau) et
                               composants partagés (étiquettes, tampons de rang, maintien, pied d'écran)
```

`GameRoot` (Screens/RootView.swift) joue les affaires de l'histoire avec le moteur d'enquête existant, dans un
emplacement de sauvegarde à part (`SaveSlot.story`), puis rend la main au coordinateur (`caseFinished`).

## Principes

- **Déterministe** : même sauvegarde + mêmes choix = même scène. La reprise rejoue les plans déjà vus en silence
  (placement, caméra) sans réappliquer une conséquence.
- **Tout est donnée** : ajouter un chapitre, une scène, un PNJ, une tenue, un décor ne touche pas au moteur.
- **Jamais d'impasse** : une sauvegarde qui pointe vers un contenu disparu ramène au hub ; un son manquant est ignoré.
- **Aucune vidéo, aucune 3D** : une scène est présentée en 2D, comme un compte rendu d'entretien sur le bureau.
  Aucune scène n'attend ni ne lit de fichier vidéo ; le modèle n'a pas de champ pour en désigner un (les tests
  refusent une scène qui en déclarerait). Les champs de mise en scène (ancres, caméras, gestes, décors, apparences)
  restent dans les données et sont validés, mais l'interface ne les lit plus.

## Ajouter…

- **un chapitre** : une entrée dans `campaign.json` (`status: "playable"`, `steps`, `summary`, `summaryUnsolved`,
  `note`), ses scènes dans `scenes/chapter_NN.json`. Une étape `result` est obligatoire (fin de chapitre, carrière).
  Le chapitre suivant se débloque à la fin du précédent.
- **une scène** : voir SCENE_SYSTEM.md (plans, caméras, règles vérifiées par le validateur).
- **un PNJ** : `npcs.json` (id, nom, titre, rôle ; apparence, taille, carrure et `extras` restent exigés par le
  validateur mais ne sont plus affichés). Il peut alors être `participant` d'une scène et parler : il apparaît dans
  le compte rendu en photo d'identité à initiales, avec son nom.
- **un dialogue / un choix** : `dialogue` de la scène ; un choix a `text`, `kind`, `effects`, `next`, et
  éventuellement `silent: true`, `remember` (phrase de fin de chapitre), `shot` (plan au moment de la réponse).
- **un décor** : `locations.json` (taille, couleurs, éclairage, ambiance, ancres, caméras `cam_*` à l'intérieur de la
  pièce, accessoires). Voir SCENE_SYSTEM.md.
- **une animation, une caméra, une tenue** : ces champs restent possibles dans les données (le validateur les
  vérifie), mais ne se voient plus à l'écran. Une scène se lit par ses répliques, ses silences (`wait`), ses cartons
  (`title`) et ses notifications.
- **une récompense** : `reward.items` d'une étape `result` (id = déblocage, nom, provenance) + l'objet dans le
  bureau du joueur (`requires` = cet id). Dans « Mon bureau », un objet avec `hotspot` a sa fiche ; un objet de
  récompense sans `hotspot` y figure aussi, avec le nom et la provenance de la récompense.

## Tests

- `Tests/StoryEngineTests/StoryEngineTests.swift` : personnage, textes, directeur (plans, choix, silence,
  mémoire, résultat, carrière, relecture, PASSER), sauvegarde (reprise partout, migrations), validateur.
- `ShippedStoryTests.swift` : le contenu livré est valide, chaque chapitre jouable se termine quels que soient les
  choix et les résultats, le chapitre 01 suit STORY_SCENES §5, le créateur offre les options du handoff.
- `ScreenshotUITests/MainFlowTests.testStoryFirstChapter` : premier lancement → création (identité, puis carte BEN)
  → scène → affaire →
  fin de chapitre → bureau ; reprise en pleine scène après avoir quitté l'app ; ENQUÊTES / ALIBI puis retour.
- `swift run CaseLint` affiche aussi un résumé de l'histoire (chapitres, scènes, durées estimées) et échoue si le
  validateur trouve un problème.
