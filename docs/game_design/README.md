# Difficulté et chemin de résolution des affaires

Retour des testeurs : « un peu trop difficile ». Règle appliquée : **difficulté intelligente = bonne, confusion =
mauvaise**. On a gardé le caractère enquête (le jeu ne donne jamais la réponse), et retiré la difficulté inutile :
indices clés cachés par la chance plutôt que par le raisonnement, objectifs vagues, preuves accessibles par un seul
chemin, textes que seule une image impossible pouvait montrer.

| Affaire | Difficulté ressentie avant → après (1–5) | Cible | Chemin minimal (pièces) | Temps pour voir l'essentiel* |
|---|---|---|---|---|
| #001 LE DERNIER MESSAGE | 3 → 1 | très accessible (tutoriel) | e_rdv, e_photo_meta, e_motive (3) | 101 s / 480 s |
| #002 PREMIER MÉTRO | 3 → 2 | accessible | e_fake_message, e_call, e_address, e_motive (4) | 96 s |
| #003 APRÈS LA FÊTE | 4 → 3 | intermédiaire | e_stairs_photo, e_yellow, e_not_in_bed, e_paul_awake (4) | 89 s |
| #004 90 SECONDES | 4 → 3 | intermédiaire | e_cue, e_key, e_swap_slot, e_insurance (4) | 79 s |
| #005 ROUTE DE NUIT | 4,5 → 3,5–4 | intermédiaire + | e_two_juliens, e_signature, e_4x4, e_same_car (4) | 141 s |

\* estimation de `CaseAnalysis.minimalPathSeconds` (coûts en temps + lecture), niveau Détective (8 min). Les tests
exigent que l'essentiel soit visible en moins de la moitié du temps, et que #001 demande le moins de pièces.

Ce qui a changé partout :

- **`minimalPath`** dans chaque affaire : le plus petit ensemble de preuves pour comprendre la solution (validé par
  `CaseValidator`, estimé par `CaseAnalysis`, affiché par CaseLint).
- **Indices en 3 plis** : 1 = OÙ REGARDER (gratuit), 2 = QUOI COMPARER (5 points), 3 = CE QUI CLOCHE, orientation forte
  sans nom (10 points). Aucun indice ne nomme le coupable (test `levelsAndHintsFollowTheRules`).
- **Preuves clés accessibles par plusieurs chemins** (`anyOf`) quand un seul chemin reposait sur la chance.
- **Carnet** : en tête des pièces, l'objectif (ou la déclaration en ALIBI) et la prochaine étape en une ligne
  (« dites ce que montre chaque pièce » → « x versées · y reliées » → « le dossier est solide : concluez »).
- **Difficulté affichée** sur les dossiers : #001 ●, #002 ●●, #003–#004 ●●●, #005 ●●●● (sur 5).
- **Photos** : chaque photo peut désormais être une vraie photographie ; les scènes qui montraient des personnages
  montrent le lieu ou l'objet, sans changer ce que la photo prouve.

Le détail par affaire (audit, chemin minimal : essentiels / secondaires / ambiance / fausses pistes / inutiles, liste
des changements, adaptations photo, risques) : `case_001.md` … `case_005.md`. Solutions, coupables et logique
centrale : inchangés.
