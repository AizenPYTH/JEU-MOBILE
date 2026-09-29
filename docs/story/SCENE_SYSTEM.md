# Mode Histoire — scènes, décors, caméras

Référence : `docs/design_story/STORY_SCENES.md`, `ENVIRONMENTS.md`, `TRANSITIONS.md`, `DIALOGUE_UI.md` (textes,
rythme) ; `docs/design_v4/` (rendu).

## Présentation à l'écran : un compte rendu d'entretien (pas de 3D)

Décision du porteur de projet : les personnages et les décors 3D sont retirés. `StoryScenePlayer` présente la scène
en 2D sur le bureau (fond `deskLamp`) :

| Élément | Rendu |
|---|---|
| Lieu | bande de papier agrafée : « COMPTE RENDU D'ENTRETIEN » + `place` (Plex Mono, capitales) |
| Présents | `participants` en photos d'identité à initiales (fond `photoBg`) ; un PNJ apparaît quand il est placé / entre en scène (ou dès qu'il parle). Celui qui parle : pleine opacité + punaise rouge ; les autres à 55 % |
| Réplique | feuille de papier : nom en Plex Mono capitales (+ rôle à sa première réplique), texte en Newsreader 19–22 (taille des sous-titres), tapé à la vitesse choisie (instantané dans les tests) ; joueur en italique `ink2`, narrateur sans nom |
| Réponses | fiches de papier (inclinaison ≤ 1°), A / B / C en Plex Mono, silence en italique ; la réponse choisie reçoit un filet rouge |
| `wait` (silence, plan tenu) | la feuille affiche « … » ; la durée est celle des données, un toucher ne l'écourte pas |
| `title` | carton de papier sur le bureau assombri |
| `notification` | fiche de papier scotchée en haut (3 s) |
| `camera`, `place`, `enter`, `move`, `face`, `animate`, `show` / `hide` | rien à l'écran (le directeur les joue toujours ; ils ne bloquent pas) |
| `transition` fade | fondu vers le bois sombre |

Un toucher n'importe où complète la réplique puis passe à la suite ; appui long : JOURNAL. AUTO, PASSER et le
journal suivent les mêmes règles qu'avant (coordinateur). Identifiants de test : `story.scene`, `story.dialogue`,
`story.choice.<id>`, `story.hud.{journal,auto,skip}`, `story.journal`, `story.notification`.

## Une scène (scenes/chapter_NN.json)

```json
{ "id": "S01-01B", "title": "Bureau 312", "location": "ENV_BEN_OFFICE_LACAZE", "place": "BEN · BUREAU 312 · 21:06",
  "participants": ["player", "lacaze"],
  "beats": [
    {"kind": "place", "actor": "lacaze", "anchor": "lac_desk"},
    {"kind": "camera", "shot": {"kind": "wide", "camera": "cam_lac_door", "subject": "lacaze"}, "keyframe": true},
    {"kind": "wait", "seconds": 3, "silence": true},
    {"kind": "camera", "shot": {"kind": "medium", "camera": "cam_lac_ms", "subject": "lacaze"}},
    {"kind": "dialogue", "node": "l_close_door"}, …],
  "dialogue": [{"id": "l_close_door", "speaker": "lacaze", "text": "{player.lastName}. Fermez la porte."}, …] }
```

Plans (`beats`) : `place`, `enter`, `move`, `exit`, `face`, `animate`, `camera`, `dialogue`, `wait`, `sound`,
`ambience`, `transition` (cut / dissolve / fade), `effect`, `notification`, `title`, `show` / `hide` (un accessoire
caché apparaît : la chemise sortie du tiroir, le sachet de scellé, la carte BEN). `condition` sur un plan, une
réplique ou un choix (`flag`, `notFlag`, `lastCaseSolved`, confiance d'un PNJ).

Les scènes, décors et la campagne sont écrits par les générateurs de `scripts/story/` (voir son README).

**Règles vérifiées par le validateur** (tests + CaseLint) : une scène = un lieu ; 3 personnes au plus ; premier plan
WIDE ; jamais plus de 2 CLOSE d'affilée ; au moins un plan muet de 2 à 4 s ; uniquement des caméras nommées du
décor ; OBJECT FOCUS juste avant le téléphone ; transitions CUT / DISSOLVE / FADE seulement ; références (ancres,
accessoires, répliques, personnes, affaires, déblocages) toutes existantes ; aucune boucle de dialogue.

Répliques : `speaker` (`player`, un PNJ, `narrator`), `text` (3 lignes au plus à l'écran), `emotion`, `animation`,
`shot` (le plan de la réplique : la réaction en CLOSE…), `voice` (piste optionnelle, jamais requise : les sous-titres
sont toujours affichés), `choices`.

Choix : 2 ou 3 réponses + le silence optionnel (`silent: true`, texte « Ne rien dire », CLOSE du PNJ pendant `pause`
secondes). `remember` : la phrase de fin de chapitre (« VOS DÉCISIONS »). Pas de minuteur, pas d'indication de
conséquence.

## Décors (locations.json)

| id | Lieu | Caméras |
|---|---|---|
| ENV_BEN_CORRIDOR | couloir du 3ᵉ, 24 m, portes 301–318, un néon qui grésille | cam_corr_wide, cam_corr_follow, cam_corr_door312, cam_corr_hero (hub), cam_corr_cu |
| ENV_BEN_OFFICE_LACAZE | bureau 312 : lampe verte, stores, sodium de la rue | cam_lac_wide, cam_lac_door, cam_lac_ms, cam_lac_cu, cam_lac_os, cam_lac_rev, cam_lac_player_cu, cam_lac_desk_top |
| ENV_BEN_OFFICE_PLAYER | bureau du joueur, niveaux 1–4 | cam_po_wide (h09), cam_po_ms, cam_po_obj_{phone, computer, files, card, archives, rewards, board, safe} |
| ENV_BEN_OPENSPACE | open space, 16 postes | cam_os_wide, cam_os_ines, cam_os_ines_cu, cam_os_player, cam_os_aubrac, cam_os_desk_top |
| ENV_BEN_ARCHIVES | sous-sol, allées d'étagères | cam_arc_aisle, cam_arc_table, cam_arc_ms, cam_arc_cu, cam_arc_colette, cam_arc_box |
| ENV_BEN_INTERROGATION | salle d'audition, miroir sans tain, voyant rouge | cam_int_wide, cam_int_os_suspect, cam_int_cu, cam_int_mirror, cam_int_table |
| ENV_BEN_BRIEFING | salle de réunion, écran mural | cam_brf_wide, cam_brf_screen, cam_brf_ms |

Cadrages vérifiés par le test `shotsFrameTheirSubject` : sujet dans le cadre, personne contre l'objectif, CLOSE
« épaules → tête » (85 mm à ~1,9 m), épaule du joueur au bord du cadre en plan par-dessus l'épaule.

Une caméra (donnée seulement) : position, point visé, focale (28, 35, 50, 85 ou 100 mm), mouvements `pushIn` et
`track`. Les réglages « Qualité », « Profondeur de champ » et « Réduire les mouvements de caméra » ont été retirés
avec la 3D.

Ces décors, caméras et cadrages restent dans les données et sont vérifiés par le validateur et les tests du moteur
(les scènes gardent leur grammaire), mais **aucun n'est plus rendu** : le rendu SceneKit (StageKit, StoryStageView)
a été supprimé avec la 3D. Seul le bureau du joueur (`ENV_BEN_OFFICE_PLAYER`) sert encore à l'écran : ses
accessoires visibles au niveau courant (`level`, `maxLevel`, `requires`) avec `hotspot` — et les objets de
récompense — deviennent les fiches de « Mon bureau ».

## Sons

Ambiances et bruitages générés (`scripts/audio/gen_story_sounds.py`) : ben_hvac, ben_office_night, ben_office_dawn,
ben_openspace, ben_archives, ben_interrogation ; steps_lino, door_glass, door_close, chair, drawer, page,
paper_slide, plastic_bag, neon_buzz, phone_distant, desk_phone_ring, keyboard, printer, coffee_machine. Un son absent
est ignoré (la scène se joue quand même). Voix : champ `voice` prêt, aucune voix enregistrée livrée.

## Assets encore utiles

Aucun modèle 3D n'est plus attendu. Restent utiles :

- **2D** : tampons PNG « NOUVEAU » et « CLASSÉ » (même générateur que les tampons existants ; en attendant, ils
  sont dessinés en code) ; tampons de rang au féminin (« ENQUÊTRICE », « INSPECTRICE ») — sans eux, le rang accordé
  est dessiné en code.
- **Audio** : voix de Lacaze pour le chapitre 01 (VO_LACAZE_C01, ~20 répliques), thème MUS_THEME_BEN ; voix des
  chapitres suivants.
