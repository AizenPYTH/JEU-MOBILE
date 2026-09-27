# Mode Histoire — scènes, décors, caméras

Référence : `docs/design_story/STORY_SCENES.md`, `ENVIRONMENTS.md`, `3D_DIRECTION.md`, `TRANSITIONS.md`, `DIALOGUE_UI.md`.

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

Une caméra : position, point visé, focale (28, 35, 50, 85 ou 100 mm ; le côté 36 mm du capteur est vertical, cadre
portrait). Mouvements : `pushIn` (≤ 12 cm) et `track` (travelling lent) ; avec « Réduire les animations » ou
« Réduire les mouvements de caméra », tout devient des coupes. Profondeur de champ sur les yeux de la personne du
plan ou sur l'objet (réglable).

Rendu (StageKit.swift) : quatre murs, faux plafond, plinthes, accessoires du kit BEN (bureaux bois/métal, chaises,
armoires, étagères, stores, radiateurs, cloisons vitrées, néons, fontaine, chariot, téléphone fixe, chemises, sachet
de scellé, carte BEN, boîtes d'archives, micro, voyant d'enregistrement, écran mural, tableau en liège, coffre…),
éclairage par préréglage (néon 4 000 K, lampe 2 700 K, sodium 2 100 K, salle d'audition 5 000 K), ombres douces
selon la qualité, étalonnage (saturation −15 %, vignettage). Le rouge n'est jamais une lumière, sauf le voyant.
Une seule pièce en mémoire : changer de décor décharge le précédent.

## Sons

Ambiances et bruitages générés (`scripts/audio/gen_story_sounds.py`) : ben_hvac, ben_office_night, ben_office_dawn,
ben_openspace, ben_archives, ben_interrogation ; steps_lino, door_glass, door_close, chair, drawer, page,
paper_slide, plastic_bag, neon_buzz, phone_distant, desk_phone_ring, keyboard, printer, coffee_machine. Un son absent
est ignoré (la scène se joue quand même). Voix : champ `voice` prêt, aucune voix enregistrée livrée.

## Assets encore nécessaires (à produire, voir docs/design_story/ASSET_MANIFEST.md)

Rien n'est inventé : tant qu'un asset manque, le rendu en formes simples le remplace.

- **P0** — modèles 3D : bases joueur F/M (USDZ riggé, 45 k tris, blendshapes ARKit), tenues OUTFIT_01–04 A/B,
  cheveux (12 coupes en cartes de cheveux), PNJ Lacaze + figurant ; décors ENV_BEN_CORRIDOR,
  ENV_BEN_OFFICE_LACAZE, ENV_BEN_OFFICE_PLAYER_L01 (lightmaps) ; kit BEN (~40 pièces) ; props carte BEN, sachet
  de scellé + téléphone (écran en texture de rendu), chemise kraft, chemise d'agent ; bibliothèque de 20 animations
  corporelles, 12 expressions, 6 poses de mains ; couloir flou précalculé du studio (STUDIO_PLAYER_BG).
- **P0** — 2D : tampons PNG `stamp_nouveau_*` et `stamp_classe_*` (même générateur que les tampons existants ;
  en attendant, `StateStamp` les dessine).
- **P0** — audio : voix de Lacaze pour le chapitre 01 (VO_LACAZE_C01, ~20 répliques), thème MUS_THEME_BEN.
- **P1** — bureaux du joueur L02–L04, open space, archives, salle d'audition, salle de réunion en modèles ; Inès,
  Aubrac, Colette ; objets de récompense ; thèmes tension / résolution ; voix des chapitres suivants.
- **P2** — décors extérieurs (rue, appartement, café, parking, métro, entrepôt), PNJ d'affaires pour l'audition.

Remplacer un rendu : charger le modèle dans `StageBuilder.prop` (par `kind`) ou `CharacterRig.make` (par variante)
au lieu des formes simples ; les données (ancres, caméras, identifiants) ne changent pas.
