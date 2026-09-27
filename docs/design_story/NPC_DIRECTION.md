# NPC_DIRECTION.md — Personnages récurrents du BEN

**Source de vérité** pour l'apparence des personnages déjà définis : `phase2/05_PERSONNAGES.md` (fiches S4). Les modèles 3D doivent être **fidèles** à ces portraits.

## 1. Bible commune
- **Proportions** : réalistes, 7,5 têtes. Aucune exagération de silhouette (ni épaules, ni yeux, ni mains).
- **Peau** : même shader pour tous. Variations de teint par texture uniquement. Rides et imperfections dans la carte de normales, jamais peintes.
- **Âges** : variés et visibles (25–65 ans). Pas de personnages « lissés ».
- **Vêtements** :
  - tenues de travail réelles : chemises, pulls, vestes, parkas ;
  - palette : #2A2D31 anthracite, #3A4250 bleu nuit, #5A4F43 brun, #8A8A84 gris, #D9D4C8 écru, avec au plus une couleur sourde par personnage ;
  - pas de logos réels.
- **Expression au repos** : neutre et légèrement fatiguée. On sourit rarement au BEN.
- **Portrait (UI)** : toujours capturé avec la caméra S4 (CHARACTER_CUSTOMIZATION §5), pour que les portraits du Carnet et ceux des scènes soient identiques.
- **Interdit** : mélanger des styles. Pas de personnage stylisé cartoon ou anime, ni d'un niveau de détail très différent des autres.

## 2. Personnages récurrents (P0 et P1)

| ID | Identité | Rôle | Silhouette | Tenue | Palette | Expression | Utilisation |
|---|---|---|---|---|---|---|---|
| NPC_LACAZE | Cdt. Bernard Lacaze, 58 ans | Chef du BEN, supérieur du joueur | Grand, maigre, légèrement voûté | Chemise blanche aux manches retroussées, cravate desserrée, lunettes demi-lune | Blanc cassé, gris, marine | Fatiguée, vive, rare demi-sourire | Toutes les scènes de briefing et de retour. P0 |
| NPC_BEN_ANALYST | Inès Carvalho, 31 ans | Analyste numérique, alliée technique | Petite, épaules droites | Sweat gris, carte BEN en tour de cou, casque audio autour du cou | Gris, écru, un accent bordeaux | Concentrée, ironique | Explique les données du téléphone, scènes d'open space. P1 |
| NPC_BEN_SENIOR | Marc Aubrac, 49 ans | Inspecteur senior, rival bienveillant | Trapu | Veste en velours brun, col roulé | Brun, écru | Sceptique | Scènes de couloir et de réunion. P1 |
| NPC_BEN_ARCHIVIST | Colette Vidal, 63 ans | Archiviste | Menue | Cardigan, lunettes au bout d'une chaîne | Beige, gris | Bienveillante et lente | Salle des archives, donne des dossiers anciens. P1 |
| NPC_BEN_AGENT_A/B/C | Agents génériques, 30–50 ans | Figurants | 3 silhouettes | Chemise, polo, parka | Neutres | Occupés | Arrière-plans flous. P0 (A), P1 (B, C) |

**Personnages des affaires** (suspects, témoins) : ils apparaissent en 3D **uniquement** en salle d'interrogatoire, à partir du chapitre 03.
- Le modèle est dérivé d'une base PNJ secondaire, avec la tête sculptée d'après le portrait 05.
- Budget : 1 PNJ d'affaire en 3D par chapitre.

## 3. Voix (ElevenLabs)

| Personnage | Voix | Rythme | Notes |
|---|---|---|---|
| Lacaze | Masculine, 55–60 ans, grave, légèrement éraillée | Lent, phrases courtes | Parle sans élever la voix |
| Inès | Féminine, 30 ans, claire | Rapide | Vocabulaire technique simple |
| Aubrac | Masculine, 50 ans, ronde | Posé | — |
| Colette | Féminine, 60+ ans, douce | Lent | — |

**Mixage** : −16 LUFS pour les dialogues, ambiance à −30 dB. La voix du joueur n'est jamais enregistrée.

## 4. Nommage et variantes
- Nommage : `CHR_NPC_{NOM}_{A|B}`. B = variante de tenue, pour une scène de nuit ou un événement.
- Une seule variante B par personnage principal au maximum.
