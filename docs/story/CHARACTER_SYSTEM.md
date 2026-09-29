# Mode Histoire — personnages

Référence : `docs/design_story/CHARACTER_CUSTOMIZATION.md`, `NPC_DIRECTION.md` (noms, rôles, ton) ;
`docs/design_v4/` (rendu).

**Aucune 3D** (décision du porteur de projet) : ni personnage modélisé, ni apparence à choisir. Chaque personne est
une photo d'identité à **initiales** sur fond `photoBg` (jamais de portrait).

## Le joueur

Création en 2 étapes (h05) : **Identité** (modèle de départ, prénom, nom, accord des titres) puis **Confirmation** :
la carte BEN sur papier (photo à initiales, nom, rang « Enquêteur / Enquêtrice / Agent », matricule attribué à la
signature) et le maintien 1,2 s « Commencer ma carrière » ; le tampon « Identité confirmée » tombe sur la feuille.
Identifiants : `creator.template.{elise,vincent}`, `creator.firstName`, `creator.lastName`,
`creator.agreement.{f,m,n}`, `creator.next`, `creator.back`, `creator.confirm`.

- Modèles de départ : **Élise Morel** et **Vincent Delmas** (`templates`), préremplis et modifiables.
- Apparence : la sauvegarde garde toujours une apparence (celle du modèle de départ, ou `defaultAppearance`) ; le
  moteur l'exige et la migre, l'interface ne la montre plus et ne la modifie plus. Les variantes de
  `characters.json` restent (stables, jamais renommées) pour les sauvegardes existantes.
- Nom : 2 à 20 caractères (lettres accentuées, espace, apostrophe, tiret), majuscules automatiques, filtre local
  de grossièretés (FR + EN, mots entiers) et refus des noms complets des personnages du BEN.
  Post-it : « Nom non valide pour un dossier officiel. »
- Accord (féminin / masculin / neutre « Agent ») : les textes utilisent `{g:affecté|affectée|affecté·e}` et
  `{player.rank}`.
- Matricule `BEN-0xxxx`, tiré une fois à la création (nom + instant), jamais modifié.
- L'accord reste modifiable (Réglages › Accord). Nom : seulement en réinitialisant l'histoire.
- Plus de portrait : `player_portrait.jpg` n'est plus écrit (une ancienne copie est effacée par la réinitialisation).

## Évolution avec le rang (non achetable)

Le rang se lit sur les feuilles (tampon de rang sur la fiche d'enquêteur, « Avancement de service ») et dans le
bureau du joueur :

| Rang | Bureau |
|---|---|
| Enquêteur | OFFICE_01 |
| Inspecteur | OFFICE_02 |
| Inspecteur senior | OFFICE_03 |
| Expérimenté | OFFICE_04 |

## Les personnages du BEN (`npcs.json`)

| id | Nom | Rôle |
|---|---|---|
| lacaze | Cdt. Bernard Lacaze, 58 ans | commandant du BEN |
| ines | Inès Carvalho, 31 ans | analyste numérique |
| aubrac | Marc Aubrac, 49 ans | inspecteur senior |
| colette | Colette Vidal, 63 ans | archiviste |
| agent_a | Julien Roche | agent (figurant) |

À l'écran, un PNJ est son nom (Plex Mono) sous une photo d'identité à initiales dans le compte rendu de la scène.
Les champs `appearance`, `height`, `build`, `extras` restent dans `npcs.json` (validés) mais ne sont plus affichés.
