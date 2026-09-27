# STORY_UX_FLOW.md — Architecture, parcours, spécification des écrans

**Maquettes** : `CONCLUDE - Mode Histoire.dc.html`, écrans h01 à h19. **Tokens** : DESIGN_SYSTEM_STORY.md.

## 1. Architecture

```
Lancement (final/ §C inchangé pour le 1er lancement ENQUÊTES)
Bureau principal (h01) ─ barre : BUREAU · ARCHIVES · ENQUÊTEUR
 ├─ ENQUÊTES (h02) → briefing → téléphone → Carnet → conclusion → rapport   [existant]
 ├─ ALIBI (h03) → affirmation → traces → croisement → verdict              [existant]
 └─ HISTOIRE
     ├─ (pas encore de personnage) Création h05 : Identité → Apparence → Tenue (h06) → Confirmation (h05b)
     │     → Scène 01-01 (première affectation)
     └─ Hub Histoire (h04)
          ├─ CONTINUER → prochaine étape du chapitre en cours
          │     SCÈNE (h11/h12) ⇄ TÉLÉPHONE (transition h13) ⇄ retour BEN (h14)
          │     … → Résultat de chapitre (h16) → Progression (h17) → [Avancement 06] → Récompense (h18)
          ├─ MON ENQUÊTEUR → Profil (h07) → Voir en 3D (h06, lecture)
          ├─ CARRIÈRE → h08
          ├─ MON BUREAU → h09
          ├─ Chapitres (tap sur « CHAPITRE 02 ») → h10
          └─ ⚙ Paramètres histoire (h19)
```

**Identité joueur, décision de fusion**
- Le personnage créé en HISTOIRE **devient** l'enquêteur du jeu entier : Profil, Bureau, dossiers « AFFECTÉ À ».
- Élise Morel et Vincent Delmas (docs 05 et 06) deviennent les deux **modèles de départ** de la création, préremplis à l'étape Identité et modifiables.
- Un joueur qui n'ouvre jamais HISTOIRE garde le modèle choisi à « Qui enquête ? ».
- Le rang, les affaires résolues et l'ancienneté sont **communs** aux trois modes.
- Les ALIBI comptent dans « affaires traitées », pas dans « résolues ».

## 2. Parcours du joueur

**P1 · Première entrée en Histoire**
Bureau → carte HISTOIRE (« Créer votre enquêteur ») → h05 (4 étapes, environ 90 s) → maintien → cachet → fondu au noir → scène 01-01.

**P2 · Boucle d'un chapitre**
h04 CONTINUER → scène 3D (1 à 3 min) → dossier remis (h15) → briefing → téléphone (affaire standard ENQUÊTES ou ALIBI) → rapport → retour BEN (h14) → scène → … → h16 → h17 → h18 → h04.

**P3 · Consultation**
h04 → Profil / Carrière / Bureau. Lecture seule, retour par ‹.

**P4 · Reprise**
- En pleine scène : reprise au dernier plan-clé (voir STORY_SCENES §4).
- En pleine affaire : reprise dans le téléphone, chrono en pause.

## 3. Spécification des écrans

Gabarit commun : 390 × 844 pt, safe areas iOS, un seul bouton plein, bouton à `safeArea.bottom` + 10 pt, retour « ‹ » de 44 × 44 pt à gauche (et geste de bord).

### h01 · Bureau principal
- **Objectif** : choisir un mode en moins de 3 s.
- **Contenu**, de haut en bas :
  - mention texte CONCLUDE / ENQUÊTES (règle logo §H du final) et pastille portrait de 44 pt, qui ouvre le Profil ;
  - H1 « Bureau » et la ligne `{I}. {NOM} · {RANG} · BEN` ;
  - 3 `ModeFolder` espacés de 26 pt, onglets compris.
- **Ordre des chemises** : le mode en cours passe en premier ; par défaut ENQUÊTES, ALIBI, HISTOIRE.
- **Contenu de chaque chemise** :

| Mode | Titre | Verbes | Méta | Accessoire |
|---|---|---|---|---|
| ENQUÊTES | « Résoudre des dossiers » | EXPLORER · VERSER · CONCLURE | « #00N EN COURS · n NOUVEAUX » | Tirage agrafé de l'affaire en cours |
| ALIBI | « Vérifier des déclarations » | VÉRIFIER · CROISER · CONCLURE | « 3 MIN · n ALIBIS » | Colonne DÉCLARÉ / TRACÉ de l'alibi suivant, écart en rouge |
| HISTOIRE | « Chapitre N · Titre » | CARRIÈRE · CHAPITRES · BUREAU | — | Portrait (capture 3D) + barre de progression du chapitre |

- **Interaction** : tap sur une chemise → push vers l'écran du mode (la chemise s'ouvre, voir TRANSITIONS T-UI-1).
- **États** :
  - **HISTOIRE sans personnage** : titre « Créer votre enquêteur », méta « NOUVEAU MODE », portrait remplacé par un tirage vide.
  - **ALIBI verrouillé** jusqu'à la fin de #001 : chemise à 50 %, « Disponible après le dossier #001 ».
  - **HISTOIRE verrouillé** jusqu'à la fin de #001 (recommandation) : même traitement.
  - **Chargement** : chemises vides, sans texte.
- **Animation d'entrée** : les chemises montent de 24 pt en fondu, décalées de 70 ms.

### h02 · Sélection ENQUÊTES
- Écran existant (final/ écran 13) : grande chemise pour l'affaire principale + liste de lignes de 48 pt.
- **Ajouts** : retour « ‹ Bureau » ; H1 « Enquêtes » et la ligne de verbes.
- **Exclusion** : les affaires de chapitre (préfixe C) ne sont pas listées ici.
- **États** (existants) : NOUVEAU, EN COURS (temps restant), RÉSOLU, VERROUILLÉ.

### h03 · Sélection ALIBI
- **Contenu** : H1 « Alibi » ; sous-titre « Une déclaration. Des traces. Vrai ou faux ? » ; liste de fiches `alibi.paper`.
- **Chaque fiche** :
  - « ALIBI nn » + état ;
  - « {Prénom I.} affirme : « {déclaration} » » en Newsreader 16,5 ;
  - « n TRACES · ≈ 3 MIN ».
- **Fiche classée** : à 60 %, avec le verdict à la place de la durée (« MENSONGE » ou « VRAI »).
- **Bouton** : « VÉRIFIER L'ALIBI nn » (le premier NOUVEAU, ou EN COURS).
- **Tap sur une fiche** : l'alibi est sélectionné (filet rouge de 1,5 pt), puis le bouton lance le mode ALIBI existant.
- **État vide** (tout classé) : fiche « Tous les alibis sont vérifiés. » + lien Archives.

### h04 · Hub Histoire
- **Objectif** : reprendre en un tap.
- **Contenu** :
  - `StoryHeroRender` : plan MEDIUM, joueur de 3/4 dos dans le décor du chapitre, travelling latéral de 6 cm/s en boucle aller-retour de 20 s. Fixe si Réduire les animations est activé.
  - LABEL « HISTOIRE · BEN », H1-hero avec le nom, TECHNICAL `{RANG} · {MATRICULE}`.
  - Bloc chapitre : filet supérieur, « CHAPITRE 0N » / « SCÈNE n / N », H3 avec le titre, barre de 2 pt.
  - Bouton [CONTINUER] ; grille de 3 contours : MON ENQUÊTEUR · CARRIÈRE · MON BUREAU.
  - ⚙ en haut à droite.
- **Tap sur le bloc chapitre** → h10.
- **États** :
  - **fin de contenu** : bloc « Chapitre suivant bientôt disponible », bouton [REVOIR UN CHAPITRE] ;
  - **rendu 3D en cours de chargement** : image fixe de dernière capture (`story_hero_last.jpg`) puis fondu vers le rendu temps réel ; sans capture, fond `scene.void`.

### h05 · Création du personnage (4 étapes)
Commun : `StepBar` en haut, retour vers l'étape précédente, rendu 3D en haut (350 pt), sheet papier en bas (340 pt).

**Étape 1 · IDENTITÉ**
- Champs Prénom et Nom : 56 pt, papier, Plex Mono 11 pour le libellé, Newsreader 20 pour la saisie.
- Préremplis avec le modèle choisi (Élise Morel / Vincent Delmas).
- **Validation** :
  - 2 à 20 caractères, lettres, espace, apostrophe et tiret ;
  - filtre de grossièretés local ;
  - erreur par post-it : « Nom non valide pour un dossier officiel. ».
- Choix de la **base** (silhouette) : FÉMININE / MASCULINE, en segmented de 2. C'est le seul choix structurant (modèle 3D de base).

**Étape 2 · APPARENCE**
- Segmented TEINT · VISAGE · CHEVEUX · YEUX, chacun avec 6 options (CHARACTER_CUSTOMIZATION.md).
- Changement instantané (≤ 100 ms) avec un fondu enchaîné de 150 ms. La caméra passe en CLOSE sur le visage.

**Étape 3 · TENUE** (h06)
- Caméra WIDE en pied. Carrousel ‹ › de 4 tenues, 2 variantes de couleur chacune (tap sur le libellé de variante).
- Rotation au doigt ±180°.

**Étape 4 · CONFIRMATION** (h05b)
- Feuille « VOTRE DOSSIER D'ENQUÊTEUR » : sceau, tirage (capture du buste 3D, format S4), nom, matricule généré (BEN-0xxxx, 5 chiffres, unique), SERVICE BEN, RANG INITIAL ENQUÊTEUR, AFFECTATION.
- Maintien « COMMENCER MA CARRIÈRE » (1,2 s) → cachet IDENTITÉ CONFIRMÉE → fondu au noir de 600 ms → scène 01-01.
- **Modification ultérieure** : l'apparence et la tenue restent modifiables (h19). Le nom est définitif, sauf réinitialisation.

### h06 · Personnage 3D (présentation)
- Voir 3D_DIRECTION §4 pour le studio.
- Utilisé à l'étape Tenue et en lecture depuis le Profil (« Voir en 3D », sans carrousel, bouton « Fermer »).
- Deux annotations LABEL au maximum, reliées par un trait de 1 pt à la zone de la tenue concernée.

### h07 · Profil enquêteur
- **Feuille papier**, dans cet ordre :
  1. Double filet BEN / BUREAU DES ENQUÊTES NUMÉRIQUES.
  2. Tirage 112 × 142 pt + nom (H2) + matricule + cachet du rang.
  3. Trois chiffres (LABEL + Newsreader 28) : AFFAIRES TRAITÉES · RÉSOLUES · ANCIENNETÉ.
  4. HISTORIQUE, 3 dernières lignes datées.
  5. Visa de Lacaze + lien « Voir en 3D ».
- **Ancienneté** : durée écoulée depuis la création, en temps de jeu (1 chapitre = 3 mois de jeu), arrondie en mois ou en ans. Affichage « 2 ans ».
- **États** :
  - 0 affaire : « 0 · 0 · — » et l'historique « Première affectation » ;
  - portrait indisponible : initiales (règle de repli existante).

### h08 · Carrière
- **Frise verticale** sur une feuille papier. Par rang : point de 14 pt, rang en LABEL 12/700, étape en Newsreader 16, méta en TECHNICAL.
- **États d'étape** :

| État | Point | Trait | Opacité | Méta |
|---|---|---|---|---|
| Franchie | Plein encre | Plein | 100 % | Date |
| Actuelle | Anneau rouge + halo | Pointillé vers la suite | 100 % | « ACTUEL » + compteur |
| Future | Anneau vide | Pointillé | 45 % | « CONDITION : … » |

- **Conditions** : affaires résolues et chapitre atteint, les deux sont nécessaires (voir CHARACTER_CUSTOMIZATION §6).
- **Tap sur une étape franchie** : sheet avec la note d'avancement (écran 10 du doc 06).
- **Aucune** jauge ni pourcentage.

### h09 · Mon bureau
- Rendu 3D du bureau, plan fixe WIDE en 3/4 plongée (ENVIRONMENTS §BEN_OFFICE_PLAYER).
- `LevelTag` « OFFICE_0N » en haut à droite. 3 à 6 `HotspotDot` selon le niveau.
- **Tap sur un point** : fondu de 450 ms vers le plan CLOSE de l'objet + sheet de description (nom, provenance, date). Retour par ‹ ou par swipe vers le bas.
- **Sheet** : « Mon bureau · NIVEAU n / 4 » ; prochain ajout avec sa condition ; puces n OBJETS · n RÉCOMPENSES.
- **États** :
  - OFFICE_01 : points TÉLÉPHONE, ORDINATEUR, DOSSIERS uniquement ;
  - nouvel objet non vu : point avec anneau rouge de 2 pt, jusqu'au premier tap.

### h10 · Chapitre
- `ChapterFolder` : onglet « CHAPITRE 0N », H2 avec le titre, résumé de 2 lignes, liste des étapes.
- **Chaque étape** : statut + titre + type (SCÈNE, TÉLÉPHONE ou ALIBI). Les étapes verrouillées sont à 45 %, sans titre révélé si elles contiennent une surprise (titre « ··· »).
- **Bouton** : « CONTINUER · SCÈNE n ».
- **Tap sur une étape franchie** : « Revoir » (scène) ou rapport (affaire).
- **Chapitre terminé** : cachet RÉSOLU sur la chemise, bouton [CHAPITRE SUIVANT].

### h11 · Dialogue / h12 · Choix
Voir DIALOGUE_UI.md.

### h13 · Transition vers le téléphone / h14 · Retour au BEN
Voir TRANSITIONS.md, T-SIG-1 et T-SIG-2.

### h15 · Nouveau dossier
- Dernière image de la scène reproduite en 2D : la chemise kraft sur le bureau de Lacaze.
- Onglet « N° C{ch}-{lettre} », LABEL « CHAPITRE 0N · AFFAIRE A », titre H2, cachet NOUVEAU, étiquette « AFFECTÉ À ».
- **Bouton** [OUVRIR LE DOSSIER] → briefing ENQUÊTES standard, avec le vocabulaire et les écrans existants.
- **Apparition** : le bouton monte en fondu 500 ms après la fin de la scène.

### h16 · Résultat de chapitre
- **Feuille**, dans cet ordre :
  1. « FIN DU CHAPITRE 0N » + cachet.
  2. H2 avec le titre.
  3. Résumé de 2 phrases.
  4. Tableau : AFFAIRES DU CHAPITRE · ALIBI · TEMPS TOTAL.
  5. VOS DÉCISIONS : 1 ou 2 phrases générées à partir des choix marqués `remembered`.
- **Bouton** [CLASSER LE CHAPITRE] → h17.
- **Chapitre non résolu** (une affaire échouée) : cachet CLASSÉ gris ; la phrase de résumé vient de la variante d'échec du chapitre. Le jeu continue malgré tout : un chapitre n'est jamais bloquant.

### h17 · Progression
- Feuille « ÉTAT DE SERVICE » : RANG ACTUEL → RANG SUIVANT, `ProgressBoxes` (une case par affaire requise pour le palier), une phrase (« n affaires résolues sur N… ») et la note de Lacaze en Caveat (texte fourni par le chapitre).
- **Rang atteint** : on enchaîne sur l'écran « Avancement de service » du doc 06, puis sur h18 si un objet est débloqué.
- **Rang maximal** : cases remplacées par « Rang maximal atteint. ».

### h18 · Récompense
- `RewardObject` au centre (220 × 270 pt de zone), LABEL « AJOUTÉ À VOTRE BUREAU », H2 avec le nom de l'objet, caption avec la provenance.
- **Bouton** [VOIR DANS MON BUREAU] → h09 cadré sur l'objet ; lien « Plus tard ».
- **Aucune** récompense en monnaie, en pourcentage ou en boost.

### h19 · Paramètres histoire
Trois `SettingsGroup` :

| Groupe | Réglage | Valeurs |
|---|---|---|
| LECTURE | Taille des sous-titres | Petite / Moyenne / Grande, liée à Dynamic Type par défaut |
| LECTURE | Vitesse du texte | Lente 45 ms / Normale 28 ms / Instantanée |
| LECTURE | Avance automatique | Non / Oui (délai = 1,2 s + 45 ms par caractère) |
| LECTURE | Voix | Oui / Non |
| AFFICHAGE 3D | Qualité | Auto / Économie / Haute (3D_DIRECTION §9) |
| AFFICHAGE 3D | Profondeur de champ | Oui / Non |
| AFFICHAGE 3D | Réduire les mouvements de caméra | Suit le réglage système par défaut |
| CARRIÈRE | Modifier l'apparence | Ouvre h05, étapes 2 et 3 |
| CARRIÈRE | Rejouer un chapitre | Choix déjà faits affichés, sans effet sur la carrière |
| CARRIÈRE | Réinitialiser l'histoire | Rouge ; maintien de 1,6 s ; conserve ENQUÊTES et ALIBI |

## 4. États globaux
- **Chargement de scène** :
  - la dernière image de l'écran précédent reste figée ;
  - au-delà de 1,5 s, LABEL « CHARGEMENT DE LA SCÈNE… » en bas à gauche, tapé en Mono ;
  - pas de spinner.
- **Erreur de chargement 3D** : post-it « La scène n'a pas pu être chargée. » + [RÉESSAYER] / « Lire en texte ». Le mode texte affiche les répliques sur fond `scene.void` avec le décor en image fixe.
- **Appareil non compatible** (moins de 4 Go de RAM) : qualité Économie forcée ; mode texte si le rendu tombe sous 24 fps.
- **Interruption** (appel, arrière-plan) : pause immédiate, reprise sur le plan courant.
