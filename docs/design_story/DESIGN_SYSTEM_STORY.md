# DESIGN_SYSTEM_STORY.md — CONCLUDE : ENQUÊTES · Mode Histoire

NOREL GAMES · V1.0 · 2026-09-27

**Maquettes de référence** : `CONCLUDE - Mode Histoire.dc.html`. Les écrans y sont numérotés h01 à h19.

**Hérite de** `final/FINAL_DESIGN_HANDOFF_CONCLUDE.md` §G : tokens, boutons, tampons et textures existants. Ce document liste **uniquement** les ajouts et les règles propres aux trois modes.

⚠ **Nom** : le brief écrit « CONCLUE ». Le logo et tous les livrables précédents disent **CONCLUDE : ENQUÊTES**. Conformément à la règle « ne pas changer le nom », on conserve CONCLUDE.

## 1. Hiérarchie des modes

| Mode | Promesse (une ligne) | Verbes | Matière | Couleur de chemise | Encre | Indice visuel |
|---|---|---|---|---|---|---|
| ENQUÊTES | Résoudre des dossiers | EXPLORER · VERSER · CONCLURE | Kraft | #C3AC80 | #2B2519 | Photo agrafée |
| ALIBI | Vérifier des déclarations | VÉRIFIER · CROISER · CONCLURE | Papier gris | #DCDFE2 | #1F2530 | Deux horaires, l'écart en rouge |
| HISTOIRE | Vivre la carrière de son enquêteur | CARRIÈRE · CHAPITRES · BUREAU | Carte BEN | #2A3240 → #333D4C | #E4E7EA | Portrait sur carte, barre de chapitre |

**Règles communes**
- Les trois entrées ont la même forme : une chemise à onglet, avec le même rayon (0 10 10 10) et la même ombre.
- Elles se distinguent uniquement par la matière et par l'indice visuel.
- On ne crée jamais une couleur d'accent propre à un mode : le rouge #A3261E (sur papier) et #D0493C (sur sombre) restent communs.

## 2. Couleurs ajoutées

| Token | Valeur | Usage |
|---|---|---|
| `alibi.paper` | #DCDFE2 | Fiche de déclaration, chemise ALIBI |
| `alibi.ink` | #1F2530 | Texte sur `alibi.paper` |
| `alibi.inkSecondary` | #4A5260 | Métadonnées ALIBI |
| `story.folder` | #2A3240 | Chemise de chapitre, carte HISTOIRE |
| `story.folderLight` | #333D4C | Haut du dégradé de la carte HISTOIRE (dégradé à 160°, le seul autorisé) |
| `story.ink` | #E4E7EA | Texte sur `story.folder` |
| `story.inkSecondary` | #9AA3AE | Kicker sur `story.folder` |
| `scene.void` | #0A0B0D | Fond sous les rendus 3D (letterbox, bas des voiles) |
| `scene.scrim` | rgba(10,9,8,0.82 → 0.94) | Voile du sous-titre de dialogue |
| `render.bg` | radial #2A313B → #12151A → #0A0B0D | Fond du studio du personnage 3D |

**Fonds de Bureau par mode**, tous en dégradé radial à 90 % × 45 % :

| Mode | Dégradé |
|---|---|
| ENQUÊTES | #3A2D20 → #15110D → #0B0A09 (lampe chaude) |
| ALIBI | #1D2229 → #101215 → #0A0A0B (néon froid) |
| HISTOIRE | #20252D → #101215 → #0A0A0B |
| Bureau principal | #2E261D → #12100E → #0A0908 |

Aucun autre dégradé n'est autorisé.

## 3. Typographie (échelle unique, toutes interfaces)

| Rôle | Police | Taille/graisse | Interlettrage | Couleur type | Usage |
|---|---|---|---|---|---|
| H1 | Newsreader | 30/500 | −0,01 em | #EFEBE3 | Titre d'écran (Bureau, Carrière) |
| H1-hero | Newsreader | 34/500 | −0,01 em | #EFEBE3 | Nom du joueur, écran h04 uniquement |
| H2 | Newsreader | 24–28/600 | 0 | Encre du support | Nom sur fiche, titre de dossier |
| H3 | Newsreader | 20–21/500–600 | 0 | — | Titre de chapitre ou de carte |
| LABEL | Plex Mono | 10/700 | +16 % | #A9A397 / #5B5448 | Kickers, onglets, capitales |
| BODY | Newsreader | 15–16/400, interligne 1,45 | 0 | #C9C3B6 / #3A3631 | Résumés, textes de dossier |
| UI-BODY | Geist | 15/400 | 0 | #EFEBE3 | Lignes de réglages, liens |
| CAPTION | Geist | 13/400, interligne 1,5 | 0 | #A9A397 | Aides, sous-textes |
| TECHNICAL | Plex Mono | 11/500 | +2 % | — | Matricules, heures, coordonnées |
| STAMP | PNG (`phase2/assets/stamps`) ; repli Plex Mono 18/700 | +16 % | — | #A3261E | Cachet |
| DIALOGUE | Newsreader | 22/400, interligne 1,35 | 0 | #EFEBE3 | Réplique en cours |
| DIALOGUE-NAME | Plex Mono | 11/700 | +18 % | #EFEBE3 | Nom du locuteur |
| DIALOGUE-ROLE | Plex Mono | 10/400 | +10 % | #A9A397 | Fonction du locuteur |
| CHOICE | Newsreader | 16/400 ; silence en italique #A9A397 | 0 | #EFEBE3 | Réponses |
| NOTE | Caveat | 21/500 | 0 | #2B3A5A (papier) / #9AA3AE (sombre) | Annotation manuscrite. Maximum 1 par écran |
| BUTTON | Plex Mono | 13/700, capitales | +16 % | — | Boutons |

**Dynamic Type**
- Les rôles en Newsreader et Geist suivent la taille système jusqu'à xxxLarge. LABEL, TECHNICAL et BUTTON restent fixes (10 pt minimum).
- En AX1 et au-delà :
  - DIALOGUE plafonne à 30 pt, et le voile du sous-titre monte jusqu'à 55 % de l'écran ;
  - les grilles de choix restent en 1 colonne ;
  - les fiches papier défilent.

## 4. Espacements, rayons, ombres
- **Espacements** : 4 · 8 · 10 · 12 · 14 · 16 · 20 · 24 · 28 · 44 (zone tactile) · 48 (ligne de liste) · 56 (bouton).
- **Marges** : 16 pt pour les feuilles, 24 pt pour les boutons, 28 pt pour les textes posés sur un rendu 3D.
- **Rayons** : feuille 0 · chemise 0 10 10 10 · bouton 6 · pilule HUD 16 · sheet 16 en haut · ligne de réglages 10.
- **Ombres** :

| Élément | Ombre |
|---|---|
| Feuille | 0 18 40 à 55 % |
| Chemise | 0 20–30 40–60 à 60–65 % |
| Tirage | 0 4 10 à 25 % |
| Objet 3D (2D factice) | 0 30 60 à 70 % |

## 5. Composants nouveaux

| Composant | Spécification |
|---|---|
| `ModeFolder` | Chemise à onglet de 358 pt de large, hauteur 118 à 156 pt. Props : `mode`, `title`, `verbs`, `meta`, `accessory` (photo / horaires / portrait + progression). Tap sur toute la surface. |
| `StoryHeroRender` | Rendu 3D en haut d'écran, 470 pt de haut. Voile dégradé vers `scene.void` sur les 200 pt du bas. |
| `ChapterFolder` | Chemise `story.folder` avec feuille intérieure, marge 14 pt. Liste de scènes : lignes de 44 pt, statut ✓ / ● / ○, type en LABEL. |
| `DialogueLine` | Voir DIALOGUE_UI.md. |
| `ChoiceRow` | 52 pt de haut au minimum, rayon 6. Principal : filet de 1,5 pt #EFEBE3. Secondaire : filet de 1 pt à 25 %. Silence : filet à 15 %, texte en italique. |
| `EvidenceChip` | Papier, vignette 44 pt, « MONTRER UNE PIÈCE ». |
| `CareerTimeline` | Voir STORY_UX_FLOW §h08. |
| `HotspotDot` | Point #EFEBE3 de 12 pt, halo de 5 pt à 18 %, étiquette Mono 10 sur rgba(10,9,8,0.7). Zone tactile de 44 pt. |
| `LevelTag` | Étiquette papier : « OFFICE_0N » ou « NIVEAU n / 4 ». |
| `ProgressBoxes` | Cases de 1,5 pt de filet, cochées d'un « × » en #A3261E Plex Mono 18/700. Une case par affaire requise. |
| `RewardObject` | Objet 3D isolé, rotation de 8 s par tour, ombre au sol. |
| `SettingsGroup` | En-tête LABEL + bloc #1A1816 à rayon 10, lignes de 48 pt. |
| `CharacterOptionSwatch` | Rond de 44 pt minimum. Sélection : anneau #ECE5D3 de 2 pt + anneau encre de 2 pt. |
| `StepBar` | 4 segments de 2 pt de haut, espacés de 6 pt. Faits : #EFEBE3 ; à venir : à 18 %. |

## 6. Système de dossiers (types × états)

**Types**

| Type | Support | Rayon | Usage |
|---|---|---|---|
| CHAPITRE | Chemise #2A3240, feuille #ECE5D3 | 0 8 8 8 | Mode Histoire |
| AFFAIRE | Chemise kraft #C3AC80 | 0 8 8 8 | ENQUÊTES, et affaires jouées dans un chapitre |
| DOCUMENT | Feuille #ECE5D3 | 0 | Note de service, lettre, briefing |
| PIÈCE | Fiche #F4F0E6 | 2 | Carnet |
| RAPPORT | Feuille #E6DFCC | 0 | Clôture |

**États** (cachet rotation −7°, filet de 2 pt, Plex Mono 9/700)

| État | Cachet | Traitement |
|---|---|---|
| NOUVEAU | Rouge | Normal |
| EN COURS | Encre | Ajout d'un temps restant ou d'une scène n / N |
| RÉSOLU | Rouge | Normal |
| CLASSÉ | Gris #5B5448 | Support à 60 % d'opacité |
| CONFIDENTIEL | Rouge | Normal |
| VERROUILLÉ (hors grille) | — | Support à 50 %, condition écrite, aucun cachet |

- Sur `story.folder`, les cachets encre et gris passent en #E4E7EA, et les cachets rouges en #D0493C.
- Cachets PNG à produire : `stamp_nouveau_*` et `stamp_classe_*` (ASSET_MANIFEST).

## 7. Boutons (rappel + ajouts)
- **Un seul bouton plein par écran.** Sur fond sombre, #EFEBE3 ; sur papier, #1C1A17.
- **Boutons secondaires en contour.** Sur le hub Histoire (h04) : grille de 3 × 48 pt.
- **Maintien** : réservé à trois moments :
  - conclure (ENQUÊTES / ALIBI) ;
  - commencer ma carrière (h05b) ;
  - réinitialiser l'histoire (h19).
- **Destructif** : texte #D0493C dans une ligne de réglages, puis confirmation par maintien.

## 8. HUD de scène
- Pilules de 32 pt de haut (zone tactile de 44 pt), fond rgba(10,9,8,0.55), Plex Mono 10 à +10 %.
- JOURNAL · AUTO · (PASSER, uniquement pour une scène déjà vue), en haut à droite, sous la safe area.
- Aucun autre élément d'interface pendant une scène.

## 9. Accessibilité (propre au mode Histoire)
- **Contraste** : tout texte posé sur un rendu 3D passe par `scene.scrim`, avec un ratio ≥ 4,5:1 garanti par le voile. Aucun texte directement sur le rendu.
- **VoiceOver** :
  - la réplique est annoncée « Bernard Lacaze, commandant : Delmas. Fermez la porte. » ;
  - les choix forment une liste, le silence est annoncé « Ne rien dire » ;
  - les points du bureau se lisent comme des boutons.
- **Réduire les animations** : caméras fixes (voir TRANSITIONS.md), fondus de 200 ms.
- **Sous-titres toujours affichés.** La voix est optionnelle (Réglages).
