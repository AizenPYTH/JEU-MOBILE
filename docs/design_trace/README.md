# TRACE — DESIGN HANDOFF V2.0 · Direction « dossier d'enquête »

Refonte visuelle et UX de TRACE (anciennement SCREENSHOT V1.0). **Aucune modification de la logique de jeu** : ce document ne décrit que la présentation. Les données (affaires, suspects, pièces, chronologie, indices, score, difficultés) viennent du moteur existant, sans changement.

## 0. Fichiers

Les `.dc.html` sont des **maquettes HTML de référence**, haute fidélité, pas du code de production. Il faut les recréer dans la stack du projet (SwiftUI recommandé), en réutilisant ses composants et son architecture.

| Fichier | Contenu |
|---|---|
| `TRACE - 1 Bureau et Dossier.dc.html` | 01 remise de la pièce · 02 bureau (accueil) · 03 archives · 04 dossier ouvert · 05 téléphone · 06 verser au dossier · 07 suspects · 08 fiche suspect |
| `TRACE - 2 Enquete et Resolution.dc.html` | 09 pièces · 10 pièce détail · 11 carnet · 12 chronologie · 13 indices · 14 notifications · 15 vérification finale · 16 vérification en cours · 17 résolu · 18 non résolu · 19 rapport · 20 profil · 21 vide · 22 confirmation |
| `TRACE - Charte.dc.html` | couleurs, typos, matières, tampons, boutons, espacements, ombres, icônes, photo, document, transitions |
| `TraceStatus.dc.html` | barre d'état avec l'étiquette chrono (3 niveaux) |

Les textes affichés dans les maquettes sont indicatifs : l'implémentation lit les données du moteur. Les catégories, dates et détails des dossiers 002 à 005 dans les maquettes (AGRESSION, DÉCÈS SUSPECT, VOL, etc.) sont des **exemples à remplacer** par les vraies données. Seuls le titre, le lieu et le numéro sont garantis.

---

## 1. Concept : papier dehors, verre dedans

| Matière | Ce qui la porte | Rendu |
|---|---|---|
| **Bureau** | fond de tous les écrans hors téléphone | noir charbon + halo de lampe radial en haut |
| **Papier** | tout ce qui appartient à l'enquêteur : dossiers, fiches, pièces, carnet, indices, formulaires, rapport, chrono, notes de service, confirmations | ivoire / kraft, ombres portées, objets (agrafes, ruban, trombones, tampons) |
| **Verre** | le téléphone saisi, et lui seul | OS moderne réaliste (icônes couleur, verre dépoli, Geist), inventé pour TRACE, sans reprendre iOS |

Signature : dans le téléphone, **deux éléments papier seulement** restent visibles. L'étiquette du chrono (en haut à gauche, légèrement inclinée) et l'onglet kraft du carnet (en bas, au centre). Le joueur « tient la pièce à conviction » tout en gardant son dossier.

Règle d'auteur des marques : **le jeu n'annote jamais à la place du joueur.** Le jeu pose seulement les tampons administratifs (RÉSOLU, NON RÉSOLU, CONFIDENTIEL, SCELLÉ, NOUVEAU) et le texte manuscrit des états vides et de l'appréciation finale. Tout le reste (ÉLÉMENT CLÉ, ALIBI À VÉRIFIER, DISCULPÉ, entourages, annotations, barrés) est une action du joueur.

## 2. Vocabulaire (à appliquer dans toute l'app)

| Ancien (V1) | TRACE V2 |
|---|---|
| Affaire (liste) | Dossier |
| Épingler | Verser au dossier |
| Preuve épinglée | Pièce N° nn |
| Lier à un suspect | L'accuse / Le disculpe |
| Accuser | Vérification finale → Clore le dossier |
| Affaire résolue / non résolue | Dossier résolu / non résolu |
| Score | Rapport de clôture · Note finale |
| Profil | Enquêteur (carte d'enquêteur, état de service) |
| Dossiers terminés | Archives |
| Accueil | Bureau (Bureau des enquêtes) |
| Indice | Indice (enveloppe) · Note du superviseur |
| Notification de jeu | Note de service |
| Verrouillée | Scellé |

Autres termes utilisés : Victime, Témoin, Témoignage, Alibi (déclaré), Chronologie, Dernière apparition, Dernier contact, Hypothèse, Responsable (désigné / identifié), Élément clé, Confidentiel, Consulter la solution, Rouvrir le dossier.

## 3. Tokens

```text
colors
  desk            #121110   desk.light #1F1D1A (radial 130% 60% at 50% 0)
  graphite        #2A2825
  paper           #ECE5D3   paper.aged #E3DAC4   print #F4F0E6   notebook #EFE9DA   note.yellow #FBF3C8
  kraft           #C3AC80   variantes #B8A077 #C9B387 #BEA67B   kraft.sealed #8E7D5C
  kraft.ink       #2B2519   kraft.label #5A4C33
  ink             #1C1A17   ink.soft #5B5448   ink.faint #8A8174 (désactivé uniquement)
  bone            #EFEBE3   bone.2 #A9A397   bone.3 #6F6A61       (texte sur bureau)
  stamp           #A3261E   stamp.onDark #D0493C   stamp.deep #3A1512 (piste du hold)   stamp.text #F2E9E4
  pen             #2E3A57   (encre bleue des écrits du joueur)
  metal           #9A978F
  tape            rgba(226,214,180,.8)
  ruled           rgba(28,26,23,.06–.07) tous les 28 · notebook rgba(60,80,120,.13) tous les 30
  margin.red      rgba(163,38,30,.45)
typography
  Newsreader (opsz)  400/500/600/italic  → titres, noms, prose, citations
  IBM Plex Mono      400–700             → champs, numéros, heures, tampons, boutons papier
  Geist              300–600             → navigation, texte UI, tout le téléphone
  Caveat             500                 → annotations seulement
  styles : voir §4
spacing   2 4 6 8 10 12 14 16 18 20 24 32 48 · feuille : padding 18–22, retrait bord écran 8–10
radius    paper 0–3 · folder tab 8 8 0 0 · folder body 0 10 10 10 · button 6 · id card 12 · chip 16 · sheet 4 4 0 0
shadows   paper.rest 0 8 20 rgba(0,0,0,.40)
          paper.lifted 0 18 40 rgba(0,0,0,.45) , 0 2 4 rgba(0,0,0,.30)
          folder 0 22 44 rgba(0,0,0,.55) , inset 0 1 0 rgba(255,255,255,.25)
          slip 0 20 44 rgba(0,0,0,.65)
          stack 0 -6 14 rgba(0,0,0,.35)
          print 0 10 18 rgba(0,0,0,.45)
opacity   stamp .75–.90 · suspect non choisi .50 · scrim .55–.60 · téléphone sous carnet −40 %
animation fast 140–200 · base 260–360 · slow 420–700 · typing 40 ms/char · hold 1200 ms
          standard (.32,.72,0,1) · emphasized (.2,.8,.2,1) · dramatic (.65,0,.35,1) · stamp (.5,0,.75,0)
          spring tab 300/30 · sheet 260/32
```

## 4. Typographie

| Style | Police | Taille/interligne | Poids | Casse / interlettrage |
|---|---|---|---|---|
| wordmark | Plex Mono | 19–30 | 700 | TRACE, +42 % · sous-titre 9–11, +26 % |
| case.title | Newsreader | 30–34/1.02 | 600 | −1 % |
| screen.title (bureau) | Newsreader | 32–36 | 500 | −2 % |
| name | Newsreader | 17–24 | 600 | |
| prose | Newsreader | 16/1.45 | 400 | |
| quote | Newsreader italique | 16–22/1.3 | 400 | guillemets français « » |
| field.label | Plex Mono | 9–10 | 500 | CAPS, +16 % |
| field.value | Plex Mono | 11–13 | 600 | CAPS |
| piece.number | Plex Mono | 10 (vignette) / 18–22 (titre) | 700 | « PIÈCE 04 » |
| stamp | Plex Mono | 9–44 | 700 | CAPS, +12 à +22 % |
| button.paper | Plex Mono | 12–13 | 600–700 | CAPS, +12 à +14 % |
| ui / body | Geist | 13–16/1.45 | 400–600 | |
| annotation | Caveat | 18–25/1.05 | 500 | rotation −3 à +2° |

Minimum : 9 pt uniquement pour les libellés mono en capitales. Le texte courant est à 13 pt au moins. Dynamic Type : Geist et Newsreader suivent la taille système. Les tampons et les champs mono montent jusqu'à +2 crans, puis se figent.

## 5. Component inventory

| Composant | Variantes / états | Spéc |
|---|---|---|
| `DeskBackground` | normal · lampe (radial) | §3 |
| `TraceStatus` | clock · timer normal / low (≤ 01:00, contour rouge + point plein) / critical (≤ 00:10, étiquette rouge) | étiquette 24 h, rotation −2°, point trou 6 pt |
| `TabBar` | Bureau · Archives · Enquêteur | Geist 11, h 84, fond #0E0D0C |
| `FolderCard` (dossier à plat) | ouvert · nouveau · résolu | onglet N° + chemise kraft + feuille dépassante + tirage photo scotché + tampon + grille de champs + CTA encre |
| `FolderTab` (tiroir) | résolu · non résolu · nouveau · scellé | h 52–60, superposition −6, badge à droite |
| `ArchiveCard` (fiche bristol) | ouvert (liseré rouge 4 + barre) · nouveau (CTA) · résolu (tampon + note) · non résolu (tampon pointillé + note manuscrite du joueur) · sans faute (double tampon) · scellé (kraft foncé + ruban) | colonne numéro 52 |
| `DifficultyMeter` | 1–5 | carrés 8–9 pleins/contour + « n/5 » |
| `DividerTabs` (intercalaires) | actif (couleur feuille, h 30) · inactif (h 26, tons dégradés) | Plex 10, défilement horizontal |
| `CaseSheet` | fiche d'affaire | agrafes, en-tête, champs, photo, résumé, annotation |
| `EvidenceBag` | scellé · ouvert | sachet translucide + bande SCELLÉ + étiquette |
| `EvidenceCTA` (pièce 01) | non démarré · en cours (chrono) | bouton encre h 60 avec icône téléphone |
| `PhoneShell` | — | OS réaliste + `TraceStatus` + `CarnetTab` |
| `CarnetTab` | n pièces · +1 (compteur rouge 1,5 s) · tiré | 250 × 92, kraft, r 10 10 0 0 |
| `DepositSlip` (bordereau Verser) | — | papier scotché, N° de pièce, 4 lignes de 46 |
| `SuspectIndexCard` | défaut · principal (contour rouge) · disculpé (barré + tampon encre) | photo 70 × 84 bord blanc 3 |
| `SuspectFile` | p. 1/2 | papier réglé, trombone, champs, ALIBI, CONTRE/EN FAVEUR (cases ✕), témoignages, annotation, tampon joueur |
| `EvidenceItem` | photo · message · appel · localisation · reçu · note · document · mail | support propre à chaque type, pied « PIÈCE nn · TYPE · HH:MM », rotation stable (hash de l'id → −2..+2°) |
| `KeyMark` | ÉLÉMENT CLÉ | tampon 9–10 pt, posé par le joueur |
| `EvidenceDetail` | — | tirage posé + fiche : source/date/heure, L'accuse / Le disculpe (chips), annotation, « Voir dans le téléphone » |
| `Notebook` | connexions · chronologie · indices · vide | lignes bleues, marge rouge, élastique, pages empilées |
| `ConnectionBlock` | l'accuse (rouge) · le disculpe (bleu) | nom serif + libellé manuscrit + `EvidenceLabel` collés |
| `EvidenceLabel` | — | mini-étiquette mono 10, papier #F7F3E8, rotation ±2° |
| `Hypothesis` | vide · rempli | champ libre, rendu en Caveat bleu |
| `TimelineSheet` | fait versé (carré plein) · fait connu (carré vide) · surligné · trou (pointillés) · DERNIÈRE APPARITION | axe 1,5 px, heures mono à gauche |
| `HintEnvelope` | ouverte (note superviseur) · scellée cire (coût) · scellée ruban (heure de déblocage) | kraft, rabat triangulaire |
| `ServiceNote` | info · erreur (liseré rouge) | papier scotché, en haut |
| `ConfirmLabel` | — | étiquette 34 h « PIÈCE 07 VERSÉE AU DOSSIER » |
| `ClosureForm` (vérification finale) | — | responsable (4 portraits, entouré), motif, pièces retenues, disculpés, hypothèse, signature |
| `HoldToClose` | repos · remplissage · validé · annulé | 1 200 ms, piste #3A1512, remplissage #A3261E |
| `VerificationTypewriter` | — | lignes mono avec verdict, curseur ▍ |
| `ClosedFolder` | RÉSOLU · NON RÉSOLU | chemise fermée + gros tampon |
| `DebriefSlip` | — | note agrafée : disculpé + alibi + piège + pièces non versées par app |
| `ClosureReport` | résolu · sans faute · non classé (solution consultée) | lignes de champs, note finale 72 pt, tampon, appréciation manuscrite |
| `InvestigatorCard` | — | carte plastifiée, bande encre, photo, grade, matricule, progression |
| `ServiceRecord` / `MentionStamp` | obtenue · cachée (pointillés) | |
| `EmptyPage` | carnet · pièces · archives · recherche | page du support + phrase + conseil manuscrit + CTA contour |
| `ConfirmSheet` | destructif · neutre | formulaire papier avec bord perforé, 2 boutons en bas |
| Objets : `Staple`, `Tape`, `Paperclip`, `PhotoPrint`, `Stamp` | — | Charte §03–04. Trombone et masque de grain d'encre = assets à produire |

## 6. Arbre des écrans (inchangé fonctionnellement, renommé)

```
Cinématique → [01] Remise de la pièce → [04] Dossier ouvert
Bureau [02]
├─ Dossier ouvert (à plat) → Reprendre → [05] Téléphone
├─ Tiroir → Dossier [04] (intercalaires : Contexte · Suspects [07] → Fiche [08] · Pièces [09] → Détail [10] · Chronologie [12] · Rapport)
├─ Archives [03] → Dossier / Rapport de clôture [19]
└─ Enquêteur [20] → Réglages
Téléphone [05] (apps V1, inchangées) ⟶ appui long → Bordereau [06]
  ├─ onglet Carnet → Carnet [11] (Connexions · Chronologie [12] · Indices [13])
  └─ notifications : verre (téléphone) / note de service (enquête) [14]
00:00 ou « Passer à l'accusation » → Vérification finale [15] → hold → Vérification [16]
  → Résolu [17] → Reconstitution (V1 n° 33, avec la présentation papier) → Rapport [19]
  → Non résolu [18] → Rouvrir | Consulter la solution → Confirmation [22]
```

## 7. Spécification des écrans

Chaque maquette porte une note grise qui fait partie de la spécification. Voici les points importants.

- **01 Remise.** C'est le dernier plan figé de la cinématique. Sachet scellé incliné à −3°, étiquette « PIÈCE À CONVICTION N° 001-01 » avec le lieu, et une annotation manuscrite du service. Le CTA « Recevoir le dossier » mène à 04. Le chrono ne tourne pas encore.
- **02 Bureau.** Le wordmark, puis « DOSSIER OUVERT » (le dossier en cours, ou à défaut le prochain disponible) posé à plat : tirage photo scotché qui dépasse de la chemise, tampon CONFIDENTIEL, puis la grille ÉTAT / DIFFICULTÉ / PIÈCES VERSÉES / OUVERT LE, et le CTA avec le temps restant. En dessous, « AUTRES DOSSIERS » en tiroir : onglets superposés avec numéro, titre, lieu et badge d'état. Un dossier scellé porte un ruban rouge.
- **03 Archives.** Chips de filtre en Geist, fiches bristol. Chaque état est reconnaissable sans la couleur : liseré + barre, tampon plein, tampon pointillé, ruban, CTA.
- **04 Dossier ouvert.** Chemise kraft en plein écran, bord à 8 pt du bord de l'écran. Intercalaires en haut, feuille agrafée. Champs VICTIME, TYPE, LIEU, DERNIER CONTACT, STATUT. Photo d'identité scotchée, résumé en serif. En bas, le CTA collant « PIÈCE 01 · OUVRIR LE TÉLÉPHONE » avec la durée.
- **05 Téléphone.** Voir §1. Le contenu des apps reprend les écrans 08 à 21 de la V1, mais avec des icônes d'OS couleur et des bulles colorées (bleu pour les messages envoyés). Le chrono de la V1 et la capsule Carnet sont remplacés par `TraceStatus` et `CarnetTab`.
- **06 Bordereau.** Remplace le menu contextuel « Épingler » de la V1. Même geste (appui long de 400 ms), mêmes actions.
- **07/08 Suspects.** Fiches bristol. La fiche détaillée est une page réglée avec ALIBI DÉCLARÉ (déclaration fournie par le moteur), CONTRE / EN FAVEUR (pièces liées par le joueur, avec leur numéro), TÉMOIGNAGES, annotations et tampon.
- **09/10 Pièces.** Grille à 2 colonnes, un support par type (tableau §5). Numérotation séquentielle dans l'ordre de versement, avec un numéro stable pour la partie.
- **11 Carnet.** Onglets Connexions / Chronologie / Indices. En bas, le CTA rouge « Passer à l'accusation ». Glisser une étiquette de pièce sur un autre suspect crée le lien.
- **12 Chronologie.** Générée à partir des horodatages des pièces et des faits connus. Surlignages et annotations viennent du joueur.
- **13 Indices.** Ce sont les 3 paliers existants du moteur. Coût et heure de déblocage affichés sur l'enveloppe.
- **14 Notifications.** Deux familles : verre (événements du téléphone, niveaux V1) et papier (événements d'enquête : note de service, étiquette de confirmation).
- **15–16 Vérification.** Formulaire de clôture, hold de 1 200 ms, puis 2,4 s de frappe. Le résultat n'apparaît qu'en 17 ou 18.
- **17/18 Clôture.** Tampon plein ou pointillé. La note de 18 reprend les données V1 : alibi du suspect accusé, piège, pièces manquées par app.
- **19 Rapport.** Mêmes données de score que la V1 : suspect, temps restant, éléments trouvés, indices, précision. La note est calculée par le moteur. Appréciation manuscrite : modèle de texte choisi selon la pièce la plus importante manquée.
- **20 Enquêteur.** Carte, état de service (4 lignes), mentions.
- **21/22.** États vides et confirmations (gabarits réutilisables).

Chargement : « Consultation des archives… » en mono + filet fin (affiché si > 150 ms). Erreur système : `ServiceNote` avec liseré rouge + « Réessayer », et le chrono en pause.

## 8. Transitions, son et haptique

Tableau complet : Charte §11. Sons et haptiques à ajouter à ceux de la V1 :

| Moment | Son | Haptique |
|---|---|---|
| Sachet posé sur le bureau | sac plastique + objet sur bois | soft |
| Ouvrir une chemise | frottement de carton | light |
| Changer d'intercalaire | feuille | selection |
| Verser une pièce | tampon sec | medium |
| Tampon RÉSOLU / NON RÉSOLU | tampon lourd | heavy / warning |
| Frappe (vérification, rapport) | machine à écrire très bas (−24 dB) | — |
| Ouvrir une enveloppe | papier déchiré court | light |
| Hold de clôture | montée grave | continu 0.2 → 0.8 puis heavy |

## 9. Implémentation (Claude Code)

1. **Ne pas toucher** au moteur, aux modèles de données ni aux règles de score. Brancher les nouvelles vues sur les modèles existants (affaire, suspects, pièces / éléments épinglés, liens suspect-pièce, chronologie, indices, résultat, score, progression du joueur).
2. Créer un module `TraceDesign` : tokens (§3), `Font.trace.*`, ViewModifiers `.paper()`, `.kraft()`, `.lifted()`, `.stamp(kind:)`, `.handwritten()`, `.tilt(seed:)` (rotation déterministe dérivée de l'id).
3. **Deux thèmes coexistent** : `TraceDesign` pour tout ce qui est hors téléphone, et le thème OS du téléphone (Geist, couleurs système du téléphone fictif) pour l'intérieur de `PhoneShell`. Aucune valeur ne passe de l'un à l'autre, sauf `TraceStatus` et `CarnetTab`.
4. Textures : grain papier en PNG 512² (bruit monochrome 3 %, blend multiply), masque d'encre pour les tampons ≥ 22 pt, trombone en SVG. En attendant les assets, les maquettes sont déjà valables en aplats.
5. Mapping du vocabulaire (§2) : dans les fichiers de localisation uniquement.
6. Épingler = `deposit(ref)` → le numéro de pièce est l'index de versement + 1, figé ensuite. Les tampons joueur (ÉLÉMENT CLÉ, ALIBI À VÉRIFIER, DISCULPÉ) et les annotations sont un **état de présentation** à stocker à côté de l'état de partie existant (clé = id de pièce ou de suspect). Ils n'influencent pas le score, sauf si le moteur utilise déjà « disculpé » ou « lien ».
7. Accessibilité : chaque tampon est lu par VoiceOver (« tampon : résolu »), les annotations Caveat ont une alternative texte, et un réglage « Écriture manuscrite lisible » remplace Caveat par Newsreader italique. Contraste : ink/paper 14:1, ink.soft/paper 6.2:1, stamp/paper 6.4:1, bone.2/desk 7.4:1. Réduire les animations : voir la Charte.
8. Recette : comparer chaque écran à sa maquette numérotée (01–22) et à la charte.

## 10. Screen inventory

01 Remise de la pièce · 02 Bureau · 03 Archives · 04 Dossier ouvert · 05 Téléphone · 06 Verser au dossier · 07 Suspects · 08 Fiche suspect · 09 Pièces · 10 Pièce détail · 11 Carnet · 12 Chronologie · 13 Indices · 14 Notifications · 15 Vérification finale · 16 Vérification en cours · 17 Dossier résolu · 18 Dossier non résolu · 19 Rapport de clôture · 20 Enquêteur · 21 État vide · 22 Confirmation.

Repris de la V1 (contenu identique, habillage téléphone V2) : toutes les apps du téléphone, la recherche, l'appel entrant et les réglages.

## 11. User flow

```
Cinématique → Pièce remise → Dossier (contexte) → Pièce 01 → Téléphone
  ⟲ explorer → appui long → Verser (pièce nn) → L'accuse / Le disculpe
  ⟲ Carnet (connexions, chronologie, indices)
→ 00:00 | Passer à l'accusation → Vérification finale → maintenir → Vérification…
→ RÉSOLU → Reconstitution → Rapport de clôture → Rejouer | Dossier suivant
→ NON RÉSOLU → Note de débrief → Rouvrir | Consulter la solution (confirmation)
Bureau ⇄ Archives ⇄ Enquêteur
```
