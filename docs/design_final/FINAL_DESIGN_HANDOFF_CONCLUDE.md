# FINAL_DESIGN_HANDOFF_CONCLUDE.md

CONCLUDE : ENQUÊTES · NOREL GAMES · Design final V3.0 · 2026-09-26
Destinataire : Claude Code, agent développeur, iOS SwiftUI.

**Maquettes de référence** : `CONCLUDE - Final UX.dc.html`. Les écrans y sont numérotés 01 à 15, avec les mêmes numéros qu'ici.

**Ce document remplace les parcours** de `06_JOUEUR_PROFIL_SELECTION.md` §1 et du handoff TRACE V2 lorsqu'ils le contredisent. Tout le reste reste en vigueur :
- tokens et composants papier déjà implémentés ;
- téléphone ;
- tampons ;
- assets de `phase2/`.

**Ne pas modifier** : le moteur d'enquête, les données des affaires (`case_00N.json`) ni la logique de score. Les textes propres à une affaire (noms, heures, pièces) viennent **toujours des données**. Les valeurs de #001 visibles dans les maquettes (Lucas, 22:47, etc.) sont illustratives.

---

## A. Vision finale

CONCLUDE : ENQUÊTES est un jeu d'enquête. Le joueur ouvre un dossier, fouille le téléphone d'une personne liée à l'affaire, verse au dossier les éléments qui comptent, puis désigne le responsable.

Hors du téléphone, tout est physique : bureau sombre, chemises kraft, papier, tampons, écriture manuscrite. Dans le téléphone, tout est numérique, moderne et crédible. Le passage du dossier au téléphone est la signature du jeu.

La profondeur vient des enquêtes, jamais de l'interface. Un joueur qui lance le jeu pour la première fois doit comprendre en moins de 10 secondes, sans aide extérieure :
- qu'il s'agit d'une enquête ;
- qu'il doit chercher des indices dans un téléphone ;
- qu'il doit désigner le responsable.

**Changement majeur de cette version** : la couche carrière passe *après* la première affaire. Elle comprend le choix d'apparence, la confirmation, le dossier agent, l'affectation et la cinématique de recrutement. Au premier lancement, le joueur arrive au téléphone en 4 écrans. Le cas #001 sert de tutoriel, avec 3 bulles contextuelles.

## B. Principes UX (règles de produit)

1. **Une action principale par écran.** Un seul bouton plein (#EFEBE3 sur fond sombre, #1C1A17 sur papier). Les actions secondaires sont des liens texte ou des boutons en contour.
2. **Trois verbes, partout identiques** : EXPLORER · VERSER AU DOSSIER · CONCLURE. Ne jamais employer « Épingler », « Accuser » ou « Sauvegarder » pour ces actions.
3. **Un seul geste de collecte** : appui long de 0,4 s sur n'importe quel élément du téléphone, puis feuille « VERSER AU DOSSIER ».
4. **On n'empêche jamais de conclure.** Le bouton CONCLURE est toujours actif. Il est simplement moins mis en avant tant que le dossier est mince.
5. **Chaque état vide dit quoi faire ensuite.** Une phrase, et un bouton si c'est utile.
6. **Les erreurs restent dans l'univers** : post-it jaune, jamais d'alerte système.
7. **Pas d'animation décorative en boucle.** Une animation n'accompagne qu'un changement d'état.
8. **Une phrase plutôt qu'un paragraphe.** Maximum 2 lignes pour une bulle d'aide, 3 lignes pour un résumé d'affaire.
9. **Règle d'arbitrage** : SIMPLICITÉ > COMPRÉHENSION > COHÉRENCE > IMMERSION > DÉCORATION.

## C. Parcours complet du premier lancement

```
01 Lancement (1,6 s, automatique)
02 Écran titre ─ [COMMENCER L'ENQUÊTE]
03 Qui enquête ? ─ [CONTINUER]          (Élise présélectionnée)
(cinématique #001, 20 s max, [Passer] visible dès 1 s)
04 Dossier #001 : briefing ─ [OUVRIR LE TÉLÉPHONE]   → le chrono démarre
05 Téléphone + bulle 1 EXPLORER
06 Appui long sur un élément + bulle 2 VERSER AU DOSSIER
07 Retour visuel : pièce versée
08 Carnet + bulle 3 RELIER (au 1er passage dans le Carnet)
09 Conclure : QUI EST RESPONSABLE ? ─ maintien 1,2 s
10 Vérification → RÉSOLU / NON RÉSOLU ─ [LIRE LE RAPPORT]
11 Rapport de clôture ─ [CLASSER LE DOSSIER]
12 Affectation officielle au BEN ─ [ALLER AU BUREAU]
13 Bureau (hub)
```

- Du lancement au téléphone : 4 taps au maximum (02, 03, éventuellement Passer, 04).
- Temps cible : moins de 45 s si le joueur lit le briefing, moins de 15 s s'il le parcourt.
- **Lancements suivants** :
  - enquête en cours : 02b, [REPRENDRE L'ENQUÊTE] ;
  - aucune enquête en cours : ouverture directe sur 13 Bureau, sans écran titre.

## D. Onboarding : textes exacts et comportement

L'onboarding se fait **dans le cas #001**, et uniquement lors de la première partie (`hasSeenTutorial == false`). Il n'existe aucune page de règles séparée.

| # | Déclencheur | Ancrage | Texte (kicker / corps / action) | Disparaît quand |
|---|---|---|---|---|
| — | Écran 02 | Sous l'accroche | Rangée de 3 verbes : `01 EXPLORER` · `02 VERSER AU DOSSIER` · `03 CONCLURE` | — (statique) |
| — | Écran 04 | Bloc « Votre mission » + 3 étapes numérotées | Voir §F-04 | — |
| 1 | Première apparition de l'accueil du téléphone | Sous l'icône Messages, flèche vers le haut | `1 / 3 · EXPLORER` / « Commencez par les messages d'Alex. Tout ce qui est dans ce téléphone peut compter. » / `Touchez Messages` | Tap sur Messages, ou tap ailleurs (la bulle se ferme, rien n'est bloqué) |
| 2 | Première ouverture d'une conversation contenant une pièce utile, après 2 s de lecture | Au-dessus de la bulle concernée | `2 / 3 · VERSER AU DOSSIER` / « Un détail vous semble important ? Maintenez-le, puis versez-le au dossier. » | Première pièce versée, ou fermeture |
| 3 | Première ouverture du Carnet | Au-dessus du bouton CONCLURE | `3 / 3 · RELIER` / « Dites ce que prouve la pièce : elle accuse ou disculpe un suspect. Quand vous êtes sûr, concluez. » | Premier lien ACCUSE/DISCULPE, ou fermeture |

**Règles des bulles**
- Une seule bulle visible à la fois. Aucune ne bloque l'interaction : ce n'est jamais un overlay modal.
- L'élément ciblé reçoit un anneau #ECE5D3 de 3 pt et un halo de 4 pt à 25 %. Les autres éléments sont à 45 % d'opacité **uniquement** pour la bulle 1.
- Le chrono continue pendant les bulles. Elles n'apparaissent que tant que le chrono est au-dessus de 06:30.
- Si le joueur verse une pièce avant la bulle 2, la bulle 2 est sautée. Même principe pour la bulle 3.
- Les bulles se rejouent via Paramètres › « Revoir le tutoriel ».
- **Relance douce** : si, après 90 s dans le téléphone, aucune pièce n'a été versée, un toast apparaît en haut : « Astuce · Maintenez un élément pour le verser au dossier. » Une seule fois.

**Style d'une bulle** : papier #ECE5D3, padding 14/16, largeur maximale 280 pt, ombre 0 18 40 à 60 %, flèche en losange de 14 pt.
- Kicker : Plex Mono 10/700, interlettrage +16 %, #A3261E.
- Corps : Newsreader 16, interligne 1,35.
- Action : Plex Mono 10, #5B5448.
- Variante sombre dans le Carnet (sur papier) : fond #1C1A17, texte #EFEBE3, kicker #D0493C.

## E. Architecture de navigation

```
Lancement
 ├─ (1er lancement) Titre → Qui enquête ? → [Cinématique #001] → Dossier #001 → Téléphone
 ├─ (enquête en cours) Titre-reprise → Téléphone de l'affaire
 └─ (sinon) Bureau

Bureau (onglet 1) ── barre du bas : BUREAU · ARCHIVES · ENQUÊTEUR
 └─ Dossier N (briefing) → [cinématique N] → Téléphone
      Téléphone ⇄ Apps (push, retour par ‹ ou geste de bord)
      Barre du dossier (toujours visible dans le téléphone) → Carnet (sheet plein écran)
           Carnet : PIÈCES · SUSPECTS · CHRONOLOGIE · [ampoule] Indice (sheet)
           Carnet → CONCLURE → Conclusion (push) → Résultat → Rapport → Bureau
      Chrono à 00:00 → Conclusion forcée (sans retour possible)
Archives (onglet 2) → Rapport d'un dossier classé (lecture) → [REJOUER]
Enquêteur (onglet 3) → Profil (Identité, Parcours, Affaires, Distinctions, Historique)
      Identité → Changer d'enquêteur / d'apparence (écrans 02–05 du document 06)
Paramètres : icône ⚙ sur Titre, et section en bas de Enquêteur
```

**Retour arrière**
- Dans une affaire, il y a toujours un chemin retour vers le téléphone.
- Quitter une affaire (‹ sur le briefing, ou Bureau) demande une confirmation par feuille : « Mettre l'enquête en pause ? Le chrono s'arrête. » Choix : [METTRE EN PAUSE] / Continuer.
- Après la conclusion, pas de retour possible.

## F. Spécifications des écrans

Gabarit commun (repris de 06 §2) :
- Référence 390 × 844 pt.
- Marges : 24 pt pour le bouton, 16 pt pour les feuilles, 28 pt pour les titres.
- Bouton principal : 56 pt de haut, rayon 6, Plex Mono 13/700, interlettrage +16 %, capitales. Position : `safeArea.bottom` + 10.
- Lien secondaire : Geist 15, #C9C3B6, zone tactile d'au moins 44 pt.

### 01 · Lancement
- **Objectif** : afficher la marque et précharger.
- **Éléments** :
  - fond #0A0908 ;
  - `app_icon` en tuile 188 pt, centrée, rayon 42 pt, ombre 0 30 60 à 70 % ;
  - « NOREL GAMES » en Plex Mono 10, interlettrage +32 %, #6F6A61, à 58 pt du bas.
- **Comportement** :
  - durée minimale 1,6 s, maximale 4 s ;
  - précharge le Bureau, `case_001`, les 4 portraits des suspects de #001 et les portraits des joueurs ;
  - transition : fondu au noir 250 ms, puis fondu vers l'écran suivant 350 ms.
- **Le LaunchScreen.storyboard doit être identique** : même fond, même tuile, même position.
- **États** : si le préchargement dépasse 4 s, on continue quand même (les portraits utilisent le fallback).

### 02 · Écran titre (premier lancement)
- **Objectif** : faire passer le test des 10 s.
- **Hiérarchie** :
  1. Bandeau logo, recadrage papier (§H) : 330 × 148 pt, centré, rotation −1,5°, à 112 pt du haut.
  2. Accroche en Newsreader 27/500 : « Un téléphone. Une disparition. Quelqu'un ment. »
  3. Mission en Geist 16, #C9C3B6 : « Fouillez le téléphone, versez les indices au dossier et désignez le responsable. »
  4. 3 verbes en rangée : numéro #D0493C en Plex Mono 10, verbe en Plex Mono 11/700, filet supérieur de 1,5 pt à 30 %.
  5. Bouton [COMMENCER L'ENQUÊTE].
- **Autres éléments** : ⚙ Paramètres en haut à droite (44 × 44 pt). Pas d'autre lien.
- **Transition** : le bouton lance l'écran 03 en push (fondu + offset 24 pt).

### 02b · Titre, reprise
- Même fond et même bandeau logo.
- Fiche « ENQUÊTE EN COURS » : `#00N · titre`, temps restant, nombre de pièces.
- Bouton [REPRENDRE L'ENQUÊTE] ; lien « Aller au Bureau ».
- Reprendre ouvre directement le téléphone, sur l'app où le joueur s'était arrêté. Le chrono reprend.

### 03 · Qui enquête ?
- **Titre** « QUI ENQUÊTE ? » en Plex Mono 18/700 ; sous-titre « Vous pourrez changer dans votre profil. »
- **Deux fiches** en 2 colonnes (gap 14 pt) : tirage 4:5 de l'apparence A, nom en Newsreader 21/600, intitulé en Plex Mono 10.
- **Élise présélectionnée** : fiche en avant de −6 pt, filet 2 pt #A3261E, mention « ✓ CHOISIE ». L'autre fiche est à 60 %.
- **Texte** : « Deux enquêteurs du Bureau des Enquêtes Numériques. Même mission, mêmes règles. »
- **Bouton** [CONTINUER].
- **Enregistrement** :
  - on enregistre `player.id` et `appearance = A`, en local ;
  - aucun matricule ni rang n'est affiché ici ;
  - en cas d'échec d'écriture, on continue quand même en mémoire et on réessaie en arrière-plan (jamais bloquant).

### Cinématique #001 (existante)
- 20 s maximum.
- « Passer › » en haut à droite, visible dès 1 s.
- Lue une seule fois automatiquement, puis accessible depuis le briefing (« Revoir la séquence »).

### 04 · Dossier #001, briefing
- **Structure** :
  - chemise kraft #C3AC80, onglet « N° 001 » ;
  - feuille #ECE5D3 + `tex_paper_grain`.
- **Contenu de la feuille** :
  - en-tête : `DOSSIER #001 · {case.category}` / `{case.city}` ;
  - tirage de la personne concernée, 84 × 104 pt ;
  - titre `case.title` en Newsreader 26/600 ;
  - résumé `case.summary` en Newsreader 14,5, 3 lignes maximum ;
  - bloc **VOTRE MISSION** : filet rouge 1,5 pt, kicker rouge, texte `case.objective` en Newsreader 17/500. Texte de #001 : « Découvrir qui ment sur son alibi et désigner le responsable. » ;
  - 3 étapes numérotées :
    1. EXPLORER le téléphone d'{victim.firstName} : messages, appels, photos, lieux.
    2. VERSER AU DOSSIER les éléments qui comptent.
    3. CONCLURE en désignant le responsable.
  - pied de page : `{n} SUSPECTS` · `TEMPS : {mm:ss}`.
- **Bouton** [OUVRIR LE TÉLÉPHONE].
- **Transition** vers le téléphone : chaîne T1 à T7 de 06 §D, abrégée au premier lancement :
  - le sachet de scellé et le téléphone sortent (1,2 s) ;
  - zoom sur l'écran ;
  - l'écran verrouillé est sauté en #001 (déverrouillage automatique, 0,6 s).
  - Le chrono démarre à la première image de l'accueil.
- **Affaires 002 à 005** : même écran, sans les 3 étapes (remplacées par le lien « Rappel des règles »). Le verrouillage existant est conservé.

### 05 · Téléphone (accueil)
- **Structure** :
  - accueil existant (12 apps en grille 4 × 3) ;
  - **étiquette chrono** en haut au centre : papier #ECE5D3, Plex Mono 13/700, rotation −1° ;
  - **barre du dossier** en bas : 64 pt de haut, marges 12 pt, rayon 10, papier. Elle contient « DOSSIER #00N », « {n} pièce(s) versée(s) » et le bouton CARNET.
- **Bouton CARNET** : en contour tant qu'il y a 0 pièce, plein #1C1A17 dès 1 pièce.
- **Chrono critique** (existant, conservé) : sous 01:00, l'étiquette passe au rouge #A3261E, texte #F6EDEA, avec un tic discret chaque seconde. Sous 00:10, s'ajoute un haptique léger chaque seconde.
- **État bulle 1** : voir §D.

### 06 · Verser au dossier (dans toutes les apps)
- **Appui long** de 0,4 s sur un élément « versable » :
  - bulle de message, ligne d'appel, photo, épingle de lieu, événement, note, mail, page, contact, fichier ;
  - l'élément grossit à 1,03, reçoit un anneau #ECE5D3 de 2 pt, un haptique `medium` ;
  - la feuille s'ouvre.
- **Feuille** (papier) :
  - poignée ;
  - kicker `{TYPE} · {SOURCE} · {DATE HEURE}` ;
  - aperçu en Newsreader 16 ;
  - bouton [VERSER AU DOSSIER] (fond #1C1A17) ;
  - lien « Annuler ».
- **Élément déjà versé** : la feuille affiche « PIÈCE 0N · déjà au dossier » et le bouton [VOIR DANS LE CARNET].
- **Élément non versable** : l'appui long ne fait rien (pas de feuille, pas d'haptique). Tout élément affiché *peut* être versé, y compris les éléments sans intérêt. C'est volontaire : le joueur juge lui-même.
- **Limite** : aucune.

### 07 · Retour après versement
- Une copie papier de l'élément apparaît au-dessus de sa position : 210 pt, rotation −4°.
- Elle se réduit et glisse vers la barre du dossier en 420 ms (`paper`).
- La barre pulse : filet 2 pt #A3261E pendant 600 ms. Le compteur s'incrémente ; le son `paper_slide` et un haptique `light` accompagnent.
- Dans l'app, l'élément garde une étiquette « PIÈCE 0N » (Plex Mono 9/700, papier). Numérotation dans l'ordre de versement.

### 08 · Carnet
- **Présentation** : sheet plein écran, fond bureau.
- **3 onglets de feuille** : PIÈCES · {n} / SUSPECTS / CHRONOLOGIE. Le CONTEXTE reste dans le briefing, accessible via « Dossier » en haut.
- **PIÈCES** :
  - liste de fiches papier dans l'ordre de versement ;
  - chaque fiche : type, source, date et heure, aperçu ;
  - « CETTE PIÈCE… » suivi de [L'ACCUSE] (plein #A3261E) / [LE DISCULPE] (contour), puis choix du suspect en puces ;
  - une annotation manuscrite (Caveat #2B3A5A) résume le lien : « Lucas → accusé par 1 pièce » ;
  - une pièce peut être liée à plusieurs suspects.
- **SUSPECTS** : fiches existantes. Chacune affiche le nombre ▲ (accuse) et ▼ (disculpe), et la liste de ses pièces.
- **CHRONOLOGIE** : existante. Les pièces versées y apparaissent automatiquement à leur heure.
- **Ampoule d'indice** : en haut à droite (44 × 44), ouvre l'écran 14.
- **Bouton [CONCLURE L'ENQUÊTE]** : en contour si moins de 3 pièces sont reliées, plein à partir de 3. Toujours actif.
- **États** : vide (écran 15), chargement (feuilles sans contenu, pas de spinner).

### 09 · Conclusion
- **Titre** : kicker `DOSSIER #00N · CONCLUSION`, titre « QUI EST RESPONSABLE ? ».
- **Grille 2 × 2** des suspects : tirage carré, nom, compteurs `▲n ▼n` (texte, pas seulement de la couleur).
- **Aucun suspect choisi** : bouton désactivé « CHOISISSEZ UN SUSPECT ».
- **Suspect choisi** : fiche en avant, filet rouge, autres fiches à 60 %. Le bouton devient « MAINTENIR : {PRÉNOM} EST RESPONSABLE ».
- **Maintien** : 1,2 s, remplissage linéaire #A3261E. Relâché trop tôt : vidage en 250 ms.
- **Accessibilité** : avec VoiceOver ou Switch Control, double-tap puis feuille de confirmation.
- **Fin du chrono** : l'écran s'ouvre de force avec l'étiquette « TEMPS ÉCOULÉ ». Il n'y a pas de retour possible, mais aucune limite de temps pour choisir.

### 10 · Vérification et résultat
- « VÉRIFICATION DU DOSSIER… » tapé en 1,4 s, puis 300 ms de silence.
- La chemise se referme, puis le tampon tombe :
  - RÉSOLU : `stamp_resolu_rouge_marque` ;
  - NON RÉSOLU : `stamp_non_resolu_noir_marque`.
- Mention « RESPONSABLE DÉSIGNÉ : {NOM} ».
- Bouton [LIRE LE RAPPORT].

### 11 · Rapport de clôture
- **Feuille**, dans cet ordre :
  1. En-tête « RAPPORT · #00N » + mini-tampon.
  2. CE QUI S'EST PASSÉ : `case.solution.summary`, 3 phrases maximum.
  3. PIÈCES CLÉS · x / y TROUVÉES : ✓ pour les trouvées, ○ à 45 % pour les manquées, avec leur libellé.
  4. En pied, sur 3 colonnes : TEMPS RESTANT · INDICES · NOTE (score existant, 0–100).
- **Bouton** [CLASSER LE DOSSIER].
- **NON RÉSOLU** :
  - le titre de la section 2 devient « CE QUE VOUS N'AVEZ PAS VU » ;
  - la note est remplacée par « — » ;
  - bouton [REPRENDRE L'ENQUÊTE] : relance avec le chrono plein et conserve les pièces versées ;
  - lien « Classer quand même ».
- La note ne s'affiche jamais en grand.

### 12 · Affectation officielle (une seule fois, après #001)
- **Déclenchement** : #001 résolu, OU deux tentatives échouées, OU choix de « Classer quand même ».
- **Feuille** : sceau BEN bleu + « BUREAU DES ENQUÊTES NUMÉRIQUES ».
  - Titre en Newsreader 24 : « Bon travail, {Nom}. Vous êtes affecté(e) au BEN. » Si non résolu : « Dossier classé, {Nom}. Vous êtes affecté(e) au BEN. »
  - Texte : « Quatre dossiers vous attendent au Bureau. Votre carte d'agent et votre rang sont dans votre profil. »
  - Signature de Lacaze + cachet du rang obtenu.
- **Lien** « Voir la séquence » : cinématique de recrutement version courte, 30 s, plans P3, P4, P7, P9, P10 de 06 §5.
- **Bouton** [ALLER AU BUREAU].
- **Effet** : le matricule, le rang et le profil deviennent visibles à partir de cet écran.

### 13 · Bureau (hub)
- **En-tête** : « Bureau » en Newsreader 28, et `{initiale}. {NOM} · {RANG}` en Plex Mono 10. Pastille portrait 44 pt, qui ouvre Enquêteur.
- **PROCHAINE ENQUÊTE** : une grande chemise kraft 354 × 300 pt, avec l'enquête en cours ou sinon la première disponible. Elle affiche catégorie, ville, titre, accroche sur 2 lignes, difficulté ●○, durée et statut.
- **AUTRES DOSSIERS** : liste de lignes de 48 pt (n°, titre, statut). RÉSOLU en #D0493C avec le texte ; VERROUILLÉ à 50 % avec la condition au tap.
- **Bouton** [OUVRIR LE DOSSIER] (ou [REPRENDRE L'ENQUÊTE]).
- **Barre du bas** : BUREAU · ARCHIVES · ENQUÊTEUR.
- **États** :
  - tout résolu : la chemise est remplacée par une feuille « Tous les dossiers sont classés. De nouvelles affaires arrivent bientôt. », avec le lien Archives ;
  - chargement : chemise vide sans texte.

### 14 · Indice
- **Présentation** : sheet papier au-dessus d'un voile à 50 %.
- **Contenu** :
  - « BESOIN D'AIDE ? » + solde « n tickets » ;
  - les indices déjà révélés en post-it jaune #FBF3C8 (Caveat 23, #2B3A5A) ;
  - l'indice suivant fermé, avec son coût ;
  - bouton [RÉVÉLER L'INDICE n · 1 TICKET] ; lien « Continuer seul ».
- **Trois niveaux par affaire** : direction → lieu → pièce exacte (données `case.hints`, existantes).
- **0 ticket** : bouton désactivé « PLUS DE TICKETS ». Mention : « 1 ticket offert à chaque dossier résolu. » (économie existante conservée).

### 15 · États

Voir §N.

### Écrans conservés tels quels (document 06)
- Profil Enquêteur (09 de 06).
- Avancement de service (10 de 06).
- Changement d'identité (02–05 de 06).
- Fiche Lacaze.

Accessibles uniquement après l'écran 12.

## G. Design system (rappel, déjà implémenté ; ajouts marqués ★)

**Couleurs**

| Rôle | Valeur |
|---|---|
| Fond lancement | #0A0908 |
| Bureau | dégradé radial #2E261D → #12100E → #0A0908 |
| Papier | #ECE5D3 · papier sélectionné #F0E9D8 · tirage #FBF9F4 |
| Kraft | #C3AC80 · chemise d'agent #9A9A94 |
| Encre principale | #1C1A17 |
| Encre secondaire | #3A3631 · libellés #5B5448 |
| Texte sur sombre | #EFEBE3 · secondaire #C9C3B6 / #A9A397 · tertiaire #6F6A61 |
| Rouge sur papier | #A3261E |
| Rouge sur sombre | #D0493C |
| Bleu-gris BEN / fond portrait | #6F7A86 |
| Manuscrit | #2B3A5A |
| Post-it (erreur, indice) ★ | #FBF3C8 |

**Typographie**

| Police | Usage |
|---|---|
| IBM Plex Mono | Libellés, boutons, kickers, chrono |
| Newsreader | Titres, noms, textes de dossier |
| Geist | Textes d'interface sur fond sombre, liens |
| Caveat | Annotations, uniquement |
| SF Pro | Tout l'intérieur du téléphone (système) |

**Échelle de tailles (pt)**

| Taille | Usage |
|---|---|
| 9–10 | Kickers |
| 11–13 | Valeurs |
| 14,5–16 | Texte courant |
| 17–18 | Titres d'écran en Mono |
| 21–30 | Titres en Newsreader |

**Espacements** : 4 · 8 · 12 · 14 · 16 · 20 · 24 · 28 · 44 (zone tactile).

**Rayons**
- Feuille : 0.
- Chemise : 0 10 10 10.
- Bouton : 6.
- Barre du dossier : 10.
- Sheet : 16 en haut.

**Ombres**
- Feuille : 0 18 40 à 55 %.
- Sélection : 0 26 50 à 70 %.
- Tirage : 0 4 10 à 25 %.

**Boutons**

| Type | Rendu |
|---|---|
| Principal | Plein |
| Contour | Inset 1,5 pt |
| Destructif | Plein #A3261E |
| Maintien | Fond #2A2825, remplissage #A3261E |
| Désactivé | Contour à 18 %, texte à 42 % |
| Chargement | Libellé remplacé par « … » tapé, largeur fixe |

**Badges** (étiquettes papier)
- « PIÈCE 0N » : Plex Mono 9/700 sur #ECE5D3.
- « NOUVEAU » : texte seul.
- « RÉSOLU » : mini-tampon PNG.

**Tampons** : `phase2/assets/stamps/`, en multiply sur papier et en normal sur sombre.

**Textures** : `phase2/assets/textures/`. Jamais de texture papier dans le téléphone.

**Images**
- Portraits : S4, fond bleu-gris, tirage à bord blanc.
- Photos de l'affaire : dans le téléphone, sans cadre papier. Dans le Carnet, avec cadre.

## H. Logo

**Fichier maître** : `final/assets/logo/logo_conclude_master.png`, 1254 × 1254 px. Il s'agit d'une tuile d'icône sur fond bois, avec le titre sur papier, un trombone, des photos du port et une empreinte.

**Dérivés à produire** (recadrages exacts, en px du master) :

| Nom | Recadrage | Sortie | Usage |
|---|---|---|---|
| `AppIcon` | x 44, y 48, 1166 × 1166 | 1024 × 1024 PNG sans alpha. iOS applique le masque : ne pas arrondir soi-même | Icône de l'app, App Store |
| `logo_tile` | Même recadrage, masque rayon 22,4 % | @1x 188 pt, soit @3x 564 px, PNG avec alpha | Écran 01, LaunchScreen |
| `logo_wordmark` | x 150, y 440, 960 × 430 | @3x 990 × 444 px | Bandeau des écrans 02 et 02b |

**Zone de respiration**
- Tuile : 20 % de son côté sur chaque bord.
- Bandeau : 16 pt minimum autour.

**Fonds autorisés** : #0A0908, dégradé Bureau sombre. **Interdits** : fonds clairs, papier, couleurs.

**Tailles minimales**
- Tuile : 96 pt.
- Bandeau : 240 pt de large.
- En dessous : mention texte « CONCLUDE » (Plex Mono 700, interlettrage +30 %) sur « ENQUÊTES » (Plex Mono, interlettrage +36 %), séparés par un filet #A3261E.

**Écrans concernés**
- 01 (tuile), 02 et 02b (bandeau).
- Paramètres › À propos (tuile 96 pt + « NOREL GAMES »).
- Carte de partage d'un rapport (mention texte).

**Absent de** : Bureau, dossiers, Carnet, téléphone de l'affaire, pièces, profil. La marque ne décore pas le jeu.

**Interdits** :
- recoloriser ;
- déformer ;
- ajouter une ombre portée colorée ;
- détourer le titre du papier ;
- animer le logo au-delà d'un fondu ;
- le placer dans une interface du téléphone fictif.

## I. Assets

| Nom | Type | Dimensions | Emplacement | Utilisation | État |
|---|---|---|---|---|---|
| logo_conclude_master.png | PNG | 1254² | final/assets/logo/ | Source | Livré |
| AppIcon | PNG | 1024² | Assets.xcassets/AppIcon | Icône | À recadrer (§H) |
| logo_tile | PNG alpha | 564² @3x | Assets/Brand/ | 01, LaunchScreen, À propos | À recadrer |
| logo_wordmark | PNG | 990 × 444 @3x | Assets/Brand/ | 02, 02b | À recadrer |
| stamp_resolu_rouge_marque, stamp_non_resolu_noir_marque | PNG | Existants | phase2/assets/stamps/ | 10, 11 | Livré |
| seal_ben_bleu, signature_lacaze_bleu, stamp_{rang}_* | PNG | Existants | phase2/assets/joueur/ | 12, profil | Livré |
| tex_paper_grain, tex_kraft_fibers | PNG | Existants | phase2/assets/textures/ | Feuilles, chemises | Livré |
| player_{elise,vincent}_{a,b}.jpg | JPG | 1024 × 1280 | Assets/Players/ | 03, profil | À générer (05_PERSONNAGES §4) |
| Portraits des suspects des 5 affaires | JPG | 1024 × 1280 | Assets/Cases/00N/ | Briefing, Carnet, Conclusion | À générer |
| Icônes des apps du téléphone | Existantes | — | — | 05 | Conservées |
| Cinématique #001 (20 s) | MP4 HEVC | 1170 × 2532 | Resources/Video/ | Avant 04 | En production |
| Recrutement court (30 s) | MP4 | 1170 × 2532 | Resources/Video/ | Lien sur 12 | À produire (06 §5) |

## J. Animations (uniquement celles-ci)

Spring `paper` : response 0,42, dampingFraction 0,86.

| Animation | Déclencheur | Détail | Durée |
|---|---|---|---|
| Push d'écran (hors téléphone) | Navigation | Fondu + offset x 24 → 0 | 300 ms `paper` |
| Apparition d'une feuille ou chemise | Arrivée | Offset y 24 → 0, opacité | `paper` |
| Ouverture de dossier | Briefing → téléphone | Chaîne 06 §D, abrégée en #001 | 1,8 s au total |
| Bulle d'aide | Apparition / disparition | Opacité + échelle 0,96 → 1 / fondu | 220 / 150 ms |
| Appui long | 0,4 s | Échelle 1,03 + anneau | 150 ms |
| Pièce versée | Confirmation | Copie → barre, puis pulsation | 420 + 600 ms |
| Sélection d'un suspect ou d'un personnage | Tap | Offset y −6, filet, autres fiches à 60 % | 260 ms |
| Maintien | Appui | Remplissage linéaire | 1,2 s ; retour 250 ms |
| Tampon | Résultat, cachets | Échelle 1,35 → 1, rotation, flou 2 → 0 | 180 ms + tassement 60 ms |
| Chrono critique | Sous 01:00 | Changement de couleur, sans clignotement | 400 ms |
| Notification entrante (téléphone) | Événement | Existant, conservé | — |

**Réduire les animations** : tout devient fondu de 200 ms. Le tampon apparaît sans chute. La copie de pièce ne vole pas : la barre pulse seule.

## K. Audio

| Son | Utilisation |
|---|---|
| `ui_paper_tap` | Boutons sur papier |
| `paper_folder_open` | Ouverture du briefing |
| `paper_slide` | Pièce versée, feuille qui apparaît |
| `evidence_bag` | Sachet ouvert (transition vers le téléphone) |
| `phone_unlock` | Déverrouillage |
| `notif_*` | Existants (téléphone) |
| `typewriter_key` | Vérification du dossier (1 son par caractère, volume −18 dB) |
| `stamp_heavy` | RÉSOLU, NON RÉSOLU, cachets de rang |
| `clock_tick_soft` | Chaque seconde sous 01:00 |
| `office_room` | Ambiance hors téléphone, −30 dB |

- Dans le téléphone : pas d'ambiance, silence.
- Avant le tampon : 300 ms de silence.
- Aucune musique pendant l'enquête. La nappe grave n'intervient qu'au briefing et au rapport.
- Tous les sons respectent le commutateur silencieux et le réglage Effets sonores.

## L. Haptique

| Déclencheur | Retour |
|---|---|
| Sélection (personnage, suspect, onglet) | `selection` |
| Appui long reconnu | `impactMedium` |
| Pièce versée | `impactLight` |
| Début du maintien | `impactLight` |
| Fin du maintien | `impactRigid` |
| Tampon RÉSOLU | `notificationSuccess` |
| Tampon NON RÉSOLU | `notificationWarning` |
| Chrono sous 00:10 | `impactLight` chaque seconde |
| Notification urgente (téléphone) | Existante |

Réglage Paramètres › Vibrations (activé par défaut).

## M. Accessibilité

- **Contraste** : texte ≥ 4,5:1 (les paires papier/encre et sombre/#EFEBE3 le respectent). #6F6A61 uniquement pour du texte non essentiel de 11 pt ou plus.
- **Zones tactiles** : 44 × 44 pt minimum ; lignes de liste de 48 pt ; boutons de 56 pt.
- **Pas d'information portée par la couleur seule** :
  - ▲/▼ accompagnés de chiffres ;
  - « ✓ CHOISIE » ;
  - statuts écrits en toutes lettres ;
  - chrono critique signalé aussi par le son et l'haptique.
- **Dynamic Type** : Newsreader et Geist suivent jusqu'à xxxLarge. Au-delà (AX1+), les grilles 2 colonnes passent en 1 colonne et les feuilles défilent. Les kickers en Mono restent fixes à 10 pt minimum.
- **VoiceOver** : chaque pièce se lit « Pièce 1, message de Lucas, 12 septembre 22 h 47 : … ». Le maintien est remplacé par une action personnalisée « Conclure ». Les bulles d'aide sont annoncées.
- **Réduire les animations** : voir §J.
- **Réduire la transparence** : voile de sheet opaque #0A0908.
- **Option « Temps détendu »** (Paramètres, P1) : chrono ×1,5. Mention « temps détendu » discrète sur le rapport, sans pénalité de score.

## N. États et cas particuliers

| Cas | Comportement |
|---|---|
| Aucune pièce (Carnet) | Feuille « Le dossier est vide pour l'instant. » + « Dans le téléphone, maintenez un message, une photo ou un appel pour le verser ici. » + [RETOUR AU TÉLÉPHONE] |
| Aucun lien (pièces sans ACCUSE/DISCULPE) | Chaque fiche affiche « CETTE PIÈCE… » en attente ; CONCLURE en contour |
| Conclure avec 0 pièce | Autorisé. Feuille de confirmation « Aucune pièce au dossier. Conclure quand même ? » [CONCLURE] / Retour |
| Dossier terminé (réouvert depuis Archives) | Rapport en lecture seule + [REJOUER] (nouvelle partie, score non remplacé si inférieur) |
| Retour arrière pendant une enquête | Feuille de pause (§E). Pause automatique si l'app passe en arrière-plan |
| Fin du chrono dans une feuille ou une app | Fermeture de toutes les feuilles, fondu, puis écran 09 « TEMPS ÉCOULÉ » |
| Pas de connexion | Sans effet : le jeu est entièrement local. Seuls les achats de tickets affichent un post-it « Connexion indisponible » |
| Chargement | Jamais de spinner. Feuilles et chemises vides, contenu en fondu (200 ms). Au-delà de 2 s, texte tapé « RÉCUPÉRATION DES PIÈCES… » |
| Erreur de lecture d'un contenu | Post-it « PIÈCE ILLISIBLE » + « Ce fichier n'a pas pu être chargé. Votre progression est enregistrée. » + RÉESSAYER. L'élément reste listé |
| App du téléphone vide | Écran natif vide et crédible (« Aucune note », « Aucun appel récent »), sans aide du jeu |
| Contenu manquant dans les données | L'élément est masqué ; une trace est journalisée en debug. Ne jamais afficher de clé brute |
| Portrait indisponible | Initiales en Newsreader 500, #E4E7EA, sur #6F7A86, même cadre et même ratio. Fondu de 300 ms à l'arrivée du vrai portrait |
| Sauvegarde existante | Écran 02b si une enquête est en cours, sinon Bureau |
| Sauvegarde corrompue | Post-it « Votre dossier n'a pas pu être relu. » + [RECOMMENCER] / « Contacter le support » |
| Chrono en pause au retour | Étiquette chrono en contour + « EN PAUSE », reprise au premier tap |

## O. Priorités d'implémentation

**P0 (indispensable)**
- Nouveau parcours de premier lancement : écrans 01 → 02 → 03 → 04 → téléphone.
- Vocabulaire unifié EXPLORER / VERSER AU DOSSIER / CONCLURE (remplacer « Épingler », « Accuser »).
- Appui long + feuille VERSER AU DOSSIER dans toutes les apps.
- Barre du dossier + retour après versement.
- 3 bulles de tutoriel en #001.
- Écran de conclusion avec bouton nommé + maintien.
- Rapport (explication d'abord).
- Écran 12 + couche carrière décalée après #001.
- Logo : AppIcon, LaunchScreen, 01, 02.
- États vides et post-it d'erreur.

**P1 (important)**
- 02b Reprise.
- Bureau avec un seul dossier principal.
- Carnet réduit à 3 onglets, avec ACCUSE/DISCULPE sur la fiche de pièce.
- Indice en 3 niveaux (sheet).
- Réduire les animations.
- Dynamic Type AX.
- VoiceOver des pièces.
- Option « Temps détendu ».
- Relance douce après 90 s.

**P2 (amélioration)**
- Cinématique de recrutement courte (lien sur 12).
- Transition de dossier complète pour 002 à 005.
- Annotations manuscrites automatiques dans le Carnet.
- Carte de partage d'un rapport.

**P3 (optionnel)**
- « Revoir le tutoriel ».
- Paramètres › À propos avec tuile.
- Variantes sonores du papier.

## P. Critères d'acceptation

1. Premier lancement sur un simulateur réinitialisé : le téléphone de #001 est affiché après **4 taps au maximum**, sans lecture obligatoire au-delà du briefing.
2. L'écran 02 contient exactement : le bandeau logo, l'accroche, la phrase de mission, les 3 verbes, un bouton plein [COMMENCER L'ENQUÊTE] et ⚙. Rien d'autre.
3. Aucun écran du premier lancement avant l'écran 12 n'affiche de matricule, de rang, « BEN-0… » ni la hiérarchie.
4. Les chaînes « Épingler », « Accuser » (hors libellé « L'ACCUSE ») et « Recrue » n'existent plus dans les fichiers de localisation.
5. Chaque écran listé en F a **un seul** bouton plein visible.
6. L'appui long de 0,4 s ouvre la feuille VERSER AU DOSSIER dans Messages, Appels, Photos, Plans, Calendrier, Notes, Contacts, Mail, Navigateur, Fichiers et Corbeille.
7. Après versement : la pièce porte « PIÈCE 0N » dans l'app d'origine, le compteur de la barre s'incrémente, et la pièce apparaît en tête du Carnet › PIÈCES au rang N.
8. Les bulles 1, 2 et 3 n'apparaissent qu'en #001, une seule fois chacune, jamais en même temps, et aucune ne bloque le tap sur un autre élément.
9. CONCLURE est accessible à tout moment depuis le Carnet. Avec 0 pièce, la feuille de confirmation s'affiche.
10. Le bouton de conclusion affiche le prénom choisi, et un relâchement avant 1,2 s n'envoie rien.
11. À 00:00 dans n'importe quel écran du téléphone, l'écran 09 « TEMPS ÉCOULÉ » s'affiche en moins de 500 ms, sans retour possible.
12. Le rapport affiche l'explication avant la note. Les pièces clés manquées apparaissent grisées avec le symbole ○.
13. NON RÉSOLU propose [REPRENDRE L'ENQUÊTE] en bouton principal.
14. L'écran 12 s'affiche exactement une fois : après la première réussite de #001, ou après 2 échecs, ou après « Classer quand même ».
15. Le logo n'apparaît ni dans le téléphone de l'affaire, ni dans le Bureau, ni dans le Carnet.
16. Avec Réduire les animations activé, aucun élément ne se déplace de plus de 0 pt pendant une transition (uniquement de l'opacité).
17. Avec Dynamic Type AX3, aucun texte n'est tronqué sur 02, 03, 04, 09 et 11 (iPhone SE 3e génération).
18. Avec VoiceOver, il est possible de terminer #001 : verser une pièce, relier, conclure.
19. Mode avion : le parcours complet fonctionne.
20. Portraits supprimés du bundle : tous les écrans s'affichent avec les initiales, sans décalage de mise en page.

---

## Points non résolus sans information externe
- **Titre de #001** : ce document suit `case_001.json` (« Le dernier message »). Si le titre « Les disparus de Saint-Clair » est voulu, c'est une modification de données, hors du périmètre design.
- **Contenu de #001** : `case.objective`, `case.solution.summary` et la liste des pièces clés doivent exister dans les données. Si un champ manque, il faut l'ajouter au JSON. Les textes des maquettes sont indicatifs.
- **Économie de tickets** : le solde de départ et l'achat sont conservés tels qu'implémentés. Aucune valeur n'est fixée ici.
