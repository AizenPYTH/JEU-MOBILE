# Mode HISTOIRE — « Vivre la carrière de son enquêteur »

Troisième mode du jeu, à côté d'ENQUÊTES (résoudre des dossiers) et d'ALIBI (vérifier des déclarations).
Le joueur crée son enquêteur, entre au BEN (Bureau des Enquêtes Numériques) et vit sa carrière en chapitres :
des scènes courtes au BEN, lues comme des comptes rendus d'entretien posés sur le bureau, des affaires jouées dans
le téléphone (les écrans d'ENQUÊTES, inchangés), des retours au BEN, un bureau qui évolue avec le rang.

Sources de design (lecture seule) : `docs/design_story/` (handoff « Mode Histoire », écrans h01 à h19 : parcours,
textes, règles) et `docs/design_v4/` (rendu « Dossier lisible » : bureau en bois, chemises kraft, feuilles ivoire,
tampons).

## Présentation : papier, pas de 3D

Décision du porteur de projet : **plus de personnages ni de décors en 3D** (« c'est très moche, on laisse tomber
ça »). L'histoire, les chapitres, les scènes, les dialogues, les choix, la progression, la sauvegarde, les
récompenses et les règles ne changent pas (StoryEngine / StoryLibrary intacts) ; seule la présentation change :

- **Une scène** = un compte rendu d'entretien sur le bureau : une bande de papier avec le lieu et l'heure
  (« BEN · BUREAU 312 · 21:06 »), les personnes présentes en photos d'identité (initiales ; celle qui parle en pleine
  opacité avec une punaise rouge, les autres à 55 %), la réplique sur une feuille (nom en Plex Mono, texte en
  Newsreader, tapé à la vitesse choisie ; les répliques du joueur en italique), les réponses en fiches de papier.
  Cartons de titre, notifications et silences : des fiches de papier. Les plans de caméra ne montrent rien.
- **Le personnage** : un nom, un accord et une photo à initiales (aucun portrait, aucune apparence à choisir).
- **Mon bureau** : vu de dessus, les objets du niveau posés sur un sous-main (fiches, carte BEN, chemise…).
- Les champs de mise en scène 3D des données (ancres, caméras, gestes, décors, apparences) restent dans les
  fichiers et sont toujours validés, mais l'interface ne les lit plus.

## Parcours

```
Bureau (h01) ─ ENQUÊTES · ALIBI · HISTOIRE
  HISTOIRE, la première fois : création (h05, 2 étapes) → maintien « Commencer ma carrière » → scène 01-01
  HISTOIRE, ensuite : Hub (h04)
     CONTINUER → scène (compte rendu, h11/h12) → nouveau dossier (h15) → briefing → téléphone → rapport
               → retour au BEN (scène) → … → fin de chapitre (h16) → état de service (h17) → récompense (h18)
     MON ENQUÊTEUR (h07) · CARRIÈRE (h08) · MON BUREAU (h09) · chapitre (h10) · ⚙ réglages (h19)
```

- Le joueur ne parle qu'à travers ses choix (2 ou 3 réponses + le silence « Ne rien dire »). Les choix changent
  le ton et la mémoire des personnages, **jamais la solution d'une affaire**. Aucune jauge, aucun chiffre de
  relation n'est montré ; les phrases « VOS DÉCISIONS » apparaissent en fin de chapitre.
- Un chapitre n'est jamais bloquant : une affaire ratée donne la variante « non résolu » du chapitre et l'histoire
  continue.
- ENQUÊTES et ALIBI restent intacts et jouables à tout moment ; leur sauvegarde est séparée de celle de l'histoire.

## Chapitres

| # | Titre | État | Contenu |
|---|---|---|---|
| 01 | PREMIÈRE AFFECTATION | jouable | S01-01 couloir (arrivée, 21:04) → S01-01B bureau 312 (Lacaze, une question) → affaire #001 « Le dernier message » → S01-02 retour (carte BEN) → fin de chapitre → S01-03 « Mon bureau » → h09 |
| 02 | UNE AFFAIRE PLUS COMPLEXE | jouable | open space (Inès, Aubrac) → bureau 312 → affaire C02-A « Le dossier Varin » (propre à l'histoire) → débriefing → fin de chapitre → archives (Colette, le carton BEN-2019-114) |
| 03 | UNE ANOMALIE DANS UN ANCIEN DOSSIER | annoncé | — |
| 04 | UNE AFFAIRE QUI TOUCHE LE BEN | annoncé | — |
| 05 | CE QUE LE BEN N'A JAMAIS DIT | annoncé | — |

Un fil court de chapitre en chapitre : la signature de Thomas Bellec (« affaire classée BEN-2019-114 — témoin »)
dans l'affaire Varin ouvre le chapitre 03 ; aucune conspiration mondiale, une histoire administrative et humaine.

## Personnages

- Le joueur : créé en 2 étapes (identité : prénom, nom, accord des titres ; puis confirmation : la carte BEN,
  maintien 1,2 s). Élise Morel et Vincent Delmas sont les deux modèles de départ (préremplis, modifiables).
- Au BEN : Cdt. Bernard Lacaze (commandant), Inès Carvalho (analyste), Marc Aubrac (inspecteur senior), Colette Vidal
  (archiviste), un agent de l'open space.

## Où c'est dans le code

Voir `docs/story/ARCHITECTURE.md` (moteur, données, écrans), `CHARACTER_SYSTEM.md`, `SCENE_SYSTEM.md`,
`PROGRESSION.md`, `SAVE_SYSTEM.md`.
