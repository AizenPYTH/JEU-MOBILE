# Mode Histoire — sauvegarde

## Fichiers (Application Support, écrits de façon atomique)

| Fichier | Contenu |
|---|---|
| `story-save.json` | la sauvegarde de l'histoire (`StorySave`, versionnée) |
| `story-investigation-in-progress.json` | l'affaire de l'histoire en cours dans le téléphone (`SaveSlot.story`) |
| `player_portrait.jpg` | ancien portrait 3D du joueur : plus écrit depuis le retrait de la 3D, effacé s'il existe |

Séparés d'ENQUÊTES / ALIBI (`investigation-in-progress.json`, tentatives de `ProgressStore`) : jouer un mode ne
remplace jamais la partie d'un autre. Exception voulue : une affaire d'ENQUÊTES jouée dans un chapitre (#001 au
chapitre 01) est enregistrée dans les tentatives d'ENQUÊTES, la carrière étant commune.

## Ce qui est sauvegardé

`StorySave` : version, joueur (nom, apparence — gardée pour le moteur, plus affichée —, accord, matricule), position (chapitre, étape, scène, plan, réplique
à l'écran, silence en cours, affaire attendue, écran de résultat / bureau), rang, déblocages, faits, relations,
affaires jouées (résolue, score, pièces, temps, ALIBI), chapitres terminés, résultat de la dernière affaire,
statistiques, scènes vues, réponses données, phrases de décision, historique daté, points du bureau ouverts,
relecture en cours, promotion en attente, date de création.

La sauvegarde est écrite **après chaque action** (réplique, choix, fin de plan, affaire finie, écran de résultat).

## Reprendre n'importe où

- En pleine scène : le directeur rejoue en silence les plans déjà joués (présents, accessoires montrés) et
  réaffiche la même réplique, ou la suite d'un silence. Aucune conséquence n'est appliquée deux fois.
- En pleine affaire : CONTINUER rouvre le téléphone au même écran, chrono en pause pendant l'absence.
- Sur les écrans de fin de chapitre ou du bureau : ils se rouvrent tels quels (la récompense n'est pas redonnée).
- Si la sauvegarde pointe vers un chapitre ou une scène qui n'existe plus : retour au hub, jamais d'écran vide.

## Versions et migrations (`StorySaveCoder`)

- v0 : brouillon des premiers prototypes (`chapter`, `scene`, `beat` à la racine, `progress.*`) → v1.
- v1 → v2 : accord et visage ajoutés au joueur (déduits de la base), accessoire supprimé, scènes vues, réponses,
  décisions, historique, points du bureau ; l'écran « reward » devient « result ».
- Une sauvegarde d'une version plus récente est refusée (`tooRecent`) sans être effacée ; un fichier illisible
  laisse l'histoire se recréer. Une apparence dont une variante n'existe plus est ajustée (`fitted`), jamais refusée.

Ajouter un champ : l'ajouter à `StorySave`, monter `currentVersion`, écrire `migrateNtoN+1` qui le remplit, et un
test de migration dans `StoryEngineTests` (voir `version1SavesAreMigrated`).

## Nouvelle partie / réinitialisation

Réglages › « Réinitialiser l'histoire » (maintien 1,6 s) supprime les trois fichiers ci-dessus et rien d'autre.
Les anciens réglages 3D (`story.quality`, `story.depthOfField`, `story.reduceCameraMotion`) ne sont plus lus ;
`StoryPreferences.reset()` (tests d'interface) les efface avec les autres réglages de l'histoire.
Les tests d'interface repartent d'une histoire vide avec `-UITestReset YES`.
