# Générateurs du mode Histoire

Les données de l'histoire (`ScreenshotKit/Sources/StoryLibrary/Resources/Story/`) sont écrites par ces scripts
(Python 3, sans dépendance). Modifier le script, puis le relancer ; `swift test` et `swift run CaseLint` vérifient
le résultat (références, grammaire des plans, cadrages).

| Script | Écrit | Lancer (depuis la racine du dépôt) |
|---|---|---|
| `gen_locations.py` | les 7 décors du BEN (ancres, caméras nommées, accessoires, points du bureau) | `python3 scripts/story/gen_locations.py ScreenshotKit/Sources/StoryLibrary/Resources/Story/locations.json` |
| `gen_campaign.py` | chapitres, étapes, carrière | `python3 scripts/story/gen_campaign.py …/Story/campaign.json` |
| `gen_chapter01.py` | scènes S01-01, S01-01B, S01-02, S01-03 | `python3 scripts/story/gen_chapter01.py …/Story/scenes/chapter_01.json` |
| `gen_chapter02.py` | scènes S02-01 à S02-04 (vérifie chaque chemin de réponses avant d'écrire) | `python3 scripts/story/gen_chapter02.py …/Story/scenes/chapter_02.json …/Story/locations.json` |
| `export_cinematic_prompts.py` | `docs/story/PROMPTS_CINEMATIQUES_HISTOIRE.md` : chaque scène en script de tournage (plans, répliques, réponses, sons) avec un prompt vidéo par plan | `python3 scripts/story/export_cinematic_prompts.py` |
| `fit_over_shoulder.py` | propose une position pour chaque caméra « par-dessus l'épaule » (épaule du joueur au bord du cadre) | `python3 scripts/story/fit_over_shoulder.py` |

`characters.json` et `npcs.json` s'éditent à la main (voir docs/story/CHARACTER_SYSTEM.md).

Cadrages : le test `ShippedStoryTests.shotsFrameTheirSubject` vérifie chaque plan à partir des caméras et des places
des personnes (sujet dans le cadre, personne contre l'objectif, CLOSE « épaules → tête », épaule au bord du cadre en
plan par-dessus l'épaule). Une caméra CLOSE (85 mm) se place à environ 1,9 m de sa cible.
