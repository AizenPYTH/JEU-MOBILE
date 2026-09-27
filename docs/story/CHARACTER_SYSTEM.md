# Mode Histoire — personnages

Référence : `docs/design_story/CHARACTER_CUSTOMIZATION.md`, `NPC_DIRECTION.md`.

## Le joueur

Création en 4 étapes (h05) : **Identité** (prénom, nom, base FÉMININE / MASCULINE, accord), **Apparence** (teint,
visage, cheveux coupe + couleur, yeux, pilosité pour la base masculine), **Tenue** (4 tenues × 2 couleurs),
**Confirmation** (maintien 1,2 s « Commencer ma carrière »).

- Nombre fini de combinaisons, aucune génération : 2 bases × 6 teints × 6 visages × 6 coupes (par base) ×
  6 couleurs × 6 yeux × 8 tenues (+ 4 pilosités pour la base masculine).
- Variantes stables (`skin_01`, `face_03`, `hair_f02`, `hair_m05`, `haircolor_04`, `eyes_06`, `outfit_02b`…) dans
  `StoryLibrary/Resources/Story/characters.json` : une sauvegarde ne contient que ces identifiants. On peut en
  ajouter, jamais en renommer.
- Modèles de départ : **Élise Morel** et **Vincent Delmas** (`templates`), préremplis et modifiables.
- Nom : 2 à 20 caractères (lettres accentuées, espace, apostrophe, tiret), majuscules automatiques, filtre local
  de grossièretés (FR + EN, mots entiers) et refus des noms complets des personnages du BEN.
  Post-it : « Nom non valide pour un dossier officiel. »
- Accord (féminin / masculin / neutre « Agent ») : les textes utilisent `{g:affecté|affectée|affecté·e}` et
  `{player.rank}`.
- Matricule `BEN-0xxxx`, tiré une fois à la création (nom + instant), jamais modifié.
- Apparence et tenue modifiables à tout moment (Réglages › Modifier l'apparence) : le portrait est ré-imprimé et
  l'historique reçoit « Photo de dossier mise à jour ». Nom et base : seulement en réinitialisant l'histoire.
- Portrait : capture du buste 3D en caméra « S4 » (85 mm, 1,55 m, fond #6F7A86), `player_portrait.jpg` dans
  Application Support, régénéré à chaque changement d'apparence.

## Évolution avec le rang (non achetable)

| Rang | Sur le personnage | Bureau |
|---|---|---|
| Enquêteur | carte BEN plastique à la ceinture | OFFICE_01 |
| Inspecteur | carte métal ; écharpe (manteaux) ou gants (autres tenues) | OFFICE_02 |
| Inspecteur senior | porte-document en cuir | OFFICE_03 |
| Expérimenté | insigne de revers | OFFICE_04 |

## Les personnages du BEN (`npcs.json`)

| id | Nom | Rôle | Silhouette |
|---|---|---|---|
| lacaze | Cdt. Bernard Lacaze, 58 ans | commandant du BEN | grand (1,88 m), maigre ; chemise blanche, cravate desserrée, lunettes demi-lune |
| ines | Inès Carvalho, 31 ans | analyste numérique | petite ; sweat gris, carte en tour de cou, casque |
| aubrac | Marc Aubrac, 49 ans | inspecteur senior | trapu ; veste en velours, col roulé |
| colette | Colette Vidal, 63 ans | archiviste | menue ; cardigan, lunettes à chaînette |
| agent_a | Julien Roche | agent (figurant) | polo |

Leurs vêtements sont des variantes `npcOnly` (jamais proposées au joueur) ; `height`, `build` et `extras`
règlent la silhouette. Les suspects des affaires n'apparaissent pas en 3D avant le chapitre 03 (salle d'audition).

## Rendu actuel et modèles à venir

Le personnage est construit en formes simples (réalisme stylisé, matériaux mats, proportions réalistes) par
`CharacterRig` (StageKit.swift) : pièces nommées `body`, `torso`, `head`, `arm_l`, `arm_r`, `legs` que les gestes
animent. Des modèles USDZ riggés (PLAYER_BASE_FEMALE/MALE, NPC_LACAZE…, voir ASSET_MANIFEST) peuvent le remplacer
sans toucher aux données : même taille, pivot au sol, face à +Z, mêmes noms de pièces ou un squelette dont les
animations portent les noms de la bibliothèque (`nod`, `read`, `handover`…).
