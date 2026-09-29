# CONCLUDE : ENQUÊTES — HANDOFF V4 « Dossier lisible »

NOREL GAMES · 2026-09-29 · pour Claude Code.

- **Maquettes** : `CONCLUDE - Refonte V4 Dossier.dc.html`, écrans 01 à 10.
- **Base UX** : `redesign/HANDOFF_UX_V3.md`. La navigation, les flux, les états, l'onboarding, l'accessibilité et les données restent valides. Ce document **remplace uniquement la couche visuelle** de la V3 (tokens, composants, rendu des écrans).
- **Ne change pas** : les histoires, les mécaniques, le Carnet, la conclusion, le téléphone et les données.

## 1. Principe
**Le dossier physique devient l'interface, posé à plat et lisible.**

| Repris de la V3 | Repris des versions papier |
|---|---|
| Une intention par écran | Chemises kraft |
| Un seul bouton principal, en bas | Feuilles ivoire |
| « Verser au dossier » visible | Photos agrafées |
| Barre d'enquête permanente | Étiquettes de pièces, scellé |
| Carnet à 4 onglets avec compteurs | Fil rouge et punaises, tampons |
| Connexions en chaîne expliquée | Annotations manuscrites, bureau en bois sombre |

**Deux mondes**
- **Dossier** : kraft, papier, encre.
- **Téléphone** : réaliste, clair, en police système.

On passe de l'un à l'autre par le **scellé** (écran 03).

## 2. Tokens

### Couleurs

| Token | Hex | Usage |
|---|---|---|
| desk | #1A140F | Fond des écrans (bureau en bois sombre) |
| deskLamp | radial #3A2D20 → #1A140F → #0C0A08 | Fond du Bureau et du scellé (halo de lampe) |
| deskDeep | radial #2A2119 → #100D0A → #080706 | Accusation |
| bar | #110E0B | Barres du bas hors téléphone |
| kraft | #C3AC80 | Chemises, rebord d'enquête, étiquette Verser |
| kraftDark | #8C7456 | Fond de la planche des fils |
| kraftBoard | #3A2F24 | Fond de la planche des pièces |
| paper | #ECE5D3 | Feuilles de lecture |
| paperCard | #F4F0E6 / #F8F4EA | Fiches de pièce, fiches suspect |
| photoBorder | #FBF9F4 / #FFFFFF | Bord des tirages |
| photoBg | #6F7A86 | Fond des photos d'identité (et repli par initiales) |
| ink | #1C1A17 | Texte sur papier (13:1 sur paper) |
| ink2 | #5B5448 | Texte secondaire sur papier (≥ 5,5:1) |
| ivory | #EFEBE3 | Texte sur desk, bouton principal sur desk |
| ivory2 | #A9A397 / #C9C3B6 | Texte secondaire sur desk |
| red | #A3261E (sur papier) / #D0493C (sur desk) | Fil, punaise, tampons, mission, accusation, « contre » |
| green | #2E6B4A | « En faveur » |
| pen | #2B3A5A | Annotations manuscrites |
| staple | #8E8B84 | Agrafes, punaises neutres |
| tabs | #B9B2A1 · #AFA897 · #A59E8D · #9B9483 | Intercalaires inactifs du Carnet |
| Chemises des autres affaires | gris #9A9A94 · kraft clair #B8A57E · alibi #DCDFE2 | Pastilles du bas du Bureau |

**Téléphone** : inchangé depuis la V3 (#FFFFFF, #F6F6F8, bulles #2F6FE4 et #E9E9EB).

### Typographie
- **IBM Plex Sans** : tout texte d'interface et de lecture (body 15–16, callout 13–14, boutons 15–17/600).
- **Newsreader** : titres (28–36/500–600), noms de suspects (19–22/600), citations (19).
- **IBM Plex Mono** : numéros (DOSSIER #001, PIÈCE 03), heures, chrono, libellés courts en capitales (10–13/700, +8 à 12 %).
- **Caveat** : **uniquement** les notes du joueur, de Lacaze et le texte des fils (18–21/500, couleur pen). Jamais d'information indispensable.

### Textures
- `phase2/assets/textures/tex_paper_grain.png` : sur les feuilles, en multiply à 100 %.
- `phase2/assets/textures/tex_kraft_fibers.png` : sur les chemises, en multiply à 35–60 %.
- **Jamais** de texture sur un bouton ou sur un texte long.

### Formes
- Feuilles : rayon 0.
- Chemise : 0 0 12 12, avec des onglets de 8 8 0 0.
- Boutons : rayon 8–10, hauteur 56 (maintien 60).
- Étiquette Verser : 4 16 16 4.
- **Rotations ±1,5° maximum**, uniquement sur les tirages, les fiches de pièce et la fiche « Pièce versée ». Les feuilles de lecture, les boutons et le texte long ne sont jamais inclinés.

### Ombres

| Élément | Ombre |
|---|---|
| Chemise | 0 26 50 à 60 % |
| Fiche | 0 4–6 10–14 à 40–45 % |
| Tirage | 0 2–6 5–14 à 20–30 % |
| Modale | 0 24 50 à 55 % |

### Accessoires
- Agrafe : 22–30 × 8–10 pt, couleur staple.
- Scotch : 44 × 16 pt, rgba(235,225,190,0.8).
- Punaise : 12–14 pt.

### Tampons
PNG existants, en multiply :

| Tampon | Fichier |
|---|---|
| CONFIDENTIEL | `phase2/assets/stamps/stamp_confidentiel_rouge_marque.png` |
| ÉLÉMENT CLÉ | `stamp_element_cle_rouge_marque.png` |
| RÉSOLU / NON RÉSOLU | `stamp_resolu_…` / `stamp_non_resolu_…` |

« VERSÉE » et « OUVERT » sont rendus en code : filet 1,5–2,5 pt rouge, Plex Mono 700, rotation −8°.

## 3. Composants (anatomie V4, états identiques à la V3)

| Composant | Rendu V4 |
|---|---|
| **FolderTabs** (modes) | 3 onglets de classeur de 40 pt. Actif : kraft, texte ink/600, hauteur 40. Inactif : #3A332B, ivory2, hauteur 36, décalé de 4 pt vers le bas |
| **CaseFolder** (ex-CaseCard) | Chemise kraft de 358 × 420 pt dans le prolongement de l'onglet actif. Contenu : `DOSSIER #001` Mono 13/700 ; titre Newsreader 32/600 ; « Lieu · Type » 15/500 ; tirage de la victime 104 × 128 agrafé, avec légende Caveat ; tampon CONFIDENTIEL ; fiche paperCard à 3 métadonnées (Difficulté, Durée, Pièces) ; bouton ink « Ouvrir le dossier ». États : NOUVEAU (tampon CONFIDENTIEL) · EN COURS (bouton « Reprendre · 06:58 », pièces n/N) · RÉSOLU (tampon RÉSOLU à la place de CONFIDENTIEL) · VERROUILLÉ (pastille du bas à 55 %, condition au tap) |
| **FolderStub** | Chemises des affaires suivantes, 54 pt, au bas du Bureau : numéro Mono + titre |
| **CaseSheet** | Feuille paper insérée dans la chemise (marge de 10 pt). Filet ink de 1,5 pt sous l'en-tête. Mission encadrée d'un filet red de 1,5 pt. Section méthode séparée par un pointillé |
| **IdPhoto** | Tirage à bord photoBorder (3–6 pt, 10–16 pt en bas), fond photoBg, agrafe. Repli : initiales Plex Sans 600 #E4E7EA |
| **EvidenceSeal** (écran 03) | Sachet translucide rgba(220,225,230,0.18) + filet ivory à 28 %, étiquette paperCard « SCELLÉ N° 001-01 » red + propriétaire, téléphone éteint à l'intérieur (heure du dernier allumage) |
| **EvidenceTag** (Verser) | Étiquette kraft de 32 pt (zone tactile de 44) : œillet blanc de 8 pt + « Verser au dossier » Plex Sans 13/600 ink. L'élément sélectionné reçoit un filet kraft de 2 pt |
| **InvestigationRim** (ex-InvestigationBar) | Rebord kraft de 96 pt avec texture. Gauche : « ‹ Dossier #001 » ; centre : étiquette paperCard avec le chrono Mono 19/600 et « n pièces » ; droite : bouton ink « Carnet » |
| **EvidenceSlip** (écran 05) | Fiche paperCard, rotation −1,2°, scotch en haut. `PIÈCE nn` Mono 15/700 + « TYPE · date · heure ». Aperçu sur blanc avec filet. Note Caveat facultative (le joueur peut l'éditer). Tampon VERSÉE. Boutons [Relier] (contour ink) / [Continuer] (ink) |
| **NotebookDividers** | 4 intercalaires de couleurs tabs. Actif : paper, 44 pt de haut ; inactifs : 38 pt, décalés de 6 pt. Chacun porte un libellé 13/600 et un compteur Mono 10. Libellés : Suspects · Pièces · Chrono · Fils |
| **SuspectSheet** | Fiche paperCard sur page lignée (lignes rgba(52,66,84,0.12) tous les 28 pt). IdPhoto 78 × 98, nom Newsreader 19/600, âge Mono, relation, ALIBI, « ↑ n contre » red, « ↓ n pour » green, note Caveat |
| **EvidencePrint** | Tirage ou fiche 2 colonnes sur kraftBoard. Vignette de 86 pt (photo, texte du message sur blanc, carte), `PIÈCE nn`, type, ligne de liens (« ≠ contredit 05 » en red). Tampon ÉLÉMENT CLÉ une fois reliée à une contradiction |
| **RedThread** (connexions) | Planche kraftDark. Nœuds paperCard avec punaise red en haut, décalés latéralement de 0 à 40 pt en alternance. Fil red de 2 × 44 pt entre deux nœuds, avec le verbe en Caveat 20 ivory. Bouton « Tirer un nouveau fil » |
| **PinnedSuspect** (accusation) | Tirage de 176 pt de photo + nom 17/600 + relation, punaise en haut. Normal : rotation ±2°, opacité 100 %, punaise staple. Sélectionné : rotation 0°, −6 pt, filet red de 2 pt, punaise red ; les autres à 50 % |
| **ClosingReport** | Feuille paper : « RAPPORT DE CLÔTURE » + numéro, titre, tampon RÉSOLU à −9°, bloc RESPONSABLE (tirage + nom), explication, lignes de chiffres à pointillés, visa `signature_lacaze_bleu.png`, note en Newsreader 40/600 |
| **Boutons** | Principal sur desk : ivory avec texte ink. Principal sur papier ou kraft : ink avec texte ivory. Secondaire : contour ink de 1,5 pt. Maintien : fond #2A2522, remplissage red |

## 4. Écrans
Rendu décrit ici. Le comportement, les états et le test de compréhension sont ceux de la V3 : voir HANDOFF_UX_V3 §6.

| # | Écran | Rendu V4 | Correspondance V3 |
|---|---|---|---|
| 01 | Bureau | Fond deskLamp. Logo Mono + avatar. « Bonjour, {rang} {Nom} » en Newsreader 28 + « Un dossier vous attend sur le bureau. ». FolderTabs, CaseFolder, 3 FolderStubs, barre d'onglets | 01 |
| 02 | Dossier ouvert | Chemise kraft plein écran avec CaseSheet. Ordre : ‹ Bureau + OUVERT, en-tête, CONTEXTE, VOTRE MISSION (encadrée en rouge), PERSONNES ENTENDUES (4 IdPhotos), MÉTHODE (#001 uniquement). Pied bar : « Examiner le téléphone · Pièce 01 » + « n pièces versées » | 02 |
| 03 | Scellé (nouveau) | EvidenceSeal centré, « Retrouvé {lieu}, {heure} », mention du code si l'affaire en fournit un, bouton « Ouvrir le scellé ». Affiché 1 fois par affaire ; ensuite, « Examiner le téléphone » ouvre directement le téléphone | Transition 02 → 03 |
| 04 | Téléphone | Téléphone réaliste inchangé, EvidenceTag, InvestigationRim | 03 / 04 |
| 05 | Pièce versée | Voile desk à 55 %, EvidenceSlip | 05 |
| 06 | Carnet › Suspects | Fond desk, « ‹ Téléphone » + chrono sur étiquette, titre « Carnet d'enquête », NotebookDividers, page lignée avec des SuspectSheets | 06 |
| 07 | Carnet › Pièces | Planche kraftBoard, EvidencePrints en 2 colonnes | 07 |
| — | Carnet › Chrono | Page lignée : heure Mono 14 dans la marge gauche (filet red vertical de 1 pt à 56 pt, comme un cahier), texte Plex Sans 15, contradiction « ≠ contredit PIÈCE nn » en red avec point red. Non maquetté, dérivé de V3 08 | 08 |
| 08 | Carnet › Fils | Planche kraftDark, RedThread | 09 |
| 09 | Accusation | Fond deskDeep. « DOSSIER #001 · VÉRIFICATION FINALE » en red, « Qui est responsable ? » Newsreader 36, 4 PinnedSuspects, maintien de 1,6 s « Maintenir pour accuser {Prénom} » | 10 |
| — | Vérification | Feuille paper vierge au centre. « VÉRIFICATION DU DOSSIER… » tapé en Mono, les 3 lignes s'inscrivent comme à la machine (22 ms par caractère), puis le tampon RÉSOLU ou NON RÉSOLU tombe sur la feuille et le rapport glisse dessous | 11 |
| 10 | Rapport de clôture | ClosingReport + [Classer le dossier]. Échec : tampon NON RÉSOLU, bloc « RESPONSABLE : {vrai coupable} » + « Vous avez accusé : {X} », boutons [Rejouer] (ivory) / « Classer » (texte) | 12 |

**États vides (Carnet)** : même texte que la V3 §6, écrit en Caveat pen sur la page lignée, centré, avec un bouton ink si une action existe. Exemple : « Aucune pièce pour l'instant. Explorez le téléphone. »

**Erreur** : post-it #FBF3C8, rotation −1°, avec le titre, le texte et [Réessayer].

## 5. Animations (spring `paper` : réponse 0,42, amortissement 0,86)

| Déclencheur | Animation | Durée |
|---|---|---|
| Ouvrir le dossier | La couverture kraft pivote (rotateY 0 → −165°, axe gauche), la feuille monte de 12 pt | 450 ms |
| Ouvrir le scellé | L'étiquette se décolle (rotation 0 → 8°, opacité → 0), zoom sur l'écran du téléphone jusqu'au plein cadre, fondu enchaîné vers l'interface du téléphone | 900 ms |
| Élément touché | Filet kraft + EvidenceTag qui glisse de 4 pt | 150 ms |
| Pièce versée | EvidenceSlip qui tombe (échelle 1,06 → 1, rotation −3 → −1,2°) ; tampon VERSÉE (échelle 1,35 → 1, 180 ms) ; au Continuer, la fiche glisse vers Carnet (échelle → 0,2) ; le compteur passe en red pendant 1,5 s, halo red sur le bouton Carnet | 300 + 180 + 450 ms ; haptique success |
| Changer d'intercalaire | L'actif monte de 6 pt, la page glisse latéralement | 250 ms |
| Tirer un fil | Punaise posée (échelle 1,2 → 1) ; le fil se déroule de haut en bas ; la note s'écrit (masque de gauche à droite) | 120 + 300 + 400 ms ; haptique light |
| ÉLÉMENT CLÉ | Tampon sur la pièce, à la création d'une contradiction | 180 ms ; haptique rigid |
| Sélection de l'accusé | Redressement + élévation + punaise rouge | 260 ms |
| Verdict | Tampon RÉSOLU ou NON RÉSOLU | 180 ms + tassement de 60 ms ; haptique rigid |
| Classer | Le rapport glisse dans la chemise, la chemise se ferme et rejoint le Bureau avec son tampon | 600 ms |

**Réduire les animations** : fondus de 200 ms. Les tampons apparaissent sans chute, les fils sans déroulé.

## 6. Accessibilité (en plus de la V3 §9)
- Texte sur papier en ink ou ink2 uniquement, et jamais en Caveat pour une information nécessaire.
- Chaque note Caveat a son équivalent dans le libellé VoiceOver.
- Textures et rotations sont purement décoratives : masquées pour VoiceOver, et supprimées quand l'option Augmenter le contraste est active (papier uni, rotations à 0).
- « Contre » et « pour » gardent leurs flèches ↑ et ↓ en plus de la couleur.

## 7. Assets
- **Existants** :
  - textures, tampons, sceaux, signature ;
  - portraits prévus dans `phase2/05_PERSONNAGES.md` (placeholders gris-bleu en attendant).
- **Rendus en code** :
  - chemises, onglets et intercalaires ;
  - étiquettes, sachet, agrafes, scotch, punaises, fil ;
  - tampons VERSÉE et OUVERT.
- **À produire (optionnel)** :
  - `tex_desk_wood.jpg` : bois sombre en 2048 px, en remplacement du dégradé desk ;
  - `tex_ruled_page.png` : page lignée, sinon dégradé répété.

## 8. Ordre d'implémentation
1. Tokens V4 dans `TraceDesign.swift`, en gardant la structure des tokens V3.
2. InvestigationRim, EvidenceTag, EvidenceSlip.
3. NotebookDividers, SuspectSheet, EvidencePrint, RedThread.
4. CaseFolder, FolderTabs, CaseSheet, EvidenceSeal.
5. PinnedSuspect, vérification tapée, ClosingReport.
6. Re-skin des écrans Alibi, Histoire, Profil et Archives avec les mêmes composants.
7. Test sur #001 avec 5 nouveaux joueurs (critères de la V3 §11).
