# Mode Histoire — progression

## Carrière (campaign.json › `career`)

Un rang demande **les deux** conditions : un nombre d'affaires résolues (tous modes : ENQUÊTES + affaires de
l'histoire, chacune comptée une fois ; une vérification ALIBI compte comme « traitée », jamais « résolue ») et un
chapitre terminé.

| Rang | Affaires résolues | Chapitre | Bureau |
|---|---|---|---|
| Enquêteur / Enquêtrice / Agent | 0 | — | OFFICE_01 |
| Inspecteur | 1 | 01 | OFFICE_02 |
| Inspecteur senior | 20 | 04 | OFFICE_03 |
| Expérimenté | 30 | 07 | OFFICE_04 |

Ces seuils remplacent, pour un joueur qui a créé son enquêteur, l'échelle 0 / 1 / 2–3 / 4–5 du mode ENQUÊTES
(pensée pour 5 affaires). Sans enquêteur créé, le mode ENQUÊTES garde son échelle (voir DESIGN_INTEGRATION.md).
Un rang ne descend jamais. Le rang atteint est gardé en attente (`save.promotion`) jusqu'à l'écran h17, suivi de
l'« Avancement de service ».

Un chapitre compte comme terminé dès son étape `result` (écrans h16 → h17 → h18) ; le chapitre suivant se
débloque au même moment. Ancienneté affichée : 3 mois de jeu par chapitre terminé.

## Déblocages

- Récompenses de fin de chapitre (`reward.items`) : des objets posés dans le bureau du joueur (jamais de monnaie,
  de pourcentage ni de bonus). Chapitre 01 : « Carte BEN » + ouverture de « Mon bureau » (`office_01`). Chapitre
  02 : le cadre du premier dossier résolu (`office_frame`).
- Bureau (h09) : niveau = rang (1 à 4). Les accessoires portent `level` / `maxLevel` / `requires` ; un objet non
  débloqué n'est pas visible du tout. « Mon bureau » est vu de dessus : chaque objet (TÉLÉPHONE, ORDINATEUR,
  DOSSIERS, CARTE BEN, puis ARCHIVES, RÉCOMPENSES, TABLEAU, COFFRE, et les objets de récompense) est une fiche posée
  sur le sous-main, avec une punaise rouge tant qu'elle n'a pas été ouverte ; un toucher ouvre sa feuille (nom,
  provenance). Étiquette « Niveau n / 4 ».
- Rang : tampon de rang sur la fiche d'enquêteur (PNG `stamp_<rang>_rouge` quand le mot imprimé est le titre
  affiché, sinon tampon dessiné avec le titre accordé).

## Relations

Confiance et respect par PNJ (−10…10), changés par les choix (`effects`), jamais montrés en chiffres. Les
dialogues les lisent (`condition` : `npc` + `atLeast`) ; l'état (« tendue », « réservée », « cordiale », « de
confiance ») est prévu pour la fiche de profil.

## Mémoire des choix

Chaque réponse est gardée (`save.choices`) : un chapitre rejoué montre la réponse donnée la première fois, et
« PASSER » (scène déjà vue) reprend les mêmes réponses. Les phrases `remember` s'affichent en fin de chapitre
(« VOS DÉCISIONS »). Les faits (`flag`) conditionnent les scènes suivantes.
